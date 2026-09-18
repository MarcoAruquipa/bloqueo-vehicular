const express = require('express');

const { pool } = require('../db');
const { autenticar } = require('../middleware/auth');

const router = express.Router();

const SELECT_UBICACION = `
  SELECT ub.id, ub.vehiculo_id, ub.conductor_id, ub.latitud, ub.longitud,
         ub.precision, ub.fecha, ub.hora, ub.created_at,
         ve.placa,
         u.nombre AS conductor_nombre
  FROM ubicaciones ub
  LEFT JOIN vehiculos ve ON ve.id = ub.vehiculo_id
  LEFT JOIN usuarios u ON u.id = ub.conductor_id
`;

async function vehiculoDeConductor(conductorId) {
  if (!conductorId) return null;
  const [filas] = await pool.query(
    'SELECT vehiculo_id FROM usuarios WHERE id = ?',
    [conductorId]
  );
  return filas[0]?.vehiculo_id || null;
}

// ---------------------------------------------------------------
// Última ubicación del vehículo (404 si no hay ninguna registrada)
// ---------------------------------------------------------------
router.get('/ubicacion/:vehiculoId', autenticar, async (req, res, next) => {
  try {
    const [filas] = await pool.query(
      `${SELECT_UBICACION}
       WHERE ub.vehiculo_id = ?
       ORDER BY ub.id DESC
       LIMIT 1`,
      [Number(req.params.vehiculoId)]
    );
    if (!filas.length) {
      return res.status(404).json({
        mensaje: 'Sin ubicaciones registradas',
        error: 'No se encontró el recurso solicitado',
      });
    }
    res.json({ ubicacion: filas[0] });
  } catch (error) {
    next(error);
  }
});

// ---------------------------------------------------------------
// Historial de ubicaciones del vehículo (orden cronológico)
// ---------------------------------------------------------------
router.get('/ubicaciones/:vehiculoId', autenticar, async (req, res, next) => {
  try {
    const [filas] = await pool.query(
      `${SELECT_UBICACION}
       WHERE ub.vehiculo_id = ?
       ORDER BY ub.id ASC`,
      [Number(req.params.vehiculoId)]
    );
    res.json({ ubicaciones: filas });
  } catch (error) {
    next(error);
  }
});

// ---------------------------------------------------------------
// El teléfono del conductor envía su ubicación real
// ---------------------------------------------------------------
router.post('/api/ubicaciones', autenticar, async (req, res, next) => {
  try {
    const {
      vehiculo_id,
      conductor_id,
      latitud,
      longitud,
      precision,
      fecha,
      hora,
    } = req.body || {};

    const vid = Number(vehiculo_id);
    const lat = Number(latitud);
    const lon = Number(longitud);

    if (!vid || !Number.isFinite(lat) || !Number.isFinite(lon)) {
      return res.status(400).json({ mensaje: 'Datos de ubicación incompletos' });
    }

    const fechaFinal = fecha || new Date().toISOString().slice(0, 10);
    const horaFinal = hora || new Date().toTimeString().slice(0, 8);

    await pool.query(
      `INSERT INTO ubicaciones
         (vehiculo_id, conductor_id, latitud, longitud, \`precision\`, fecha, hora)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        vid,
        Number(conductor_id) || null,
        lat,
        lon,
        Number(precision) || null,
        fechaFinal,
        horaFinal,
      ]
    );

    res.status(201).json({ mensaje: 'Ubicación registrada' });
  } catch (error) {
    next(error);
  }
});

// ---------------------------------------------------------------
// El conductor comienza a compartir su ubicación
// ---------------------------------------------------------------
router.post('/api/ubicacion/iniciar', autenticar, async (req, res, next) => {
  try {
    const { conductor_id, vehiculo_id } = req.body || {};
    const vid =
      Number(vehiculo_id) || (await vehiculoDeConductor(Number(conductor_id)));

    if (!vid) {
      return res.status(400).json({ mensaje: 'No se pudo identificar el vehículo' });
    }

    await pool.query('UPDATE vehiculos SET compartiendo_ubicacion = 1 WHERE id = ?', [
      vid,
    ]);
    res.json({ mensaje: 'Compartición iniciada' });
  } catch (error) {
    next(error);
  }
});

// ---------------------------------------------------------------
// El conductor deja de compartir su ubicación
// ---------------------------------------------------------------
router.post('/api/ubicacion/detener', autenticar, async (req, res, next) => {
  try {
    const { conductor_id } = req.body || {};
    const vid = await vehiculoDeConductor(Number(conductor_id));

    if (vid) {
      await pool.query('UPDATE vehiculos SET compartiendo_ubicacion = 0 WHERE id = ?', [
        vid,
      ]);
    }

    res.json({ mensaje: 'Compartición detenida' });
  } catch (error) {
    next(error);
  }
});

module.exports = router;