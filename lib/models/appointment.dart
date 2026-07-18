class Appointment {
  final int id;
  final int userId;
  final int doctorId;
  final DateTime fecha;
  final int duracionMinutos;
  final String estado;
  final String? notas;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? doctorNombre;
  final String? doctorEspecialidad;
  final String? doctorConsultorio;

  Appointment({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.fecha,
    this.duracionMinutos = 30,
    this.estado = 'pendiente',
    this.notas,
    required this.createdAt,
    required this.updatedAt,
    this.doctorNombre,
    this.doctorEspecialidad,
    this.doctorConsultorio,
  });

  factory Appointment.fromMap(Map<String, dynamic> map) {
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    DateTime toDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return Appointment(
      id: toInt(map['id']),
      userId: toInt(map['user_id']),
      doctorId: toInt(map['doctor_id']),
      fecha: toDateTime(map['fecha']),
      duracionMinutos: toInt(map['duracion_minutos']),
      estado: map['estado']?.toString() ?? 'pendiente',
      notas: map['notas']?.toString(),
      createdAt: toDateTime(map['created_at']),
      updatedAt: toDateTime(map['updated_at']),
      doctorNombre: map['doctor_nombre']?.toString(),
      doctorEspecialidad: map['doctor_especialidad']?.toString(),
      doctorConsultorio: map['doctor_consultorio']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'doctorId': doctorId,
    'fecha': fecha.toIso8601String(),
    'duracionMinutos': duracionMinutos,
    'estado': estado,
    'notas': notas,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    if (doctorNombre != null) 'doctor': {
      'nombre': doctorNombre,
      'especialidad': doctorEspecialidad,
      'consultorio': doctorConsultorio,
    },
  };
}