const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { printRaw, buildKitchenTicket, buildFullTicket, buildTestTicket } = require('./printer');

const app = express();
const PORT = 3001;

// =============================================
// Config de esta PC
// =============================================
const PC_CONFIG = loadConfig();

function loadConfig() {
  const configPaths = [
    path.join(__dirname, 'pc-config.json'),
    path.join(process.cwd(), 'pc-config.json'),
  ];

  for (const configFile of configPaths) {
    try {
      if (fs.existsSync(configFile)) {
        const config = JSON.parse(fs.readFileSync(configFile, 'utf8'));
        console.log(`[Config] Cargado de: ${configFile}`);
        return config;
      }
    } catch (e) {
      console.warn(`[Config] Error leyendo ${configFile}:`, e.message);
    }
  }

  console.log('[Config] No se encontro pc-config.json, usando default BARRA');
  return { pc: 'BARRA', printers: ['Barra'] };
}

// =============================================
// Logging a archivo
// =============================================
const LOG_DIR = path.join(__dirname, 'logs');
if (!fs.existsSync(LOG_DIR)) fs.mkdirSync(LOG_DIR);

function logToFile(msg) {
  const now = new Date();
  const date = now.toISOString().split('T')[0];
  const time = now.toLocaleTimeString('es-AR');
  const line = `[${date} ${time}] ${msg}\n`;
  const logFile = path.join(LOG_DIR, `print-${date}.log`);
  fs.appendFileSync(logFile, line);
}

function log(msg) {
  console.log(msg);
  logToFile(msg);
}

// =============================================
// Historial de impresiones (in-memory, ultimas 100)
// =============================================
const printHistory = [];
const MAX_HISTORY = 100;

function addToHistory(entry) {
  printHistory.unshift({ ...entry, timestamp: new Date().toISOString() });
  if (printHistory.length > MAX_HISTORY) printHistory.pop();
}

// =============================================
// Middleware
// =============================================
app.use(cors());
app.use(express.json({ limit: '1mb' }));

// Log de requests
app.use((req, res, next) => {
  if (req.method !== 'GET' || req.path !== '/health') {
    log(`${req.method} ${req.path} desde ${req.ip}`);
  }
  next();
});

// =============================================
// Health check
// =============================================
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    pc: PC_CONFIG.pc,
    printers: PC_CONFIG.printers,
    uptime: Math.floor(process.uptime()),
    hostname: os.hostname(),
    timestamp: new Date().toISOString(),
  });
});

// =============================================
// Listar impresoras configuradas
// =============================================
app.get('/printers', (req, res) => {
  res.json({
    pc: PC_CONFIG.pc,
    configured: PC_CONFIG.printers,
  });
});

// =============================================
// Historial de impresiones
// =============================================
app.get('/history', (req, res) => {
  res.json(printHistory);
});

