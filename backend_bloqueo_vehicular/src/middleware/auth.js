const jwt = require('jsonwebtoken');

const { pool } = require('../db');

const SECRETO = () => process.env.JWT_SECRET || 'cambio-este-secreto';

/**
 * Requiere un token JWT válido en la cabecera Authorization (Bearer).
 * Adjunta `req.usuarioId` y `req.rol`.
 */
async function autenticar(req, res, next) {
  const cabecera = req.headers.authorization || '';
  const token = cabecera.startsWith('Bearer ') ? cabecera.slice(7) : null;
  if (!token) {
    return res.status(401).json({
      mensaje: 'No autorizado',
      error: 'Credenciales incorrectas o sesión expirada',
    });
  }

  try {
    const payload = jwt.verify(token, SECRETO());
    const [filas] = await pool.query('SELECT id FROM usuarios WHERE id = ?', [
      payload.sub,
    ]);
    if (!filas.length) {
      return res.status(401).json({
        mensaje: 'No autorizado',
        error: 'Credenciales incorrectas o sesión expirada',
      });
    }
    req.usuarioId = payload.sub;
    req.rol = payload.rol;
    return next();
  } catch (_) {
    return res.status(401).json({
      mensaje: 'Sesión expirada o inválida',
      error: 'Credenciales incorrectas o sesión expirada',
    });
  }
}

/**
 * Permite el acceso al ESP32 mediante un token JWT válido o mediante la
 * clave de API configurada en `API_ESP32_KEY` (cabecera `X-API-KEY`).
 */
async function autenticarDispositivo(req, res, next) {
  const cabecera = req.headers.authorization || '';
  const token = cabecera.startsWith('Bearer ') ? cabecera.slice(7) : null;

  const cabeceraClave = (process.env.ESP32_KEY_HEADER || 'x-api-key').toLowerCase();
  const claveRecibida = (req.headers[cabeceraClave] || '').toString();
  const claveEsperada = process.env.API_ESP32_KEY || '';

  let valido = false;

  if (claveEsperada && claveRecibida === claveEsperada) {
    valido = true;
  }

  if (token) {
    try {
      jwt.verify(token, SECRETO());
      valido = true;
    } catch (_) {
      // token inválido: se evalúa la clave de API
    }
  }

  if (!valido) {
    return res.status(401).json({
      mensaje: 'No autorizado',
      error: 'Credenciales incorrectas o sesión expirada',
    });
  }

  return next();
}

module.exports = { autenticar, autenticarDispositivo };