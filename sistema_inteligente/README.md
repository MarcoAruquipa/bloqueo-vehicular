# sistema_inteligente

Aplicación móvil **Flutter** del proyecto académico:

> **“Sistema Inteligente de Bloqueo Vehicular por Detección de Alcohol”**

Aplicación de **uso familiar**. Permite monitorear el vehículo, consultar las
pruebas de alcohol, ver alertas, el estado del ESP32 y la ubicación del
vehículo a partir del **GPS del teléfono del conductor**.

> **El ESP32 NO tiene GPS.** La ubicación se obtiene del teléfono del conductor
> con su autorización y se envía a la API.
>
> **Flutter NO controla el relé ni desbloquea el vehículo.** El bloqueo físico
> es responsabilidad del ESP32.

---

## 1. Arquitectura

```
Sistema físico:            Ubicación:
MQ-3                       GPS del celular
  ↓                          ↓
ESP32                      Flutter del conductor
  ↓                          ↓
Wi-Fi                      API
  ↓                          ↓
API                        Northflank
  ↓                          ↓
Northflank                 Base de datos
  ↓                          ↓
Base de datos              Flutter del responsable
                             ↓
                           Mapa
```

---

## 2. Requisitos

- Flutter 3.41+ / Dart 3.11+ (probado con estas versiones).
- Android Studio / Xcode según la plataforma.
- Una cuenta/API en **Northflank** con el backend desplegado.
- Una **clave de Google Maps** (para el mapa).

---

## 3. Crear el proyecto e instalar dependencias

```bash
flutter create sistema_inteligente
cd sistema_inteligente
flutter pub add http provider geolocator google_maps_flutter \
    flutter_secure_storage intl connectivity_plus
```

### ¿Para qué sirve cada dependencia?

| Paquete | Uso en el proyecto |
|---|---|
| `http` | Peticiones HTTP a la API de Northflank. |
| `provider` | Manejo de estado (`AuthProvider`, `VehiculoProvider`, `UbicacionProvider`). |
| `geolocator` | Permisos y obtención de la **ubicación real** del teléfono. |
| `google_maps_flutter` | Mapa con el marcador del vehículo y el recorrido del historial. |
| `flutter_secure_storage` | Persistencia **segura** de la sesión (token + usuario). |
| `intl` | Formato de fecha (`dd/MM/yyyy`) y hora (`HH:mm:ss`). |
| `connectivity_plus` | Disponible para detectar conectividad; el manejo de “Sin conexión” ya está en `ApiService`. |

---

## 4. Estructura del proyecto

```
lib/
├── main.dart
├── models/
│   ├── usuario.dart
│   ├── vehiculo.dart
│   ├── prueba.dart
│   ├── alerta.dart
│   ├── dispositivo_esp32.dart
│   └── ubicacion.dart
├── screens/
│   ├── login_screen.dart
│   ├── registro_screen.dart
│   ├── dashboard_screen.dart
│   ├── vehiculos_screen.dart
│   ├── pruebas_screen.dart
│   ├── alertas_screen.dart
│   ├── ubicacion_screen.dart
│   ├── compartir_ubicacion_screen.dart
│   └── historial_ubicacion_screen.dart
├── services/
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── vehiculo_service.dart
│   ├── prueba_service.dart
│   ├── alerta_service.dart
│   ├── esp32_service.dart
│   └── ubicacion_service.dart
├── providers/
│   ├── auth_provider.dart
│   ├── vehiculo_provider.dart
│   └── ubicacion_provider.dart
├── widgets/
│   ├── vehicle_card.dart
│   ├── status_card.dart
│   ├── alert_card.dart
│   ├── location_map.dart
│   └── location_status_card.dart
├── routes/
│   └── app_routes.dart
├── config/
│   └── api_config.dart
└── utils/
    └── constants.dart
```

---

## 5. Configurar `API_BASE_URL`

El backend compatible se encuentra en la carpeta
`..\backend_bloqueo_vehicular` (Node.js/Express + MySQL, listo para desplegar
en **Northflank** como servicio aparte). Una vez desplegado expone una URL del
tipo:

```
https://backend-bloqueo-vehicular--<region>.code.run
```

`lib/config/api_config.dart` define la URL base y una clave opcional de la
API. Se pueden sobrescribir al compilar sin tocar el código:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://backend-bloqueo-vehicular--xxxx.code.run \
  --dart-define=API_KEY=tu-clave \
  --dart-define=API_KEY_HEADER=X-API-KEY
