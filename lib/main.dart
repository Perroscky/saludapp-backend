import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'config/database.dart';
import 'routes/auth_routes.dart';
import 'routes/appointment_routes.dart';
import 'middleware/cors_middleware.dart';
import 'middleware/auth_middleware.dart';

void main() async {
  try {
    await DatabaseConfig.connection;
    print('✅ Conectado a PostgreSQL');
  } catch (e) {
    print('❌ Error al conectar: $e');
    return;
  }

  final app = Router();
  
  final authRoutes = AuthRoutes();
  app.mount('/auth', authRoutes.router);
  
  final appointmentRoutes = AppointmentRoutes();
  app.mount('/api', appointmentRoutes.router);

  final handler = const Pipeline()
      .addMiddleware(corsMiddleware())
      .addMiddleware(logRequests())
      .addMiddleware(
        (Handler handler) {
          return (Request request) async {
            if (request.url.path.startsWith('api/') || request.url.path.contains('api/')) {
              return await AuthMiddleware.requireAuth()(handler)(request);
            }
            return await handler(request);
          };
        },
      )
      .addHandler(app);

  try {
    final server = await serve(handler, 'localhost', 8080);
    print('🚀 Servidor: http://${server.address.host}:${server.port}');
    print('');
    print('📋 ENDPOINTS DISPONIBLES:');
    print('  POST /auth/register      - Registrar usuario');
    print('  POST /auth/login         - Iniciar sesión');
    print('  GET  /api/appointments   - Ver citas (Auth requerida) ✅');
    print('  GET  /api/appointments/bad - Ver citas con N+1 (Auth) ⚠️');
    print('  POST /api/appointments   - Crear cita (Auth requerida)');
    print('  GET  /api/especialidades - Especialidades (con caché)');
    print('');
    print('🔑 Para rutas /api/* enviar header:');
    print('  Authorization: Bearer <token>');
  } catch (e) {
    print('❌ Error al iniciar servidor: $e');
  }
}