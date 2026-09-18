const express = require('express');

const { pool } = require('../db');
const { autenticar } = require('../middleware/auth');

const router = express.Router();

const SELECT_PRUEBAS = `
  SELECT p.*,
         DATE_FORMAT(p.fecha, '%Y-%m-%d') AS fecha,
         DATE_FORMAT(p.hora, '%H:%i:%s') AS hora,
         v.placa,
         u.nombre AS conductor_nombre
  FROM pruebas p
  LEFT JOIN vehiculos v ON v.id = p.vehiculo_id
  LEFT JOIN usuarios u ON u.id = p.conductor_id
`;

router.get('/pruebas', autenticar, async (req, res, next) => {
  try {
    let sql = SELECT_PRUEBAS;
    const parametros = [];

    if (req.query.vehiculo_id) {
      sql += ' WHERE p.vehiculo_id = ?';
      parametros.push(Number(req.query.vehiculo_id));
    }

    sql += ' ORDER BY p.fecha DESC, p.hora DESC, p.id DESC';
    const [filas] = await pool.query(sql, parametros);
    res.json({ pruebas: filas });
  } catch (error) {
    next(error);
  }
});

router.get('/pruebas/:id', autenticar, async (req, res, next) => {
  try {
    const [filas] = await pool.query(
      `${SELECT_PRUEBAS} WHERE p.id = ?`,
      [Number(req.params.id)]
    );
    if (!filas.length) {
      return res.status(404).json({ mensaje: 'Prueba no encontrada' });
    }
    res.json({ prueba: filas[0] });
  } catch (error) {
    next(error);
  }
});

module.exports = router;