const express = require('express');

const { pool } = require('../db');
const { autenticar } = require('../middleware/auth');

const router = express.Router();

const SELECT_ALERTAS = `
  SELECT a.*,
         DATE_FORMAT(a.fecha, '%Y-%m-%d') AS fecha,
         DATE_FORMAT(a.hora, '%H:%i:%s') AS hora,
         v.placa
  FROM alertas a
  LEFT JOIN vehiculos v ON v.id = a.vehiculo_id
`;

router.get('/alertas', autenticar, async (req, res, next) => {
  try {
    const [filas] = await pool.query(
      `${SELECT_ALERTAS} ORDER BY a.created_at DESC, a.id DESC`
    );
    res.json({ alertas: filas });
  } catch (error) {
    next(error);
  }
});

router.put('/alertas/:id', autenticar, async (req, res, next) => {
  try {
    const { estado } = req.body || {};
    const [resultado] = await pool.query(
      'UPDATE alertas SET estado = ? WHERE id = ?',
      [estado || 'leída', Number(req.params.id)]
    );
    if (!resultado.affectedRows) {
      return res.status(404).json({ mensaje: 'Alerta no encontrada' });
    }
    res.json({ mensaje: 'Alerta actualizada' });
  } catch (error) {
    next(error);
  }
});

module.exports = router;