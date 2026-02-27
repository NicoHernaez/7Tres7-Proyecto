const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('api', {
  // Obtener configuracion de la PC
  getConfig: () => ipcRenderer.invoke('get-config'),

  // Prueba de impresion
  testPrint: () => ipcRenderer.invoke('test-print'),

  // Escuchar eventos del main process
  onStatusUpdate: (callback) => {
    ipcRenderer.on('status-update', (_event, status) => callback(status));
  },

  onLog: (callback) => {
    ipcRenderer.on('log', (_event, msg) => callback(msg));
  },

  onPrintJob: (callback) => {
    ipcRenderer.on('print-job', (_event, data) => callback(data));
  },
});
