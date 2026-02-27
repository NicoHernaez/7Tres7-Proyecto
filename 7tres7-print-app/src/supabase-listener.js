const { createClient } = require('@supabase/supabase-js');
const config = require('./config');

let supabase = null;
let channel = null;
let callbacks = {};
let reconnectTimer = null;

// Mapa printer_id (UUID) -> printer name (Windows)
// Se carga desde Supabase al iniciar
let myPrinterIds = new Set();
let printerIdToName = {};

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
        log('Conectado - Escuchando pedidos');
        notifyStatus('connected');
        clearReconnectTimer();
      } else if (status === 'CLOSED' || status === 'CHANNEL_ERROR') {
        log(`Desconectado (${status}). Reintentando...`);
        notifyStatus('disconnected');
        scheduleReconnect();
      } else {
        log(`Estado canal: ${status}`);
      }
    });

  // Verificar si hay jobs pendientes al iniciar
  checkPendingJobs();
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
  if (job.status === 'printed' || job.status === 'completed') {
    return;
  }

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
    const tenMinAgo = new Date(Date.now() - 10 * 60 * 1000).toISOString();
    const myIds = Array.from(myPrinterIds);

    const { data: pendingJobs, error } = await supabase
      .from('print_jobs')
      .select('*')
      .gte('created_at', tenMinAgo)
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
      log(`${pendingJobs.length} job(s) pendiente(s) encontrado(s)`);
      for (const job of pendingJobs) {
        await handleNewJob(job);
      }
    }
  } catch (err) {
    log(`Error en checkPendingJobs: ${err.message}`);
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
