class User {
  final int id;
  final String email;
  final String nombre;
  final String apellido;
  final String? telefono;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.nombre,
    required this.apellido,
    this.telefono,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'nombre': nombre,
    'apellido': apellido,
    'telefono': telefono,
    'createdAt': createdAt.toIso8601String(),
  };

  factory User.fromMap(Map<String, dynamic> map) => User(
    id: map['id'],
    email: map['email'],
    nombre: map['nombre'],
    apellido: map['apellido'],
    telefono: map['telefono'],
    createdAt: map['created_at'],
  );
}