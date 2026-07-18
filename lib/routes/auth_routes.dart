import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/auth_service.dart';

class AuthRoutes {
  Router get router {
    final router = Router();
    
    // Registrar usuario
    router.post('/register', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        
        final email = data['email'] as String?;
        final password = data['password'] as String?;
        final nombre = data['nombre'] as String?;
        final apellido = data['apellido'] as String?;
        final telefono = data['telefono'] as String?;
        
        if (email == null || password == null || nombre == null || apellido == null) {
          return Response.badRequest(body: jsonEncode({
            'error': 'Email, password, nombre y apellido son requeridos',
          }));
        }
        
        final result = await AuthService.register(
          email, password, nombre, apellido, telefono,
        );
        
        return Response.ok(jsonEncode(result));
      } catch (e) {
        return Response.badRequest(body: jsonEncode({
          'error': e.toString(),
        }));
      }
    });
    
    // Iniciar sesión
    router.post('/login', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        
        final email = data['email'] as String?;
        final password = data['password'] as String?;
        
        if (email == null || password == null) {
          return Response.badRequest(body: jsonEncode({
            'error': 'Email y password son requeridos',
          }));
        }
        
        final result = await AuthService.login(email, password);
        return Response.ok(jsonEncode(result));
      } catch (e) {
        return Response.badRequest(body: jsonEncode({
          'error': e.toString(),
        }));
      }
    });
    
    return router;
  }
}