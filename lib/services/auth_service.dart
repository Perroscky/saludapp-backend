import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:postgres/postgres.dart';
import '../config/database.dart';

class AuthService {
  static const String _jwtSecret = 'mi_secreto_super_seguro_2024';
  
  // Registrar usuario
  static Future<Map<String, dynamic>> register(
    String email,
    String password,
    String nombre,
    String apellido,
    String? telefono,
  ) async {
    final conn = await DatabaseConfig.connection;
    
    // 🔧 Usar Sql.named para consultas con parámetros
    final existing = await conn.execute(
      Sql.named('SELECT id FROM users WHERE email = @email'),
      parameters: {'email': email},
    );
    
    if (existing.isNotEmpty) {
      throw Exception('El email ya está registrado');
    }
    
    final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());
    
    final result = await conn.execute(
      Sql.named('''
      INSERT INTO users (email, password_hash, nombre, apellido, telefono)
      VALUES (@email, @passwordHash, @nombre, @apellido, @telefono)
      RETURNING id, email, nombre, apellido, telefono, created_at
      '''),
      parameters: {
        'email': email,
        'passwordHash': passwordHash,
        'nombre': nombre,
        'apellido': apellido,
        'telefono': telefono,
      },
    );
    
    if (result.isEmpty) {
      throw Exception('Error al registrar usuario');
    }
    
    final userMap = result.first.toColumnMap();
    final userId = _toInt(userMap['id']);
    final token = _generateToken(userId);
    
    return {
      'user': {
        'id': userId,
        'email': userMap['email']?.toString() ?? '',
        'nombre': userMap['nombre']?.toString() ?? '',
        'apellido': userMap['apellido']?.toString() ?? '',
        'telefono': userMap['telefono']?.toString(),
      },
      'token': token,
    };
  }
  
  // Iniciar sesión
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final conn = await DatabaseConfig.connection;
    
    final result = await conn.execute(
      Sql.named('''
      SELECT id, email, password_hash, nombre, apellido, telefono
      FROM users
      WHERE email = @email
      '''),
      parameters: {'email': email},
    );
    
    if (result.isEmpty) {
      throw Exception('Credenciales inválidas');
    }
    
    final userMap = result.first.toColumnMap();
    
    final passwordValid = BCrypt.checkpw(password, userMap['password_hash']?.toString() ?? '');
    if (!passwordValid) {
      throw Exception('Credenciales inválidas');
    }
    
    final userId = _toInt(userMap['id']);
    final token = _generateToken(userId);
    
    return {
      'user': {
        'id': userId,
        'email': userMap['email']?.toString() ?? '',
        'nombre': userMap['nombre']?.toString() ?? '',
        'apellido': userMap['apellido']?.toString() ?? '',
        'telefono': userMap['telefono']?.toString(),
      },
      'token': token,
    };
  }
  
  static String _generateToken(int userId) {
    final jwt = JWT({
      'userId': userId,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': DateTime.now().add(Duration(hours: 24)).millisecondsSinceEpoch ~/ 1000,
    });
    return jwt.sign(SecretKey(_jwtSecret));
  }
  
  static Map<String, dynamic> verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      return {
        'valid': true,
        'userId': jwt.payload['userId'],
      };
    } catch (e) {
      return {
        'valid': false,
        'error': 'Token inválido',
      };
    }
  }
  
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}