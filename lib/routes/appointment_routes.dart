import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/appointment_service.dart';
import '../services/cache_service.dart';

class AppointmentRoutes {
  Router get router {
    final router = Router();
    
    // ✅ OBTENER CITAS - OPTIMIZADO
    router.get('/appointments', (Request request) async {
      try {
        final userId = request.context['userId'] as int?;
        if (userId == null) {
          return Response(401, body: jsonEncode({
            'error': 'Usuario no autenticado',
          }));
        }
        
        final startTime = DateTime.now();
        final appointments = await AppointmentService.getAppointmentsOptimized(userId);
        final duration = DateTime.now().difference(startTime).inMilliseconds;
        
        return Response.ok(jsonEncode({
          'count': appointments.length,
          'data': appointments,
          'optimized': true,
          'message': '✅ Usando Eager Loading - Sin N+1',
          'responseTime': '$duration ms',
        }));
      } catch (e) {
        print('❌ Error en /appointments: $e');
        return Response.ok(jsonEncode({
          'count': 0,
          'data': [],
          'optimized': true,
          'message': 'Sin citas disponibles',
          'responseTime': '0 ms',
        }));
      }
    });
    
    // 🔴 N+1 - PARA COMPARAR
    router.get('/appointments/bad', (Request request) async {
      try {
        final userId = request.context['userId'] as int?;
        if (userId == null) {
          return Response(401, body: jsonEncode({
            'error': 'Usuario no autenticado',
          }));
        }
        
        final startTime = DateTime.now();
        final appointments = await AppointmentService.getAppointmentsWithN1Problem(userId);
        final duration = DateTime.now().difference(startTime).inMilliseconds;
        
        return Response.ok(jsonEncode({
          'count': appointments.length,
          'data': appointments,
          'optimized': false,
          'warning': '⚠️ Esta versión tiene problema N+1',
          'responseTime': '$duration ms',
        }));
      } catch (e) {
        return Response.ok(jsonEncode({
          'count': 0,
          'data': [],
          'optimized': false,
          'warning': 'Error al obtener datos',
          'responseTime': '0 ms',
        }));
      }
    });
    
    // ➕ CREAR CITA
    router.post('/appointments', (Request request) async {
      try {
        final userId = request.context['userId'] as int?;
        if (userId == null) {
          return Response(401, body: jsonEncode({
            'success': false,
            'error': 'Usuario no autenticado',
          }));
        }
        
        final body = await request.readAsString();
        if (body.isEmpty) {
          return Response.badRequest(body: jsonEncode({
            'success': false,
            'error': 'Cuerpo de la petición vacío',
          }));
        }
        
        final data = jsonDecode(body);
        
        final doctorId = data['doctorId'] as int?;
        final fechaStr = data['fecha'] as String?;
        final notas = data['notas'] as String?;
        
        if (doctorId == null) {
          return Response.badRequest(body: jsonEncode({
            'success': false,
            'error': 'doctorId es requerido',
          }));
        }
        
        if (fechaStr == null) {
          return Response.badRequest(body: jsonEncode({
            'success': false,
            'error': 'fecha es requerida',
          }));
        }
        
        final fecha = DateTime.parse(fechaStr);
        
        final result = await AppointmentService.createAppointment(
          userId: userId,
          doctorId: doctorId,
          fecha: fecha,
          notas: notas,
        );
        
        return Response.ok(jsonEncode(result));
      } catch (e) {
        print('❌ Error en POST /appointments: $e');
        return Response.badRequest(body: jsonEncode({
          'success': false,
          'error': 'Error al procesar la solicitud: ${e.toString()}',
        }));
      }
    });
    
    // 🏥 ESPECIALIDADES (CON CACHÉ)
    router.get('/especialidades', (Request request) async {
      try {
        final startTime = DateTime.now();
        final especialidades = await CacheService.getEspecialidades();
        final duration = DateTime.now().difference(startTime).inMilliseconds;
        
        return Response.ok(jsonEncode({
          'data': especialidades,
          'cache': true,
          'responseTime': '$duration ms',
        }));
      } catch (e) {
        return Response.internalServerError(body: jsonEncode({
          'error': e.toString(),
        }));
      }
    });
    
    return router;
  }
}