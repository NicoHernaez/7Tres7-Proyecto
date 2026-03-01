const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const config = require('./src/config');
const { createTray, updateTrayStatus, setTestPrintCallback } = require('./src/tray');
const { startListening, stopListening } = require('./src/supabase-listener');
const { printKitchenTicket, printFullTicket, printTestPage } = require('./src/printer');

let mainWindow;
let tray;

// =============================================
// Single instance lock
// =============================================
const gotTheLock = app.requestSingleInstanceLock();
if (!gotTheLock) {
  app.quit();
  return;
}

app.on('second-instance', () => {
  if (mainWindow) {
    mainWindow.show();
    mainWindow.focus();
  }
});

// =============================================
// Crear ventana principal
// =============================================
function createWindow() {
  mainWindow = new BrowserWindow({
    width: 500,
    height: 500,
    show: false,
    resizable: false,
    icon: path.join(__dirname, 'assets', 'icon.ico'),
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      nodeIntegration: false,
      contextIsolation: true,
    },
  });

  mainWindow.loadFile('renderer/index.html');
  mainWindow.setMenuBarVisibility(false);

  // Ocultar en vez de cerrar
  mainWindow.on('close', (event) => {
    if (!app.isQuitting) {
      event.preventDefault();
      mainWindow.hide();
    }
  });
}

// =============================================
// Procesar print job (1 job = 1 impresora)
// =============================================
async function handlePrintJob(job) {
  const printerName = job._printerName;
  const ticketType = job.ticket_type;
  const data = job.raw_data;

  if (!data) {
    return { success: false, error: 'raw_data vacio' };
  }

  try {
    if (ticketType === 'full_ticket') {
      // Ticket completo para el cliente (solo Barra)
      await printFullTicket(printerName, {
        orderNumber: data.order_number,
        tableOrDelivery: formatDeliveryLabel(data),
        items: data.items || [],
        subtotal: data.subtotal,
        discount: data.discount,
        discountReason: data.discount_reason,
        deliveryFee: data.delivery_fee,
        total: data.total,
        paymentMethod: formatPaymentMethod(data.payment_method),
        customerName: data.customer_name,
        customerPhone: data.customer_phone,
        deliveryNotes: data.delivery_notes || data.customer_notes,
      });
    } else {
      // Comanda de cocina/barra
      await printKitchenTicket(printerName, {
        orderNumber: data.order_number,
        tableOrDelivery: formatDeliveryLabel(data),
        items: (data.items || []).map((item) => ({
          name: item.name || item.label || 'Item',
          quantity: item.quantity || 1,
          cooking: item.cooking || item.cooking_method || item.cookingMethod || null,
          notes: item.notes || item.obs || item.observations || null,
        })),
      });
    }

    // Notificar al renderer
    sendToRenderer('print-job', {
      orderNumber: data.order_number,
      printer: printerName,
      ticketType,
      timestamp: new Date().toISOString(),
      success: true,
    });

    sendToRenderer('log', `Pedido #${data.order_number} impreso en "${printerName}" (${ticketType})`);
    return { success: true };
  } catch (err) {
    sendToRenderer('print-job', {
      orderNumber: data.order_number,
      printer: printerName,
      ticketType,
      timestamp: new Date().toISOString(),
      success: false,
      error: err.message,
    });

    sendToRenderer('log', `ERROR Pedido #${data.order_number} en "${printerName}": ${err.message}`);
    return { success: false, error: err.message };
  }
}

// =============================================
// Helpers de formato
// =============================================
function formatDeliveryLabel(data) {
  const type = data.delivery_type;
  if (type === 'delivery') {
    return data.delivery_address ? `Delivery - ${data.delivery_address}` : 'Delivery';
  }
  if (type === 'pickup') return 'Retira en local';
  if (type === 'local') return 'Mesa';
  return type || '';
}

function formatPaymentMethod(method) {
  const map = { cash: 'Efectivo', mercadopago: 'MercadoPago', transfer: 'Transferencia' };
  return map[method] || method || 'Efectivo';
}

// =============================================
// Prueba de impresion
// =============================================
async function testPrint() {
  sendToRenderer('log', 'Iniciando prueba de impresion...');
  const results = [];

  for (const printer of config.PRINTERS) {
    try {
      await printTestPage(printer);
      sendToRenderer('log', `Prueba OK en "${printer}"`);
      results.push({ printer, success: true });
    } catch (err) {
      sendToRenderer('log', `Prueba FALLO en "${printer}": ${err.message}`);
      results.push({ printer, success: false, error: err.message });
    }
  }

  return results;
}

// =============================================
// Helper: enviar mensaje al renderer
// =============================================
function sendToRenderer(channel, data) {
  if (mainWindow && !mainWindow.isDestroyed()) {
    mainWindow.webContents.send(channel, data);
  }
}

// =============================================
// IPC Handlers
// =============================================
ipcMain.handle('get-config', () => ({
  pcName: config.PC_NAME,
  printers: config.PRINTERS,
  supabaseUrl: config.SUPABASE_URL,
}));

ipcMain.handle('test-print', async () => {
  return testPrint();
});

// =============================================
// App lifecycle
// =============================================
app.whenReady().then(() => {
  createWindow();
  tray = createTray(mainWindow);

  setTestPrintCallback(testPrint);

  // Iniciar listener de Supabase
  startListening({
    onJob: handlePrintJob,
    onStatusChange: (status) => {
      updateTrayStatus(tray, status, mainWindow);
      sendToRenderer('status-update', status);
    },
    onLog: (msg) => {
      sendToRenderer('log', msg);
    },
  });
});

// Auto-arranque con Windows
app.setLoginItemSettings({
  openAtLogin: true,
  path: app.getPath('exe'),
});

app.on('before-quit', () => {
  app.isQuitting = true;
  stopListening();
});

app.on('window-all-closed', () => {
  // No cerrar la app cuando se cierra la ventana (queda en tray)
});
