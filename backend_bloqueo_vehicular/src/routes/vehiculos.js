const express = require('express');

const { pool } = require('../db');
const { autenticar } = require('../middleware/auth');

const router = express.Router();

const SELECT_VEHICULOS = `
  SELECT v.*, u.nombre AS conductor_nombre
  FROM vehiculos v
  LEFT JOIN usuarios u ON u.id = v.conductor_id
`;

router.get('/vehiculos', autenticar, async (req, res, next) => {
  try {
    const [filas] = await pool.query(
      `${SELECT_VEHICULOS} ORDER BY v.id ASC`
    );
    res.json({ vehiculos: filas });
  } catch (error) {
    next(error);
  }
});

router.get('/vehiculos/:id', autenticar, async (req, res, next) => {
  try {
    const [filas] = await pool.query(
      `${SELECT_VEHICULOS} WHERE v.id = ?`,
      [Number(req.params.id)]
    );
    if (!filas.length) {
      return res.status(404).json({ mensaje: 'Vehículo no encontrado' });
    }
    res.json({ vehiculo: filas[0] });
  } catch (error) {
    next(error);
  }
});

module.exports = router;