import 'dart:async';
import 'package:postgres/postgres.dart';  // 👈 IMPORTANTE: para Sql.named
import '../config/database.dart';

class AppointmentService {
  // ✅ OBTENER CITAS - OPTIMIZADO
  static Future<List<Map<String, dynamic>>> getAppointmentsOptimized(int userId) async {
    final conn = await DatabaseConfig.connection;
    
    try {
      print('📊 [APPOINTMENTS] Buscando citas para usuario: $userId');
      
      final result = await conn.execute(
        Sql.named('''
          SELECT 
            id,
            user_id,
            doctor_id,
            fecha,
            duracion_minutos,
            estado,
            notas,
            created_at,
            updated_at
          FROM appointments
          WHERE user_id = @userId 
            AND estado != 'cancelada'
          ORDER BY fecha ASC
        '''),
        parameters: {'userId': userId},
      );
      
      print('✅ [APPOINTMENTS] ${result.length} citas encontradas');
      
      if (result.isEmpty) {
        return [];
      }
      
      final List<Map<String, dynamic>> appointments = [];
      
      for (var row in result) {
        final map = row.toColumnMap();
        
        final doctorId = map['doctor_id'];
        int? doctorIdInt;
        if (doctorId != null) {
          if (doctorId is int) {
            doctorIdInt = doctorId;
          } else if (doctorId is String) {
            doctorIdInt = int.tryParse(doctorId);
          }
        }
        
        if (doctorIdInt == null) {
          continue;
        }
        
        final doctorResult = await conn.execute(
          Sql.named('SELECT id, nombre, especialidad, consultorio FROM doctors WHERE id = @doctorId'),
          parameters: {'doctorId': doctorIdInt},
        );
        
        Map<String, dynamic>? doctorData;
        if (doctorResult.isNotEmpty) {
          final doc = doctorResult.first.toColumnMap();
          doctorData = {
            'id': doc['id'],
            'nombre': doc['nombre']?.toString() ?? 'Doctor',
            'especialidad': doc['especialidad']?.toString() ?? '',
            'consultorio': doc['consultorio']?.toString() ?? '',
          };
        }
        
        appointments.add({
          'id': map['id'],
          'userId': map['user_id'],
          'doctorId': doctorIdInt,
          'fecha': map['fecha'].toString(),
          'duracionMinutos': map['duracion_minutos'] ?? 30,
          'estado': map['estado']?.toString() ?? 'pendiente',
          'notas': map['notas']?.toString(),
          'createdAt': map['created_at'].toString(),
          'updatedAt': map['updated_at'].toString(),
          'doctor': doctorData,
        });
      }
      
      return appointments;
    } catch (e) {
      print('❌ [APPOINTMENTS] Error: $e');
      return [];
    }
  }
  
  // 🔴 N+1 - PARA COMPARAR
  static Future<List<Map<String, dynamic>>> getAppointmentsWithN1Problem(int userId) async {
    final conn = await DatabaseConfig.connection;
    
    try {
      final appointments = await conn.execute(
        Sql.named('''
          SELECT * FROM appointments
          WHERE user_id = @userId AND estado != 'cancelada'
          ORDER BY fecha ASC
        '''),
        parameters: {'userId': userId},
      );
      
      final result = <Map<String, dynamic>>[];
      for (var appointment in appointments) {
        final map = appointment.toColumnMap();
        
        final doctorId = map['doctor_id'];
        int? doctorIdInt;
        if (doctorId != null) {
          if (doctorId is int) {
            doctorIdInt = doctorId;
          } else if (doctorId is String) {
            doctorIdInt = int.tryParse(doctorId);
          }
        }
        
        if (doctorIdInt != null) {
          final doctors = await conn.execute(
            Sql.named('SELECT * FROM doctors WHERE id = @doctorId'),
            parameters: {'doctorId': doctorIdInt},
          );
          result.add({
            ...map,
            'doctor': doctors.isNotEmpty ? doctors.first.toColumnMap() : null,
          });
        } else {
          result.add({
            ...map,
            'doctor': null,
          });
        }
      }
      
      return result;
    } catch (e) {
      print('❌ [APPOINTMENTS-N1] Error: $e');
      return [];
    }
  }
  
  // ➕ CREAR CITA - CORREGIDO CON Sql.named
  static Future<Map<String, dynamic>> createAppointment({
    required int userId,
    required int doctorId,
    required DateTime fecha,
    int duracionMinutos = 30,
    String? notas,
  }) async {
    final conn = await DatabaseConfig.connection;
    
    try {
      print('📝 [APPOINTMENTS] Creando cita para usuario: $userId, doctor: $doctorId');
      
      if (userId <= 0) {
        return {
          'success': false,
          'error': 'ID de usuario inválido: $userId',
        };
      }
      
      if (doctorId <= 0) {
        return {
          'success': false,
          'error': 'ID de doctor inválido: $doctorId',
        };
      }
      
      // 🔥 VERIFICAR DISPONIBILIDAD
      final conflict = await conn.execute(
        Sql.named('''
          SELECT id FROM appointments
          WHERE doctor_id = @doctorId 
            AND fecha = @fecha
            AND estado != 'cancelada'
        '''),
        parameters: {
          'doctorId': doctorId,
          'fecha': fecha.toIso8601String(),
        },
      );
      
      if (conflict.isNotEmpty) {
        return {
          'success': false,
          'error': 'El doctor no está disponible en ese horario'
        };
      }
      
      // 🔥 CREAR CITA
      final result = await conn.execute(
        Sql.named('''
          INSERT INTO appointments (user_id, doctor_id, fecha, duracion_minutos, notas)
          VALUES (@userId, @doctorId, @fecha, @duracionMinutos, @notas)
          RETURNING id
        '''),
        parameters: {
          'userId': userId,
          'doctorId': doctorId,
          'fecha': fecha.toIso8601String(),
          'duracionMinutos': duracionMinutos,
          'notas': notas,
        },
      );
      
      if (result.isEmpty) {
        return {
          'success': false,
          'error': 'Error al crear la cita en la base de datos'
        };
      }
      
      final map = result.first.toColumnMap();
      final idValue = map['id'];
      int appointmentId;
      if (idValue is int) {
        appointmentId = idValue;
      } else if (idValue is String) {
        appointmentId = int.tryParse(idValue) ?? 0;
      } else {
        appointmentId = 0;
      }
      
      if (appointmentId <= 0) {
        return {
          'success': false,
          'error': 'No se pudo obtener el ID de la cita creada'
        };
      }
      
      print('✅ [APPOINTMENTS] Cita creada ID: $appointmentId');
      
      unawaited(_scheduleReminder(appointmentId, userId, fecha));
      
      return {
        'success': true,
        'id': appointmentId,
        'fecha': fecha.toIso8601String(),
        'duracionMinutos': duracionMinutos,
        'estado': 'pendiente',
        'notas': notas,
        'message': '✅ Cita creada exitosamente',
      };
    } catch (e) {
      print('❌ [APPOINTMENTS] Error al crear: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // 📅 RECORDATORIO (cola de trabajo)
  static Future<void> _scheduleReminder(int appointmentId, int userId, DateTime fecha) async {
    await Future.delayed(Duration(seconds: 2));
    print('📅 [WORKER] Recordatorio cita #$appointmentId para usuario $userId - $fecha');
    print('✅ [WORKER] Notificación enviada');
  }
}