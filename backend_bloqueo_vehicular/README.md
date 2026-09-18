# Backend: Bloqueo Vehicular por Detección de Alcohol

API REST (Node.js + Express + MySQL) del **Sistema Inteligente de Bloqueo Vehicular por Detección de Alcohol**. Guarda usuarios (responsable/conductor), vehículos, estado del ESP32, pruebas de alcohol, alertas y ubicaciones del teléfono del conductor.

Al iniciar crea las 6 tablas automáticamente y, si la base está vacía, carga datos de demostración:

| Acceso | Correo | Contraseña | Rol |
| --- | --- | --- | --- |
| Responsable | `responsable@familia.com` | `123456` | responsable |
| Conductor | `conductor@familia.com` | `123456` | conductor |

Vehículo de demostración: **ABC-123** (Toyota Corolla), con ESP32 `ESP32-MQ3-BV-001`.

## Requisitos

- Node.js 18+
- MySQL/MariaDB (en Northflank: addon MySQL)

## Configuración local

```bash
npm install
# copia .env.example a .env y ajusta las credenciales locales
npm start
```

Copia `.env.example` a `.env` y ajusta (`DB_HOST=127.0.0.1`, `DB_USER=root`, `DB_PASSWORD=vacia`, `DB_NAME=bloqueo_vehicular`, `DB_SSL=0`). El `npm start` crea las tablas y los datos iniciales.

## Despliegue en Northflank

1. Sube esta carpeta a un repositorio Git (con el `Dockerfile` incluido).
2. En Northflank crea un **Proyecto** nuevo (p. ej. `bloqueo-vehicular`).
3. Crea un **Addon MariaDB/MySQL** y anota host, puerto, usuario, contraseña y base de datos.
4. Crea un **Servicio** tipo *Microservice* → *Source: Repo* → *Dockerfile*.
5. Configura las variables del servicio (ver `.env.example`), usando las credenciales del addon:
   - `PORT=8080`
   - `DB_HOST` = host del addon, `DB_PORT=3306`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`
   - `DB_SSL=1`
   - `JWT_SECRET` = secreto largo
   - `API_ESP32_KEY` = clave que usará el ESP32 (opcional)
6. Despliega. Northflank asigna una URL pública del tipo:
   `https://backend-bloqueo-vehicular--<tu-region>.code.run`
7. En la app Flutter usa esa URL:
   ```bash
   flutter run --dart-define=API_BASE_URL=https://backend-bloqueo-vehicular--xxxxxxx.code.run
   ```

## Endpoints

Todos devuelven JSON y, salvo los públicos, exigen `Authorization: Bearer <token>`.

### Públicos
| Método | Ruta | Descripción |
| --- | --- | --- |
| POST | `/login` | `{correo, password}` → `{token, usuario}` |
| POST | `/register` | `{nombre, correo, password, rol}` |
| POST | `/recuperar-contrasena` | `{correo}` (respuesta uniforme) |
| GET | `/health` | Estado del servicio |

### Autenticados (app Flutter)
| Método | Ruta | Descripción |
| --- | --- | --- |
| GET | `/profile` | Perfil del usuario autenticado |
| POST | `/logout` | Cierra sesión |
| GET | `/vehiculos` | Lista de vehículos |
| GET | `/vehiculos/:id` | Detalle de un vehículo |
| GET | `/pruebas` | Pruebas de alcohol (filtra con `?vehiculo_id=`) |
| GET | `/pruebas/:id` | Detalle de una prueba |
| GET | `/alertas` | Alertas del sistema |
| PUT | `/alertas/:id` | Actualiza el estado de una alerta |
| GET | `/estado-esp32?vehiculo_id=` | Estado del ESP32 del vehículo |
| GET | `/ubicacion/:vehiculoId` | Última ubicación (404 si no existe) |
| GET | `/ubicaciones/:vehiculoId` | Historial de ubicaciones |
| POST | `/api/ubicaciones` | El conductor envía su ubicación |
| POST | `/api/ubicacion/iniciar` | Inicia la compartición |
| POST | `/api/ubicacion/detener` | Detiene la compartición |

### Dispositivo (ESP32)
Puede usar el token de un usuario o la cabecera `X-API-KEY <API_ESP32_KEY>`.
| Método | Ruta | Descripción |
| --- | --- | --- |
| POST | `/api/esp32/estado` | Reporta wifi/sensor y prueba de alcohol; registra prueba y alertas automáticamente |
| PUT | `/api/esp32/desbloquear` | `{vehiculo_id}`: desbloquea el vehículo |

Ejemplo de reporte del ESP32 (nivel ≥ 100 ⇒ `bloqueado`, si no `normal`):

```json
POST /api/esp32/estado
{
  "identificador": "ESP32-MQ3-BV-001",
  "estado": "conectado",
  "wifi": "conectado",
  "sensor": "listo",
  "nivel_alcohol": 150,
  "resultado": "bloqueado"
}
```

## Notas académicas

- **Nunca se inventan ubicaciones:** solo se guardan las coordenadas enviadas por el GPS del teléfono del conductor.
- **Flutter no controla el relé:** el bloqueo/desbloqueo es responsabilidad del ESP32; el backend solo registra el estado y genera alertas.
- La recuperación de contraseña no envía correos reales (respuesta uniforme por seguridad); puede integrarse un proveedor de email después.