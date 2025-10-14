class User {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? telefono;
  final String? fotoPerfil;
  final String? dni;
  final String? dateJoined;
  final String? lastLogin;
  final String? role;

  User({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.telefono,
    this.fotoPerfil,
    this.dni,
    this.dateJoined,
    this.lastLogin,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'] as int,
    username: j['username'] as String,
    firstName: (j['first_name'] ?? '') as String,
    lastName: (j['last_name'] ?? '') as String,
    email: j['email'] as String?,
    telefono: j['telefono'] as String?,
    fotoPerfil: j['foto_perfil'] as String?,
    dni: j['dni'] as String?,
    dateJoined: j['date_joined'] as String?,
    lastLogin: j['last_login'] as String?,
    role: j['role'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'telefono': telefono,
    'foto_perfil': fotoPerfil,
    'dni': dni,
    'date_joined': dateJoined,
    'last_login': lastLogin,
    'role': role,
  };
}
