const express = require('express');

const { pool } = require('../db');
const { autenticar, autenticarDispositivo } = require('../middleware/auth');

const router = express.Router();

// ---------------------------------------------------------------
// La app consulta el estado del ESP32 asociado a un vehículo
// ---------------------------------------------------------------
router.get('/estado-esp32', autenticar, async (req, res, next) => {
  try {
    const vehiculoId = Number(req.query.vehiculo_id);
    if (!vehiculoId) {
      return res.status(400).json({ mensaje: 'Falta vehiculo_id' });
    }

    const [filas] = await pool.query(
      `SELECT d.*,
              DATE_FORMAT(d.ultima_conexion, '%Y-%m-%d %H:%i:%s') AS ultima_conexion
       FROM dispositivos_esp32 d
       WHERE d.vehiculo_id = ?
       ORDER BY d.id DESC
       LIMIT 1`,
      [vehiculoId]
    );

    if (!filas.length) {
      return res.status(404).json({
        mensaje: 'No se encontró el dispositivo',
        error: 'No se encontró el recurso solicitado',
      });
    }

    res.json({ dispositivo: filas[0] });
  } catch (error) {
    next(error);
  }
});

// ---------------------------------------------------------------
// El ESP32 reporta su estado (wifi, sensor) y el resultado de una
// prueba de alcohol. Puede autenticarse con JWT o con API_ESP32_KEY.
// ---------------------------------------------------------------
router.post('/api/esp32/estado', autenticarDispositivo, async (req, res, next) => {
  try {
    const {
      identificador,
      vehiculo_id,
      estado,
      wifi,
      sensor,
      nivel_alcohol,
      resultado,
    } = req.body || {};

    if (!identificador) {
      return res.status(400).json({ mensaje: 'Falta identificador' });
    }

    let [dispositivos] = await pool.query(
      'SELECT * FROM dispositivos_esp32 WHERE identificador = ?',
      [identificador]
    );
    if (!dispositivos.length) {
      const vid = Number(vehiculo_id);
      if (!vid) {
        return res
          .status(400)
          .json({ mensaje: 'Dispositivo no registrado. Envíe vehiculo_id' });
      }
      const [insertados] = await pool.query(
        `INSERT INTO dispositivos_esp32 (vehiculo_id, identificador, estado, wifi, sensor)
         VALUES (?, ?, ?, ?, ?)`,
        [vid, identificador, estado || 'conectado', wifi || 'desconocido', sensor || 'desconocido']
      );
      [dispositivos] = await pool.query(
        'SELECT * FROM dispositivos_esp32 WHERE id = ?',
        [insertados.insertId]
      );
    }

    const dispositivo = dispositivos[0];
    await pool.query(
      `UPDATE dispositivos_esp32
       SET estado = ?, wifi = ?, sensor = ?, ultima_conexion = NOW()
       WHERE id = ?`,
      [
        estado || 'conectado',
        wifi || dispositivo.wifi || 'desconocido',
        sensor || dispositivo.sensor || 'desconocido',
        dispositivo.id,
      ]
    );

    let resultadoPrueba = null;

    if (nivel_alcohol !== undefined && nivel_alcohol !== null) {
      const nivel = Number(nivel_alcohol);
      const resultadoFinal = resultado || (nivel >= 100 ? 'bloqueado' : 'normal');
      await pool.query(
        `INSERT INTO pruebas (vehiculo_id, conductor_id, nivel_alcohol, resultado, fecha, hora)
         VALUES (?, ?, ?, ?, CURDATE(), CURTIME())`,
        [dispositivo.vehiculo_id, req.usuarioId || null, nivel, resultadoFinal]
      );
      resultadoPrueba = resultadoFinal;
    } else if (resultado) {
      await pool.query(
        `INSERT INTO pruebas (vehiculo_id, conductor_id, nivel_alcohol, resultado, fecha, hora)
         VALUES (?, ?, NULL, ?, CURDATE(), CURTIME())`,
        [dispositivo.vehiculo_id, req.usuarioId || null, resultado]
      );
      resultadoPrueba = resultado;
    }

    if (resultadoPrueba === 'bloqueado') {
      await pool.query('UPDATE vehiculos SET estado = ? WHERE id = ?', [
        'bloqueado',
        dispositivo.vehiculo_id,
      ]);

      const [vehiculos] = await pool.query(
        'SELECT placa FROM vehiculos WHERE id = ?',
        [dispositivo.vehiculo_id]
      );
      const placa = vehiculos[0]?.placa || '';
      await pool.query(
        `INSERT INTO alertas (vehiculo_id, tipo, mensaje, fecha, hora, estado)
         VALUES (?, ?, ?, CURDATE(), CURTIME(), ?)`,
        [
          dispositivo.vehiculo_id,
          'alcohol_detectado',
          `¡Alerta! Alcohol detectado en el vehículo ${placa}`,
          'pendiente',
        ]
      );
    } else if (resultadoPrueba === 'normal') {
      await pool.query('UPDATE vehiculos SET estado = ? WHERE id = ?', [
        'operativo',
        dispositivo.vehiculo_id,
      ]);
    }

    const [actualizado] = await pool.query(
      `SELECT d.*,
              DATE_FORMAT(d.ultima_conexion, '%Y-%m-%d %H:%i:%s') AS ultima_conexion
       FROM dispositivos_esp32 d
       WHERE d.id = ?`,
      [dispositivo.id]
    );

    res.json({ ok: true, dispositivo: actualizado[0] });
  } catch (error) {
    next(error);
  }
});

// ---------------------------------------------------------------
// Desbloquear el vehículo (por ejemplo, cuando el aire se limpia)
// ---------------------------------------------------------------
router.put('/api/esp32/desbloquear', autenticarDispositivo, async (req, res, next) => {
  try {
    const vehiculoId = Number((req.body || {}).vehiculo_id);
    if (!vehiculoId) {
      return res.status(400).json({ mensaje: 'Falta vehiculo_id' });
    }

    await pool.query('UPDATE vehiculos SET estado = ? WHERE id = ?', [
      'operativo',
      vehiculoId,
    ]);
    await pool.query(
      'UPDATE dispositivos_esp32 SET estado = ? WHERE vehiculo_id = ?',
      ['conectado', vehiculoId]
    );
    await pool.query(
      `UPDATE alertas SET estado = ? WHERE vehiculo_id = ? AND estado = ?`,
      ['leída', vehiculoId, 'pendiente']
    );

    res.json({ mensaje: 'Vehículo desbloqueado' });
  } catch (error) {
    next(error);
  }
});

module.exports = router;