import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../services/auth_service.dart';

class AuthMiddleware {
  static Middleware requireAuth() {
    return (Handler handler) {
      return (Request request) async {
        // 🔥 LOG 1: Verificar que el middleware se ejecuta
        print('🔍 [AUTH] Middleware ejecutado para: ${request.url.path}');
        
        // 🔥 LOG 2: Ver todos los headers
        print('📋 [AUTH] Headers: ${request.headers}');
        
        // 1. Obtener el header Authorization
        final authHeader = request.headers['Authorization'];
        
        // 🔥 LOG 3: Verificar si el header existe
        print('🔑 [AUTH] Header Authorization: $authHeader');
        
        // 2. Verificar que existe y tiene el formato correcto
        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          print('❌ [AUTH] Token no proporcionado o formato incorrecto');
          return Response(401, body: jsonEncode({
            'error': 'Token de autenticación requerido',
          }));
        }

        // 3. Extraer el token
        final token = authHeader.substring(7);
        print('🔑 [AUTH] Token recibido: ${token.substring(0, 20)}...');

        // 4. Verificar el token
        final verification = AuthService.verifyToken(token);
        
        if (!verification['valid']) {
          print('❌ [AUTH] Token inválido: ${verification['error']}');
          return Response(401, body: jsonEncode({
            'error': verification['error'] ?? 'Token inválido',
          }));
        }

        // 5. Agregar userId al contexto
        final userId = verification['userId'];
        print('✅ [AUTH] Usuario autenticado: $userId');
        
        final updatedRequest = request.change(
          context: {'userId': userId},
        );

        return await handler(updatedRequest);
      };
    };
  }
}