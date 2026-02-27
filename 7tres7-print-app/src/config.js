const os = require('os');
const fs = require('fs');
const path = require('path');

// =============================================
// Supabase
// =============================================
const SUPABASE_URL = 'https://yfdustfjfmifvgybwinr.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmZHVzdGZqZm1pZnZneWJ3aW5yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMzU3ODQsImV4cCI6MjA4NTgxMTc4NH0.YcLo7YXePi0_okJxtPuYLaMQI2-P4C8UxNzXnLfQoBY';

// =============================================
// Printer codes por PC (matchean printers.code en Supabase)
// =============================================
const CONFIG_BARRA = {
  PC_NAME: 'BARRA',
  // Nombres Windows de las impresoras (para enviar raw print)
  PRINTERS: ['Barra'],
  // Codes de la tabla printers en Supabase que maneja esta PC
  PRINTER_CODES: ['BARRA'],
};

const CONFIG_COCINA = {
  PC_NAME: 'COCINA',
  PRINTERS: ['minuta', 'parrilla delivery'],
  PRINTER_CODES: ['MINUTA', 'PARRILLA'],
};

// =============================================
// Detectar PC automaticamente
// =============================================
function detectConfig() {
  // 1. Intentar leer archivo local pc-config.json
  const configPaths = [
    path.join(__dirname, '..', 'pc-config.json'),
    path.join(process.resourcesPath || __dirname, 'pc-config.json'),
  ];

  for (const configFile of configPaths) {
    try {
      if (fs.existsSync(configFile)) {
        const localConfig = JSON.parse(fs.readFileSync(configFile, 'utf8'));
        if (localConfig.pc === 'COCINA') return CONFIG_COCINA;
        if (localConfig.pc === 'BARRA') return CONFIG_BARRA;
      }
    } catch (e) {
      // Ignorar errores de lectura
    }
  }

  // 2. Detectar por hostname
  const hostname = os.hostname().toUpperCase();
  if (hostname.includes('COCINA')) return CONFIG_COCINA;
  if (hostname.includes('BARRA') || hostname.includes('CAJA')) return CONFIG_BARRA;

  // 3. Default: BARRA (la PC principal)
  return CONFIG_BARRA;
}

const config = detectConfig();

module.exports = {
  ...config,
  SUPABASE_URL,
  SUPABASE_ANON_KEY,
};