```

- `API_BASE_URL`: URL pública del backend en Northflank.
- `API_KEY`: clave/token si Northflank (o tu API) la exige. Si está vacía no
  se envía.
- `API_KEY_HEADER`: nombre de la cabecera (valor por defecto `X-API-KEY`).

Si no se definen, se usan los valores por defecto en `api_config.dart`
(`https://tu-app.northflank.app`).

> En Android, durante el desarrollo con un backend `http://` en red local, el
> `AndroidManifest.xml` ya incluye `android:usesCleartextTraffic="true"`.
> El backend real de Northflank usa **HTTPS**.

---

## 6. Permisos de plataforma

### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

Y la clave de Google Maps:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="TU_CLAVE_DE_GOOGLE_MAPS"/>
```

### iOS (`ios/Runner/Info.plist`)

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Para mostrar la ubicación del vehículo al responsable autorizado...</string>
```

---

## 7. Ubicación: GPS del celular del conductor

- Se usa `geolocator` para pedir el permiso y leer la posición **real**.
- La app **nunca inventa coordenadas**.
- El conductor decide **compartir o dejar de compartir**.
- La frecuencia de envío es configurable (15 s, 30 s, 1 min, 5 min) para no
  consumir de más la batería ni los datos.

Datos enviados (`POST /api/ubicaciones`):

```json
{
  "vehiculo_id": 1,
  "conductor_id": 2,
  "latitud": -16.5000,
  "longitud": -68.1500,
  "precision": 10,
  "fecha": "2026-09-17",
  "hora": "12:15:00"
}
```

### Estados que muestra la app

| Situación | Mensaje |
|---|---|
| Compartiendo | `Ubicación compartida` |
| Detenido | `Ubicación no compartida` |
| Permiso denegado | `Permiso de ubicación requerido` |
| Sin Internet | `Sin conexión` + última ubicación registrada |
| Ubicación del teléfono apagada | `Activa la ubicación del teléfono para compartir tu posición` |

---

## 8. Ubicación actualizada vs. última ubicación conocida

En `lib/utils/constants.dart` (`UbicacionConfig.maxEdadReciente`) se define el
umbral (5 minutos). El responsable ve:

- **Ubicación actualizada** → llegó hace menos de 5 minutos.
- **Última ubicación conocida** → es más antigua; se indica **Sin conexión** y
  la hora exacta de la última actualización. Nunca se muestra una ubicación
  antigua como si fuera actual.

---

## 9. Endpoints del backend

El backend `backend_bloqueo_vehicular` implementa estos endpoints (ver su
README para el detalle completo):

```
POST /login
POST /register
POST /recuperar-contrasena
GET  /profile
POST /logout
GET  /vehiculos
GET  /vehiculos/{id}
GET  /pruebas            (filtra con ?vehiculo_id=)
GET  /pruebas/{id}
GET  /alertas
PUT  /alertas/{id}
GET  /estado-esp32?vehiculo_id={id}
GET  /ubicacion/{vehiculo_id}
GET  /ubicaciones/{vehiculo_id}
POST /api/ubicaciones
POST /api/ubicacion/iniciar
POST /api/ubicacion/detener
```

Endpoints del dispositivo **ESP32** (autentica con `X-API-KEY` o JWT):

```
POST /api/esp32/estado        (reporta wifi/sensor y registra la prueba)
PUT  /api/esp32/desbloquear   (desbloquea el vehículo)
```

Al iniciar por primera vez, el backend crea las 6 tablas y dos cuentas de
demostración (contraseña `123456`): `responsable@familia.com` y
`conductor@familia.com`, con el vehículo `ABC-123`.

Respuesta esperada de `POST /login`:

```json
{
  "token": "jwt...",
  "usuario": {
    "id": 2,
    "nombre": "Juan Pérez",
    "correo": "juan@ejemplo.com",
    "rol": "conductor",
    "vehiculo_id": 1,
    "vehiculo_placa": "ABC-123"
  }
}
```

---

## 10. Base de datos (SQL sugerido)

