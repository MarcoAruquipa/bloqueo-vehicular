-- Esquema de referencia de la base de datos del Sistema de Bloqueo Vehicular.
-- Las tablas se crean automáticamente al iniciar el servidor (ver src/db.js),
-- este archivo sirve como documentación y para configuraciones manuales.

CREATE TABLE IF NOT EXISTS usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(120) NOT NULL,
  correo VARCHAR(190) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  rol VARCHAR(30) NOT NULL DEFAULT 'conductor',
  vehiculo_id INT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS vehiculos (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS dispositivos_esp32 (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS pruebas (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS alertas (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ubicaciones (
  id INT AUTO_INCREMENT PRIMARY KEY,
  vehiculo_id INT NOT NULL,
  conductor_id INT NULL,
  latitud DECIMAL(10,7) NOT NULL,
  longitud DECIMAL(10,7) NOT NULL,
  precision DOUBLE NULL,
  fecha DATE NOT NULL,
  hora TIME NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ubicaciones_vehiculo FOREIGN KEY (vehiculo_id)
    REFERENCES vehiculos(id) ON DELETE CASCADE,
  CONSTRAINT fk_ubicaciones_conductor FOREIGN KEY (conductor_id)
    REFERENCES usuarios(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;