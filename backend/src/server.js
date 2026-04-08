'use strict';
const app    = require('./app');
const config = require('./config');

const server = app.listen(config.port, () => {
  console.log(`🚀 Finans Asistanı Backend — port ${config.port} (${config.env})`);
  console.log(`📡 Health: http://localhost:${config.port}/health`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM alındı — sunucu kapatılıyor...');
  server.close(() => process.exit(0));
});

process.on('unhandledRejection', (reason) => {
  console.error('[Unhandled Rejection]', reason);
});
