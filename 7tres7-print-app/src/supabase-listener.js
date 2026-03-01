const { createClient } = require('@supabase/supabase-js');
const config = require('./config');

let supabase = null;
let channel = null;
let callbacks = {};
let reconnectTimer = null;
let pollingTimer = null;
const POLLING_INTERVAL = 30000; // 30 segundos

// Mapa printer_id (UUID) -> printer name (Windows)
// Se carga desde Supabase al iniciar
let myPrinterIds = new Set();
let printerIdToName = {};

// Evitar procesar el mismo job dos veces (Realtime + polling)
let processingJobs = new Set();

// =============================================
// Inicializar cliente Supabase
// =============================================
function initSupabase() {
  supabase = createClient(config.SUPABASE_URL, config.SUPABASE_ANON_KEY, {
    realtime: {
      params: {
        eventsPerSecond: 10,
      },
    },
  });
  return supabase;
}

// =============================================
// Cargar impresoras de esta PC desde Supabase
// =============================================
async function loadMyPrinters() {
  if (!supabase) initSupabase();

  const { data: printers, error } = await supabase
    .from('printers')
    .select('id, name, code, print_categories')
    .eq('is_active', true);

  if (error) {
    log(`Error cargando impresoras: ${error.message}`);
    return false;
  }

  myPrinterIds.clear();
  printerIdToName = {};

  for (const p of printers) {
    if (config.PRINTER_CODES.includes(p.code)) {
      myPrinterIds.add(p.id);
      printerIdToName[p.id] = p.name;
      log(`Impresora registrada: "${p.name}" (${p.code}) -> ${p.id.substring(0, 8)}`);
    }
  }

  if (myPrinterIds.size === 0) {
    log('ADVERTENCIA: No se encontraron impresoras para esta PC');
    return false;
  }

  log(`${myPrinterIds.size} impresora(s) cargadas para PC ${config.PC_NAME}`);
  return true;
}

// =============================================
// Escuchar nuevos print_jobs via Realtime
// =============================================
async function startListening(cbs) {
  callbacks = cbs;

  if (!supabase) initSupabase();

  log('Cargando impresoras desde Supabase...');
  notifyStatus('connecting');

  await loadMyPrinters();

  log('Conectando a Supabase Realtime...');

  channel = supabase
    .channel('print_jobs_channel')
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'print_jobs',
      },
      (payload) => {
        handleNewJob(payload.new);
      }
    )
    .subscribe((status) => {
      if (status === 'SUBSCRIBED') {
        log('Conectado - Escuchando pedidos (Realtime + Polling)');
        notifyStatus('connected');
        clearReconnectTimer();
      } else if (status === 'CLOSED' || status === 'CHANNEL_ERROR' || status === 'TIMED_OUT') {
        log(`Desconectado (${status}). Reintentando en 5s...`);
        notifyStatus('disconnected');
        scheduleReconnect();
      } else {
        log(`Estado canal: ${status}`);
      }
    });

  // Verificar si hay jobs pendientes al iniciar
  checkPendingJobs();

  // Polling de backup: revisa cada 30s por si Realtime falla
  startPolling();
}

