require('dotenv').config();

const { bootstrap, pool } = require('../src/db');

bootstrap()
  .then(async () => {
    console.log('Tablas creadas y datos iniciales cargados.');
    await pool.end();
  })
  .catch((error) => {
    console.error('Error al sembrar la base de datos:', error.message);
    process.exit(1);
  });