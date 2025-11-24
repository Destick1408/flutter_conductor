class Service {
  Service({
    required this.id,
    required this.tipo,
    required this.estado,
    required this.metodoPago,
    required this.ofertado,
    required this.fechaSolicitud,
    required this.distanciaKm,
    required this.minutosEspera,
    required this.numeroParadas,
    required this.valorFinal,
    required this.valorBase,
    required this.pagado,
    required this.raw,
    this.fechaAceptacion,
    this.fechaInicio,
    this.fechaAbordo,
    this.fechaFinalizacion,
    this.observaciones,
    this.operador,
    this.cliente,
    this.conductor,
    this.vehiculo,
    this.origen,
    this.destino,
  });

  final int id;
  final String tipo;
  final String estado;
  final String metodoPago;
  final bool ofertado;
  final String fechaSolicitud;
  final String? fechaAceptacion;
  final String? fechaInicio;
  final String? fechaAbordo;
  final String? fechaFinalizacion;
  final String distanciaKm;
  final int minutosEspera;
  final int numeroParadas;
  final String valorFinal;
  final String valorBase;
  final bool pagado;
  final String? observaciones;
  final int? operador;
  final ServiceClient? cliente;
  final ServiceConductor? conductor;
  final ServiceVehiculo? vehiculo;
  final ServiceLocation? origen;
  final ServiceLocation? destino;
  final Map<String, dynamic> raw;

  factory Service.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    String _toString(dynamic value) {
      return value?.toString() ?? '';
    }

    return Service(
      id: _toInt(json['id']),
      tipo: _toString(json['tipo']),
      estado: _toString(json['estado']),
      metodoPago: _toString(json['metodo_pago']),
      ofertado: json['ofertado'] == true,
      fechaSolicitud: _toString(json['fecha_solicitud']),
      fechaAceptacion: json['fecha_aceptacion']?.toString(),
      fechaInicio: json['fecha_inicio']?.toString(),
      fechaAbordo: json['fecha_abordo']?.toString(),
      fechaFinalizacion: json['fecha_finalizacion']?.toString(),
      distanciaKm: _toString(json['distancia_km']),
      minutosEspera: _toInt(json['minutos_espera']),
      numeroParadas: _toInt(json['numero_paradas']),
      valorFinal: _toString(json['valor_final']),
      valorBase: _toString(json['valor_base']),
      pagado: json['pagado'] == true,
      observaciones: json['observaciones']?.toString(),
      operador: json['operador'] is int
          ? json['operador'] as int
          : int.tryParse(json['operador']?.toString() ?? ''),
      cliente: json['cliente'] is Map<String, dynamic>
          ? ServiceClient.fromJson(json['cliente'] as Map<String, dynamic>)
          : null,
      conductor: json['conductor'] is Map<String, dynamic>
          ? ServiceConductor.fromJson(json['conductor'] as Map<String, dynamic>)
          : null,
      vehiculo: json['vehiculo'] is Map<String, dynamic>
          ? ServiceVehiculo.fromJson(json['vehiculo'] as Map<String, dynamic>)
          : null,
      origen: json['origen'] is Map<String, dynamic>
          ? ServiceLocation.fromJson(json['origen'] as Map<String, dynamic>)
          : null,
      destino: json['destino'] is Map<String, dynamic>
          ? ServiceLocation.fromJson(json['destino'] as Map<String, dynamic>)
          : null,
      raw: json,
    );
  }

  static List<Service> listFromPaginatedJson(Map<String, dynamic> json) {
    final results = json['results'] as List<dynamic>? ?? [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(Service.fromJson)
        .toList();
  }

  Service copyWith({
    String? estado,
    Map<String, dynamic>? raw,
  }) {
    return Service(
      id: id,
      tipo: tipo,
      estado: estado ?? this.estado,
      metodoPago: metodoPago,
      ofertado: ofertado,
      fechaSolicitud: fechaSolicitud,
      fechaAceptacion: fechaAceptacion,
      fechaInicio: fechaInicio,
      fechaAbordo: fechaAbordo,
      fechaFinalizacion: fechaFinalizacion,
      distanciaKm: distanciaKm,
      minutosEspera: minutosEspera,
      numeroParadas: numeroParadas,
      valorFinal: valorFinal,
      valorBase: valorBase,
      pagado: pagado,
      observaciones: observaciones,
      operador: operador,
      cliente: cliente,
      conductor: conductor,
      vehiculo: vehiculo,
      origen: origen,
      destino: destino,
      raw: raw ?? this.raw,
    );
  }
}

class ServiceClient {
  const ServiceClient({
    required this.id,
    required this.nombre,
    this.apellido,
    this.telefono,
  });

  final int id;
  final String nombre;
  final String? apellido;
  final String? telefono;

  factory ServiceClient.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return ServiceClient(
      id: _toInt(json['id']),
      nombre: (json['nombre'] ?? json['first_name'] ?? '').toString(),
      apellido: (json['apellido'] ?? json['last_name'])?.toString(),
      telefono: json['telefono']?.toString(),
    );
  }

  String get nombreCompleto {
    final last = (apellido ?? '').trim();
    if (last.isEmpty) return nombre;
    return '$nombre $last'.trim();
  }
}

class ServiceUsuario {
  const ServiceUsuario({
    required this.id,
    required this.nombre,
    this.apellido,
    this.email,
  });

  final int id;
  final String nombre;
  final String? apellido;
  final String? email;

  factory ServiceUsuario.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return ServiceUsuario(
      id: _toInt(json['id']),
      nombre: (json['first_name'] ?? json['nombre'] ?? '').toString(),
      apellido: (json['last_name'] ?? json['apellido'])?.toString(),
      email: json['email']?.toString(),
    );
  }

  String get nombreCompleto {
    final last = (apellido ?? '').trim();
    if (last.isEmpty) return nombre;
    return '$nombre $last'.trim();
  }
}

class ServiceConductor {
  const ServiceConductor({
    required this.id,
    this.licencia,
    this.usuario,
  });

  final int id;
  final String? licencia;
  final ServiceUsuario? usuario;

  factory ServiceConductor.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return ServiceConductor(
      id: _toInt(json['id']),
      licencia: json['licencia']?.toString(),
      usuario: json['usuario'] is Map<String, dynamic>
          ? ServiceUsuario.fromJson(json['usuario'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ServiceVehiculo {
  const ServiceVehiculo({
    required this.id,
    this.placa,
    this.marca,
    this.modelo,
    this.unidad,
  });

  final int id;
  final String? placa;
  final String? marca;
  final String? modelo;
  final String? unidad;

  factory ServiceVehiculo.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return ServiceVehiculo(
      id: _toInt(json['id']),
      placa: json['placa']?.toString(),
      marca: json['marca']?.toString(),
      modelo: json['modelo']?.toString(),
      unidad: json['unidad']?.toString(),
    );
  }
}

class ServiceLocation {
  const ServiceLocation({
    required this.id,
    required this.direccion,
    required this.latitud,
    required this.longitud,
  });

  final int id;
  final String direccion;
  final String latitud;
  final String longitud;

  factory ServiceLocation.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    String _toString(dynamic value) {
      return value?.toString() ?? '';
    }

    return ServiceLocation(
      id: _toInt(json['id']),
      direccion: _toString(json['direccion'] ?? json['nombre']),
      latitud: _toString(json['latitud'] ?? json['lat']),
      longitud: _toString(json['longitud'] ?? json['lng']),
    );
  }
}