// =============================================
// ENDPOINT PRINCIPAL: Imprimir
// =============================================
app.post('/print', async (req, res) => {
  const { order, printer, type } = req.body;

  if (!order) {
    return res.status(400).json({ success: false, error: 'Falta "order" en el body' });
  }
  if (!printer) {
    return res.status(400).json({ success: false, error: 'Falta "printer" en el body' });
  }

  // Validar que la impresora este configurada en esta PC
  if (!PC_CONFIG.printers.includes(printer)) {
    return res.status(400).json({
      success: false,
      error: `Impresora "${printer}" no configurada en PC ${PC_CONFIG.pc}`,
      configured: PC_CONFIG.printers,
    });
  }

  try {
    log(`Imprimiendo pedido #${order.id || order.orderNumber || '?'} en "${printer}" (${type || 'kitchen'})`);

    let ticket;
    if (type === 'full') {
      // Ticket completo (Barra)
      ticket = buildFullTicket({
        orderNumber: order.id || order.orderNumber,
        tableOrDelivery: formatDeliveryLabel(order),
        items: (order.items || []).map(mapItem),
        subtotal: order.subtotal,
        discount: order.discount,
        discountReason: order.discount_reason || order.discountReason,
        deliveryFee: order.delivery_fee || order.deliveryFee,
        total: order.total,
        paymentMethod: formatPaymentMethod(order.payment_method || order.paymentMethod),
        customerName: order.customer_name || order.customerName,
        customerPhone: order.customer_phone || order.customerPhone,
        deliveryNotes: order.delivery_notes || order.customer_notes || order.deliveryNotes,
      });
    } else {
      // Comanda de cocina (minuta, parrilla, barra parcial)
      ticket = buildKitchenTicket({
        orderNumber: order.id || order.orderNumber,
        tableOrDelivery: formatDeliveryLabel(order),
        items: (order.items || []).map(mapItem),
      });
    }

    await printRaw(printer, ticket);

    const entry = {
      success: true,
      printer,
      orderId: order.id || order.orderNumber,
      type: type || 'kitchen',
      items: (order.items || []).length,
    };
    addToHistory(entry);
    log(`[OK] Pedido #${entry.orderId} impreso en "${printer}"`);

    res.json({
      success: true,
      printer,
      orderId: entry.orderId,
      timestamp: new Date().toISOString(),
    });

  } catch (error) {
    const entry = {
      success: false,
      printer,
      orderId: order.id || order.orderNumber,
      type: type || 'kitchen',
      error: error.message,
    };
    addToHistory(entry);
    log(`[ERROR] Pedido #${entry.orderId} en "${printer}": ${error.message}`);

    res.status(500).json({
      success: false,
      error: error.message,
      printer,
      orderId: entry.orderId,
    });
  }
});

// =============================================
// Imprimir prueba
// =============================================
app.post('/test', async (req, res) => {
  const { printer } = req.body;

  if (!printer || !PC_CONFIG.printers.includes(printer)) {
    return res.status(400).json({
      success: false,
      error: `Impresora "${printer}" no valida`,
      configured: PC_CONFIG.printers,
    });
  }

  try {
    log(`Imprimiendo prueba en "${printer}"...`);
    const testTicket = buildTestTicket(printer);
    await printRaw(printer, testTicket);

    addToHistory({ success: true, printer, type: 'test' });
    log(`[OK] Prueba impresa en "${printer}"`);

    res.json({ success: true, printer });
  } catch (error) {
    addToHistory({ success: false, printer, type: 'test', error: error.message });
    log(`[ERROR] Prueba en "${printer}": ${error.message}`);

    res.status(500).json({ success: false, error: error.message });
  }
});

// =============================================
// Helpers de formato (compatibles con main.js del Electron viejo)
// =============================================
function formatDeliveryLabel(order) {
  const type = order.delivery_type || order.deliveryType;
  if (type === 'delivery') {
    const addr = order.delivery_address || order.deliveryAddress;
    return addr ? `Delivery - ${addr}` : 'Delivery';
  }
  if (type === 'pickup') return 'Retira en local';
  if (type === 'local') return 'Mesa';
  return type || '';
}

function formatPaymentMethod(method) {
  const map = { cash: 'Efectivo', mercadopago: 'MercadoPago', transfer: 'Transferencia' };
  return map[method] || method || 'Efectivo';
}

function mapItem(item) {
  return {
    name: item.name || item.label || 'Item',
    quantity: item.quantity || 1,
    price: item.price || 0,
    subtotal: item.subtotal || (item.price || 0) * (item.quantity || 1),
    cooking: item.cooking || item.cooking_method || item.cookingMethod || null,
    notes: item.notes || item.obs || item.observations || null,
  };
}

// =============================================
// Iniciar servidor
// =============================================
app.listen(PORT, '0.0.0.0', () => {
  log('');
  log('===========================================');
  log(`  7TRES7 PRINT SERVER v2.0.0 - ${PC_CONFIG.pc}`);
  log('===========================================');
  log(`  Puerto: ${PORT}`);
  log(`  Impresoras: ${PC_CONFIG.printers.join(', ')}`);
  log(`  URL: http://localhost:${PORT}`);
  log(`  IP: http://${getLocalIP()}:${PORT}`);
  log('===========================================');
  log('  Esperando pedidos...');
  log('');
});

function getLocalIP() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return 'localhost';
}
