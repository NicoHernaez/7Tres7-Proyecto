const { Tray, Menu, nativeImage } = require('electron');
const path = require('path');

// Icono simple generado en codigo (16x16 printer icon)
// Reemplazar con assets/icon.ico cuando tengas uno personalizado
function createTrayIcon() {
  // Intentar cargar .ico del directorio assets
  const icoPath = path.join(__dirname, '..', 'assets', 'icon.ico');
  const pngPath = path.join(__dirname, '..', 'assets', 'icon.png');

  try {
    const fs = require('fs');
    if (fs.existsSync(icoPath)) {
      return nativeImage.createFromPath(icoPath);
    }
    if (fs.existsSync(pngPath)) {
      return nativeImage.createFromPath(pngPath);
    }
  } catch (e) {
    // Fallback a icono generado
  }

  // Icono generado: cuadrado 16x16 con "7" en el centro
  return nativeImage.createFromDataURL(
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAA' +
    'cElEQVQ4T2NkoBAwUqifYdAb8P9/A8P/fxgZGP4zMjL8Z2Rk+M/AwMDAwMjIwMDAwPCf' +
    'AUwzMDAwMDL8Z/jPwMDAyMDAyMjIwPCfkZGBkZERKoZsACMjIwMDIyMDIyMjkGZkZGBg' +
    'ZGBkYBywaBh0eQEA0NYaEaLiJtcAAAAASUVORK5CYII='
  );
}

let testPrintCallback = null;

function createTray(mainWindow) {
  const icon = createTrayIcon();
  const tray = new Tray(icon);

  tray.setToolTip('7Tres7 Print - Iniciando...');

  const contextMenu = buildMenu('connecting', mainWindow);
  tray.setContextMenu(contextMenu);

  tray.on('double-click', () => {
    if (mainWindow) {
      mainWindow.show();
      mainWindow.focus();
    }
  });

  return tray;
}

function buildMenu(status, mainWindow) {
  let statusLabel;
  switch (status) {
    case 'connected':
      statusLabel = 'Conectado';
      break;
    case 'disconnected':
      statusLabel = 'Desconectado';
      break;
    case 'connecting':
      statusLabel = 'Conectando...';
      break;
    default:
      statusLabel = status;
  }

  return Menu.buildFromTemplate([
    {
      label: statusLabel,
      enabled: false,
    },
    { type: 'separator' },
    {
      label: 'Mostrar ventana',
      click: () => {
        if (mainWindow) {
          mainWindow.show();
          mainWindow.focus();
        }
      },
    },
    {
      label: 'Imprimir prueba',
      click: () => {
        if (testPrintCallback) testPrintCallback();
      },
    },
    { type: 'separator' },
    {
      label: 'Salir',
      click: () => {
        const { app } = require('electron');
        app.isQuitting = true;
        app.quit();
      },
    },
  ]);
}

function updateTrayStatus(tray, status, mainWindow) {
  if (!tray || tray.isDestroyed()) return;

  const statusText = status === 'connected' ? 'Conectado' :
    status === 'disconnected' ? 'Desconectado' : 'Conectando...';

  tray.setToolTip(`7Tres7 Print - ${statusText}`);
  tray.setContextMenu(buildMenu(status, mainWindow));
}

function setTestPrintCallback(cb) {
  testPrintCallback = cb;
}

module.exports = {
  createTray,
  updateTrayStatus,
  setTestPrintCallback,
};