```sql
CREATE TABLE usuarios (
  id            SERIAL PRIMARY KEY,
  nombre        VARCHAR(120) NOT NULL,
  correo        VARCHAR(160) UNIQUE NOT NULL,
  contrasena    VARCHAR(255) NOT NULL,
  rol           VARCHAR(20)  NOT NULL   -- 'responsable' | 'conductor'
);

CREATE TABLE vehiculos (
  id            SERIAL PRIMARY KEY,
  placa         VARCHAR(20) NOT NULL,
  marca         VARCHAR(60),
  modelo        VARCHAR(60),
  conductor_id  INTEGER REFERENCES usuarios(id),
  estado        VARCHAR(20) DEFAULT 'desconocido'
);

CREATE TABLE pruebas (
  id             SERIAL PRIMARY KEY,
  vehiculo_id    INTEGER REFERENCES vehiculos(id),
  conductor_id   INTEGER REFERENCES usuarios(id),
  nivel_alcohol  INTEGER,
  resultado      VARCHAR(30),          -- 'Normal' | 'Bloqueado' | 'Error de lectura'
  fecha          DATE,
  hora           TIME
);

CREATE TABLE alertas (
  id           SERIAL PRIMARY KEY,
  vehiculo_id  INTEGER REFERENCES vehiculos(id),
  tipo         VARCHAR(60),
  mensaje      TEXT,
  fecha        DATE,
  hora         TIME,
  estado       VARCHAR(20) DEFAULT 'pendiente'
);

CREATE TABLE dispositivos_esp32 (
  id               SERIAL PRIMARY KEY,
  vehiculo_id      INTEGER REFERENCES vehiculos(id),
  identificador    VARCHAR(80),
  estado           VARCHAR(20) DEFAULT 'desconectado',
  ultima_conexion  TIMESTAMP
);

CREATE TABLE ubicaciones (
  id            SERIAL PRIMARY KEY,
  vehiculo_id   INTEGER REFERENCES vehiculos(id),
  conductor_id  INTEGER REFERENCES usuarios(id),
  latitud       DOUBLE PRECISION,
  longitud      DOUBLE PRECISION,
  precision     DOUBLE PRECISION,
  fecha         DATE,
  hora          TIME
);
```

---

## 11. Ejecutar la aplicación

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://backend-bloqueo-vehicular--xxxx.code.run
```

Para Android con el mapa, recuerda colocar tu clave en el `AndroidManifest.xml`.

---

## 12. Pruebas manuales sugeridas

1. **Login**: credenciales válidas redirigen al dashboard según el rol.
   Credenciales inválidas y API caída muestran el mensaje correspondiente.
2. **Sin Internet**: activa modo avión. La app muestra `Sin conexión a Internet`
   o `No se pudo conectar con el servidor` y conserva la última ubicación.
3. **Permiso de ubicación**: rechaza el permiso. La app muestra
   `Permiso de ubicación requerido` y **no** intenta obtener la ubicación.
4. **Ubicación actualizada**: con el conductor compartiendo, el responsable ve
   la posición y el estado *Ubicación actualizada*.
5. **Última ubicación conocida**: detén el envío o espera más del umbral; el
   responsable ve *Última ubicación conocida / Sin conexión* con la hora.
6. **ESP32 desconectado**: el dashboard y el detalle del vehículo muestran
   `El ESP32 está desconectado`.
7. **Historial**: la pantalla muestra lista + mapa con la línea del recorrido.

---

## 13. Qué NO hace la aplicación (por diseño)

- No incluye GPS en el ESP32.
- No genera coordenadas falsas.
- No desbloquea ni controla el relé: **solo monitorea**.
- No obtiene ubicación si el conductor no autorizó el permiso.
- No oculta que la ubicación está siendo compartida.
- No muestra una ubicación vieja como si fuera la actual.

---

## 14. Notas para conectar el ESP32

1. El ESP32 envía sus lecturas y su estado a la API por Wi-Fi al endpoint
   `POST /api/esp32/estado` (identificador, wifi, sensor, `nivel_alcohol`,
   `resultado`). El backend registra la prueba, actualiza el estado del
   vehículo y genera una alerta si el nivel supera el umbral (≥ 100).
2. Flutter **lee** esa información (`GET /estado-esp32?vehiculo_id=...`);
   no envía comandos de bloqueo/desbloqueo. El desbloqueo lo hace el ESP32
   (`PUT /api/esp32/desbloquear`).
3. La ubicación del vehículo proviene **únicamente** del teléfono del conductor
   (`POST /api/ubicaciones`), nunca del ESP32.
