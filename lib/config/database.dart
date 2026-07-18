import 'package:postgres/postgres.dart';

class DatabaseConfig {
  static Connection? _connection;
  
  static Future<Connection> get connection async {
    if (_connection != null) return _connection!;
    
    try {
      _connection = await Connection.open(
        Endpoint(
          host: 'localhost',
          port: 5432,
          database: 'saludapp',
          username: 'postgres',
          password: 'Loany2021', // 👈 ¡CONTRASEÑA QUE USAS!
        ),
        settings: ConnectionSettings(
          sslMode: SslMode.disable,
        ),
      );
      
      print('✅ Conectado a PostgreSQL');
      return _connection!;
    } catch (e) {
      print('❌ Error al conectar: $e');
      rethrow;
    }
  }
  
  static Future<void> close() async {
    await _connection?.close();
    print('✅ Conexión cerrada');
  }
}