// =============================================
// Estado
// =============================================
let currentStatus = 'connecting';
let recentPrints = [];
const MAX_RECENT = 20;

// =============================================
// Inicializar
// =============================================
async function init() {
  const config = await window.api.getConfig();

  document.getElementById('pcName').textContent =
    `PC: ${config.pcName} | Impresoras: ${config.printers.join(', ')}`;

  // Renderizar lista de impresoras
  const printerList = document.getElementById('printerList');
  printerList.innerHTML = config.printers.map((p) => `
    <div class="printer-item">
      <span class="printer-name">${p}</span>
      <span class="printer-status" id="printer-${p.replace(/\s/g, '-')}">Lista</span>
    </div>
  `).join('');

  // Escuchar eventos del main process
  window.api.onStatusUpdate((status) => {
    currentStatus = status;
    updateStatusUI(status);
  });

  window.api.onLog((msg) => {
    addLogEntry(msg);
  });

  window.api.onPrintJob((data) => {
    addRecentPrint(data);
  });
}

// =============================================
// Actualizar UI de estado
// =============================================
function updateStatusUI(status) {
  const dot = document.getElementById('statusDot');
  const text = document.getElementById('statusText');

  dot.className = 'status-dot';

  switch (status) {
    case 'connected':
      dot.classList.add('connected');
      text.textContent = 'Conectado - Escuchando pedidos';
      break;
    case 'disconnected':
      text.textContent = 'Desconectado - Reintentando...';
      break;
    case 'connecting':
      dot.classList.add('connecting');
      text.textContent = 'Conectando...';
      break;
    default:
      text.textContent = status;
  }
}

// =============================================
// Agregar impresion reciente
// =============================================
function addRecentPrint(data) {
  recentPrints.unshift(data);
  if (recentPrints.length > MAX_RECENT) recentPrints.pop();
  renderRecentPrints();
}

function renderRecentPrints() {
  const container = document.getElementById('recentList');

  if (recentPrints.length === 0) {
    container.innerHTML = '<div style="color: #444; font-size: 13px; text-align: center; padding: 20px;">Esperando pedidos...</div>';
    return;
  }

  container.innerHTML = recentPrints.map((p) => {
    const time = new Date(p.timestamp).toLocaleTimeString('es-AR', {
      hour: '2-digit',
      minute: '2-digit',
    });

    const typeLabel = p.ticketType === 'full_ticket' ? 'Ticket' : 'Comanda';
    const statusLabel = p.success ? 'OK' : 'FALLO';

    return `
      <div class="recent-item ${p.success === false ? 'error' : ''}">
        <span class="recent-time">${time}</span>
        <span class="recent-text">
          #${p.orderNumber} - ${p.printer} (${typeLabel}) - ${statusLabel}
        </span>
      </div>
    `;
  }).join('');
}

// =============================================
// Prueba de impresion
// =============================================
async function handleTestPrint() {
  const btn = document.getElementById('btnTest');
  btn.disabled = true;
  btn.textContent = 'Imprimiendo...';

  try {
    const results = await window.api.testPrint();
    const allOk = results.every((r) => r.success);
    btn.textContent = allOk ? 'Prueba exitosa!' : 'Hubo errores - ver log';
  } catch (err) {
    btn.textContent = 'Error: ' + err.message;
  }

  setTimeout(() => {
    btn.disabled = false;
    btn.textContent = 'Imprimir Prueba';
  }, 3000);
}

// =============================================
// Log tecnico
// =============================================
function addLogEntry(msg) {
  const logPanel = document.getElementById('logPanel');
  const entry = document.createElement('div');
  entry.className = 'log-entry';
  entry.textContent = msg;
  logPanel.appendChild(entry);

  // Mantener maximo 100 entradas
  while (logPanel.children.length > 100) {
    logPanel.removeChild(logPanel.firstChild);
  }

  logPanel.scrollTop = logPanel.scrollHeight;
}

function toggleLog() {
  document.getElementById('logPanel').classList.toggle('show');
}

// =============================================
// Init
// =============================================
init();
