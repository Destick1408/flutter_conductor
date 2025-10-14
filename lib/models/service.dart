class Service {
  final int id;
  final String clienteNombre;
  final String origenDireccion;
  final String destinoDireccion;
  final String fechaSolicitud;
  final String estado;
  final Map<String, dynamic> raw; // guardamos todo el JSON original

  Service({
    required this.id,
    required this.clienteNombre,
    required this.origenDireccion,
    required this.destinoDireccion,
    required this.fechaSolicitud,
    required this.estado,
    required this.raw,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as int,
      clienteNombre: (json['cliente']?['nombre'] ?? '') as String,
      origenDireccion: (json['origen']?['direccion'] ?? '') as String,
      destinoDireccion: (json['destino']?['direccion'] ?? '') as String,
      fechaSolicitud: (json['fecha_solicitud'] ?? '') as String,
      estado: (json['estado'] ?? '') as String,
      raw: json,
    );
  }

  static List<Service> listFromJson(Map<String, dynamic> json) {
    final results = json['results'] as List<dynamic>? ?? [];
    return results
        .map((e) => Service.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
