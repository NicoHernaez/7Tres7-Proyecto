const path = require('path');
const Service = require('node-windows').Service;

const svc = new Service({
  name: '7Tres7 Print Server',
  script: path.join(__dirname, 'server.js'),
});

svc.on('uninstall', () => {
  console.log('Servicio desinstalado correctamente.');
});

svc.on('error', (err) => {
  console.error('Error desinstalando servicio:', err);
});

console.log('Desinstalando servicio...');
svc.uninstall();
