/// Configuración centralizada de la API.
///
/// Se configura al compilar con `--dart-define`:
///
/// flutter run \
///   --dart-define=API_BASE_URL=https://mi-app.northflank.app \
///   --dart-define=API_KEY=tu-clave \
///   --dart-define=API_KEY_HEADER=X-API-KEY
///
/// Si no se definen, se usan los valores por defecto.
class ApiConfig {
  ApiConfig._();

  /// URL pública del backend en Northflank.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://tu-app.northflank.app',
  );

  /// Clave (token) de la API si Northflank la exige.
  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '',
  );

  /// Cabecera donde se envía la clave de la API.
  static const String apiKeyHeader = String.fromEnvironment(
    'API_KEY_HEADER',
    defaultValue: 'X-API-KEY',
  );

  static const Duration tiempoLimitePeticion = Duration(seconds: 12);
}