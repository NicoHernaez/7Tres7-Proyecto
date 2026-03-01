const os = require('os');
const fs = require('fs');
const path = require('path');

// =============================================
// Supabase
// =============================================
const SUPABASE_URL = 'https://yfdustfjfmifvgybwinr.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmZHVzdGZqZm1pZnZneWJ3aW5yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMzU3ODQsImV4cCI6MjA4NTgxMTc4NH0.YcLo7YXePi0_okJxtPuYLaMQI2-P4C8UxNzXnLfQoBY';

// =============================================
// Configs por PC — nombres CASE-SENSITIVE
// =============================================
const CONFIG_BARRA = {
  PC_NAME: 'BARRA',
  PRINTERS: ['Barra'],
  PRINTER_CODES: ['BARRA'],
};

const CONFIG_BARRA2 = {
  PC_NAME: 'BARRA2',
  PRINTERS: ['Barra'],
  PRINTER_CODES: ['BARRA2'],
};

const CONFIG_COCINA = {
  PC_NAME: 'COCINA',
  PRINTERS: ['minuta', 'parrilla delivery'],
  PRINTER_CODES: ['MINUTA', 'PARRILLA'],
};

// =============================================
// Mapeo de categorias a nombres de impresora
// Nombres EXACTOS como aparecen en Windows
// =============================================
const CATEGORY_PRINTER_MAP = {
  // PC COCINA - Impresora "minuta" (minuscula)
  'empanadas': 'minuta',
  'minutas': 'minuta',
  'pizzas': 'minuta',
  'postres': 'minuta',

  // PC COCINA - Impresora "parrilla delivery" (minuscula)
  'restaurant': 'parrilla delivery',
  'pastas': 'parrilla delivery',
  'carnes': 'parrilla delivery',
  'parrilla': 'parrilla delivery',

  // PC BARRA - Impresora "Barra" (con mayuscula)
  'bebidas': 'Barra',
  'gaseosas': 'Barra',
  'cervezas': 'Barra',
  'vinos': 'Barra',
};

// =============================================
// Detectar PC automaticamente
// Busca pc-config.json en multiples ubicaciones
// para funcionar tanto en dev como en .exe portable
// =============================================
function detectConfig() {
  const configPaths = [
    // 1. Junto al .exe (portable)
    process.env.PORTABLE_EXECUTABLE_DIR
      ? path.join(process.env.PORTABLE_EXECUTABLE_DIR, 'pc-config.json')
      : null,
    // 2. En la carpeta del exe
    process.execPath
      ? path.join(path.dirname(process.execPath), 'pc-config.json')
      : null,
    // 3. Carpeta resources (empaquetado)
    process.resourcesPath
      ? path.join(process.resourcesPath, 'pc-config.json')
      : null,
    // 4. Relativo al src/ (dev)
    path.join(__dirname, '..', 'pc-config.json'),
    // 5. CWD
    path.join(process.cwd(), 'pc-config.json'),
  ].filter(Boolean);

  for (const configFile of configPaths) {
    try {
      if (fs.existsSync(configFile)) {
        const localConfig = JSON.parse(fs.readFileSync(configFile, 'utf8'));
        console.log(`[Config] Leido de: ${configFile}`, localConfig);

        if (localConfig.pc === 'COCINA') {
          if (localConfig.printers) CONFIG_COCINA.PRINTERS = localConfig.printers;
          return CONFIG_COCINA;
        }
        if (localConfig.pc === 'BARRA2') {
          if (localConfig.printers) CONFIG_BARRA2.PRINTERS = localConfig.printers;
          return CONFIG_BARRA2;
        }
        if (localConfig.pc === 'BARRA') {
          if (localConfig.printers) CONFIG_BARRA.PRINTERS = localConfig.printers;
          return CONFIG_BARRA;
        }
      }
    } catch (e) {
      console.warn(`[Config] Error leyendo ${configFile}:`, e.message);
    }
  }

  // Fallback: detectar por hostname
  const hostname = os.hostname().toUpperCase();
  console.log(`[Config] No se encontro pc-config.json, detectando por hostname: ${hostname}`);
  if (hostname.includes('COCINA')) return CONFIG_COCINA;
  if (hostname.includes('BARRA') || hostname.includes('CAJA')) return CONFIG_BARRA;

  // Default: BARRA
  console.log('[Config] Default: BARRA');
  return CONFIG_BARRA;
}

const config = detectConfig();

module.exports = {
  ...config,
  SUPABASE_URL,
  SUPABASE_ANON_KEY,
  CATEGORY_PRINTER_MAP,
};
