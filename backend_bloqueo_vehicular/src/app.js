const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const vehiculoRoutes = require('./routes/vehiculos');
const pruebaRoutes = require('./routes/pruebas');
const alertaRoutes = require('./routes/alertas');
const esp32Routes = require('./routes/esp32');
const ubicacionRoutes = require('./routes/ubicaciones');

const app = express();

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ estado: 'ok', servicio: 'backend-bloqueo-vehicular' });
});

app.use('/', authRoutes);
app.use('/', vehiculoRoutes);
app.use('/', pruebaRoutes);
app.use('/', alertaRoutes);
app.use('/', esp32Routes);
app.use('/', ubicacionRoutes);

app.use((req, res) => {
  res.status(404).json({ mensaje: 'No se encontró la ruta solicitada' });
});

// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ mensaje: 'Error interno del servidor' });
});

module.exports = app;