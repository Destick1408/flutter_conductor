class OfertaServicio {
  final int id;
  final String tipo;
  final String estado;
  final String origenDireccion;
  final String origenLatitud;
  final String origenLongitud;
  final Map<String, dynamic> raw;

  OfertaServicio({
    required this.id,
    required this.tipo,
    required this.estado,
    required this.origenDireccion,
    required this.origenLatitud,
    required this.origenLongitud,
    required this.raw,
  });

  factory OfertaServicio.fromJson(Map<String, dynamic> json) {
    final origen = json['origen'] as Map<String, dynamic>? ?? {};
    return OfertaServicio(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      tipo: (json['tipo'] ?? '') as String,
      estado: (json['estado'] ?? '') as String,
      origenDireccion: (origen['direccion'] ?? '') as String,
      origenLatitud: (origen['latitud'] ?? '') as String,
      origenLongitud: (origen['longitud'] ?? '') as String,
      raw: json,
    );
  }

  static List<OfertaServicio> listFromPaginatedJson(Map<String, dynamic> json) {
    final results = json['results'] as List<dynamic>? ?? [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(OfertaServicio.fromJson)
        .toList();
  }

  OfertaServicio copyWith({String? estado, Map<String, dynamic>? raw}) {
    return OfertaServicio(
      id: id,
      tipo: tipo,
      estado: estado ?? this.estado,
      origenDireccion: origenDireccion,
      origenLatitud: origenLatitud,
      origenLongitud: origenLongitud,
      raw: raw ?? this.raw,
    );
  }
}
