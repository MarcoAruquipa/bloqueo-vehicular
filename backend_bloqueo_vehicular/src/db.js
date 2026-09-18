const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');

const config = {
  host: process.env.DB_HOST || '127.0.0.1',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'bloqueo_vehicular',
  waitForConnections: true,
  connectionLimit: 10,
  dateStrings: true,
};

if (process.env.DB_SSL === '1') {
  config.ssl = { rejectUnauthorized: false };
}

const pool = mysql.createPool(config);

const DDL = [
  `CREATE TABLE IF NOT EXISTS usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(120) NOT NULL,
  correo VARCHAR(190) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  rol VARCHAR(30) NOT NULL DEFAULT 'conductor',
  vehiculo_id INT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`,

  `CREATE TABLE IF NOT EXISTS vehiculos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  placa VARCHAR(20) NOT NULL UNIQUE,
  marca VARCHAR(60) NOT NULL,
  modelo VARCHAR(60) NOT NULL,
  conductor_id INT NULL,
  estado VARCHAR(30) NOT NULL DEFAULT 'desconocido',
  compartiendo_ubicacion TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_vehiculos_conductor FOREIGN KEY (conductor_id)
    REFERENCES usuarios(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`,

  `CREATE TABLE IF NOT EXISTS dispositivos_esp32 (
  id INT AUTO_INCREMENT PRIMARY KEY,
  vehiculo_id INT NOT NULL,
  identificador VARCHAR(80) NOT NULL UNIQUE,
  estado VARCHAR(30) DEFAULT 'desconectado',
  ultima_conexion DATETIME NULL,
  wifi VARCHAR(30) DEFAULT 'desconocido',
  sensor VARCHAR(30) DEFAULT 'desconocido',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_dispositivos_vehiculo FOREIGN KEY (vehiculo_id)
    REFERENCES vehiculos(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`,

  `CREATE TABLE IF NOT EXISTS pruebas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  vehiculo_id INT NOT NULL,
  conductor_id INT NULL,
  nivel_alcohol INT NULL,
  resultado VARCHAR(30) NOT NULL,
  fecha DATE NOT NULL,
  hora TIME NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pruebas_vehiculo FOREIGN KEY (vehiculo_id)
    REFERENCES vehiculos(id) ON DELETE CASCADE,
  CONSTRAINT fk_pruebas_conductor FOREIGN KEY (conductor_id)
    REFERENCES usuarios(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`,

  `CREATE TABLE IF NOT EXISTS alertas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  vehiculo_id INT NOT NULL,
  tipo VARCHAR(50) NOT NULL,
  mensaje VARCHAR(255) NOT NULL,
  fecha DATE NOT NULL,
  hora TIME NOT NULL,
  estado VARCHAR(20) NOT NULL DEFAULT 'pendiente',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_alertas_vehiculo FOREIGN KEY (vehiculo_id)
    REFERENCES vehiculos(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`,

  `CREATE TABLE IF NOT EXISTS ubicaciones (
  id INT AUTO_INCREMENT PRIMARY KEY,
  vehiculo_id INT NOT NULL,
  conductor_id INT NULL,
  latitud DECIMAL(10,7) NOT NULL,
  longitud DECIMAL(10,7) NOT NULL,
  \`precision\` DOUBLE NULL,
  fecha DATE NOT NULL,
  hora TIME NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ubicaciones_vehiculo FOREIGN KEY (vehiculo_id)
    REFERENCES vehiculos(id) ON DELETE CASCADE,
  CONSTRAINT fk_ubicaciones_conductor FOREIGN KEY (conductor_id)
    REFERENCES usuarios(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`,
];

/**
 * Crea las tablas si no existen y, en una base vacía, inserta los datos
 * iniciales de demostración (usuario responsable, conductor y vehículo).
 */
async function bootstrap() {
  for (const sentencia of DDL) {
    await pool.query(sentencia);
  }

  const [filas] = await pool.query('SELECT COUNT(*) AS total FROM usuarios');
  if (Number(filas[0].total) === 0) {
    await seedInicial();
    console.log('Base de datos inicializada con datos de demostración.');
  }

  return true;
}

async function seedInicial() {
  const hash = await bcrypt.hash('123456', 10);

  const [responsable] = await pool.query(
    'INSERT INTO usuarios (nombre, correo, password_hash, rol) VALUES (?, ?, ?, ?)',
    ['Responsable', 'responsable@familia.com', hash, 'responsable']
  );

  const [conductor] = await pool.query(
    'INSERT INTO usuarios (nombre, correo, password_hash, rol) VALUES (?, ?, ?, ?)',
    ['Conductor', 'conductor@familia.com', hash, 'conductor']
  );

  const [vehiculo] = await pool.query(
    'INSERT INTO vehiculos (placa, marca, modelo, conductor_id, estado) VALUES (?, ?, ?, ?, ?)',
    ['ABC-123', 'Toyota', 'Corolla', conductor.insertId, 'desconocido']
  );

  await pool.query('UPDATE usuarios SET vehiculo_id = ? WHERE id = ?', [
    vehiculo.insertId,
    conductor.insertId,
  ]);

  await pool.query(
    'INSERT INTO dispositivos_esp32 (vehiculo_id, identificador, estado) VALUES (?, ?, ?)',
    [vehiculo.insertId, 'ESP32-MQ3-BV-001', 'desconectado']
  );
}

module.exports = { pool, bootstrap };