// =============================================
// Procesar nuevo job
// =============================================
async function handleNewJob(job) {
  if (!job || !job.raw_data) {
    return; // Job sin datos, ignorar silenciosamente
  }

  // Solo procesar jobs de MIS impresoras
  if (!myPrinterIds.has(job.printer_id)) {
    return; // No es para esta PC
  }

  // Ignorar si ya esta impreso
  if (job.status === 'printed' || job.status === 'completed' || job.status === 'printing') {
    return;
  }

  // Dedup: evitar procesar el mismo job dos veces (Realtime + polling)
  if (processingJobs.has(job.id)) {
    return;
  }
  processingJobs.add(job.id);

  const printerName = printerIdToName[job.printer_id] || 'Desconocida';
  const orderNum = job.raw_data.order_number || '?';
  log(`Job recibido: Pedido #${orderNum} -> ${printerName} (${job.ticket_type})`);

  try {
    // Marcar como printing
    await updateJobStatus(job.id, 'printing');

    // Llamar al handler de impresion (definido en main.js)
    if (callbacks.onJob) {
      const result = await callbacks.onJob({
        ...job,
        _printerName: printerName,
      });

      if (result.success) {
        await updateJobStatus(job.id, 'printed', { printed_at: new Date().toISOString() });
        log(`Pedido #${orderNum} impreso OK en "${printerName}"`);
      } else {
        const attempts = (job.attempts || 0) + 1;
        await updateJobStatus(job.id, 'failed', {
          error_message: result.error,
          attempts,
        });
        log(`Pedido #${orderNum} FALLO en "${printerName}": ${result.error}`);
      }
    }
  } catch (err) {
    log(`Error procesando job: ${err.message}`);
    try {
      await updateJobStatus(job.id, 'failed', {
        error_message: err.message,
        attempts: (job.attempts || 0) + 1,
      });
    } catch (e) { /* ignore */ }
  } finally {
    processingJobs.delete(job.id);
  }
}

// =============================================
// Actualizar estado del job en Supabase
// =============================================
async function updateJobStatus(jobId, status, extra = {}) {
  if (!supabase) return;

  await supabase
    .from('print_jobs')
    .update({ status, ...extra })
    .eq('id', jobId);
}

// =============================================
// Verificar jobs pendientes (al iniciar la app)
// =============================================
async function checkPendingJobs() {
  if (!supabase || myPrinterIds.size === 0) return;

  try {
    // Buscar jobs pendientes de la ultima hora
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString();
    const myIds = Array.from(myPrinterIds);

    const { data: pendingJobs, error } = await supabase
      .from('print_jobs')
      .select('*')
      .gte('created_at', oneHourAgo)
      .in('status', ['pending', 'failed'])
      .in('printer_id', myIds)
      .lt('attempts', 3)
      .order('priority', { ascending: true })
      .order('created_at', { ascending: true });

    if (error) {
      log(`Error consultando jobs pendientes: ${error.message}`);
      return;
    }

    if (pendingJobs && pendingJobs.length > 0) {
      log(`Polling: ${pendingJobs.length} job(s) pendiente(s) encontrado(s)`);
      for (const job of pendingJobs) {
        await handleNewJob(job);
      }
    }
  } catch (err) {
    log(`Error en checkPendingJobs: ${err.message}`);
  }
}

// =============================================
// Polling de backup (cada 30s)
// =============================================
function startPolling() {
  stopPolling();
  log(`Polling activo cada ${POLLING_INTERVAL / 1000}s`);
  pollingTimer = setInterval(() => {
    checkPendingJobs();
  }, POLLING_INTERVAL);
}

function stopPolling() {
  if (pollingTimer) {
    clearInterval(pollingTimer);
    pollingTimer = null;
  }
}

// =============================================
// Reconexion
// =============================================
function scheduleReconnect() {
  clearReconnectTimer();
  reconnectTimer = setTimeout(() => {
    log('Reintentando conexion...');
    stopListening();
    startListening(callbacks);
  }, 5000);
}

function clearReconnectTimer() {
  if (reconnectTimer) {
    clearTimeout(reconnectTimer);
    reconnectTimer = null;
  }
}

// =============================================
// Detener
// =============================================
function stopListening() {
  clearReconnectTimer();
  stopPolling();
  if (channel && supabase) {
    supabase.removeChannel(channel);
    channel = null;
  }
}

// =============================================
// Helpers
// =============================================
function log(msg) {
  const timestamp = new Date().toLocaleTimeString('es-AR');
  const fullMsg = `[${timestamp}] ${msg}`;
  console.log(fullMsg);
  if (callbacks.onLog) callbacks.onLog(fullMsg);
}

function notifyStatus(status) {
  if (callbacks.onStatusChange) callbacks.onStatusChange(status);
}

module.exports = {
  startListening,
  stopListening,
};
