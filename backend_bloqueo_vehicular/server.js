require('dotenv').config();

const app = require('./src/app');
const { bootstrap, pool } = require('./src/db');

const PUERTO = Number(process.env.PORT || 8080);

bootstrap()
  .then(() => {
    app.listen(PUERTO, () => {
      console.log(`Backend Bloqueo Vehicular escuchando en el puerto ${PUERTO}`);
    });
  })
  .catch((error) => {
    console.error('No se pudo iniciar el backend:', error.message);
    process.exit(1);
  });

process.on('SIGTERM', async () => {
  await pool.end();
  process.exit(0);
});