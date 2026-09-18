const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const { pool } = require('../db');
const { autenticar } = require('../middleware/auth');

const router = express.Router();

const SECRETO = () => process.env.JWT_SECRET || 'cambio-este-secreto';
const EXPIRACION = '7d';
const EXPRESION_CORREO = /^[\w._%+-]+@[\w.-]+\.[A-Za-z]{2,}$/;
const ROLES_VALIDOS = ['responsable', 'conductor'];

function firmarToken(usuario) {
  return jwt.sign(
    { sub: usuario.id, rol: usuario.rol },
    SECRETO(),
    { expiresIn: EXPIRACION }
  );
}

function usuarioPublico(fila) {
  return {
    id: fila.id,
    nombre: fila.nombre,
    correo: fila.correo,
    rol: fila.rol,
    vehiculo_id: fila.vehiculo_id ?? null,
    vehiculo_placa: fila.vehiculo_placa ?? null,
  };
}

const SELECT_USUARIO = `
  SELECT u.*, v.placa AS vehiculo_placa, v.id AS vehiculo_id
  FROM usuarios u
  LEFT JOIN vehiculos v ON v.id = u.vehiculo_id
`;

// ---------------------------------------------------------------
// Login
// ---------------------------------------------------------------
router.post('/login', async (req, res, next) => {
  try {
    const { correo, password } = req.body || {};
    if (!correo || !password) {
      return res.status(400).json({ mensaje: 'Ingresa tu correo y contraseña' });
    }

    const [filas] = await pool.query(
      `${SELECT_USUARIO} WHERE u.correo = ?`,
      [String(correo).trim()]
    );
    const usuario = filas[0];

    if (!usuario || !(await bcrypt.compare(String(password), usuario.password_hash))) {
      return res.status(401).json({
        mensaje: 'Credenciales incorrectas',
        error: 'Credenciales incorrectas o sesión expirada',
      });
    }

    res.json({
      token: firmarToken(usuario),
      usuario: usuarioPublico(usuario),
    });
  } catch (error) {
    next(error);
  }
});

// ---------------------------------------------------------------
// Registro de un nuevo miembro de la familia
// ---------------------------------------------------------------
router.post('/register', async (req, res, next) => {
  try {
    const { nombre, correo, password, rol } = req.body || {};

    const nombreLimpio = String(nombre || '').trim();
    const correoLimpio = String(correo || '').trim().toLowerCase();
    const rolLimpio = String(rol || 'conductor').trim().toLowerCase();

    if (!nombreLimpio) {
      return res.status(400).json({ mensaje: 'Ingresa tu nombre' });
    }
    if (!EXPRESION_CORREO.test(correoLimpio)) {
      return res.status(400).json({ mensaje: 'Ingresa un correo válido' });
    }
    if (!password || String(password).length < 6) {
      return res
        .status(400)
        .json({ mensaje: 'La contraseña debe tener al menos 6 caracteres' });
    }
    if (!ROLES_VALIDOS.includes(rolLimpio)) {
      return res.status(400).json({ mensaje: 'Rol no válido' });
    }

    const [existentes] = await pool.query(
      'SELECT id FROM usuarios WHERE correo = ?',
      [correoLimpio]
    );
    if (existentes.length) {
      return res.status(409).json({ mensaje: 'El correo ya está registrado' });
    }

    const hash = await bcrypt.hash(String(password), 10);
    await pool.query(
      'INSERT INTO usuarios (nombre, correo, password_hash, rol) VALUES (?, ?, ?, ?)',
      [nombreLimpio, correoLimpio, hash, rolLimpio]
    );

    res.status(201).json({ mensaje: 'Cuenta creada correctamente' });
  } catch (error) {
    next(error);
  }
});

// ---------------------------------------------------------------
// Recuperar contraseña (respuesta uniforme, sin envío de correo real)
// ---------------------------------------------------------------
router.post('/recuperar-contrasena', async (req, res, next) => {
  try {
    const { correo } = req.body || {};
    if (!correo || !EXPRESION_CORREO.test(String(correo).trim())) {
      return res.status(400).json({ mensaje: 'Ingresa un correo válido' });
    }

    res.json({
      mensaje: 'Si la cuenta existe, se enviaron las instrucciones a tu correo',
    });
  } catch (error) {
    next(error);
  }
});

// ---------------------------------------------------------------
// Perfil del usuario autenticado
// ---------------------------------------------------------------
router.get('/profile', autenticar, async (req, res, next) => {
  try {
    const [filas] = await pool.query(
      `${SELECT_USUARIO} WHERE u.id = ?`,
      [req.usuarioId]
    );
    if (!filas.length) {
      return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    }
    res.json({ usuario: usuarioPublico(filas[0]) });
  } catch (error) {
    next(error);
  }
});

// ---------------------------------------------------------------
// Limpiar la sesión (el cliente descarta el token localmente)
// ---------------------------------------------------------------
router.post('/logout', autenticar, (req, res) => {
  res.json({ mensaje: 'Sesión cerrada' });
});

module.exports = router;