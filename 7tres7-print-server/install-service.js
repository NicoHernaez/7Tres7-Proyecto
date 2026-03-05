const path = require('path');
const Service = require('node-windows').Service;

const svc = new Service({
  name: '7Tres7 Print Server',
  description: 'Servidor de impresion local para 7Tres7 Restaurante',
  script: path.join(__dirname, 'server.js'),
  nodeOptions: [],
  env: [{
    name: 'NODE_ENV',
    value: 'production',
  }],
});

svc.on('install', () => {
  svc.start();
  console.log('');
  console.log('===========================================');
  console.log('  Servicio instalado y corriendo!');
  console.log('  Nombre: "7Tres7 Print Server"');
  console.log('  Se iniciara automaticamente con Windows');
  console.log('===========================================');
  console.log('');
  console.log('Para verificar:');
  console.log('  - Abrir "Servicios" de Windows (services.msc)');
  console.log('  - Buscar "7Tres7 Print Server"');
  console.log('  - Probar: http://localhost:3001/health');
});

svc.on('alreadyinstalled', () => {
  console.log('El servicio ya esta instalado.');
  console.log('Para reinstalar, primero ejecuta: node uninstall-service.js');
});

svc.on('error', (err) => {
  console.error('Error instalando servicio:', err);
});

console.log('Instalando servicio de Windows...');
svc.install();
