import 'package:flutter/foundation.dart';

import '../models/oferta_servicio.dart';

class CurrentServiceSession {
  CurrentServiceSession._();

  static final CurrentServiceSession instance = CurrentServiceSession._();

  final ValueNotifier<OfertaServicio?> currentService =
      ValueNotifier<OfertaServicio?>(null);

  void setService(OfertaServicio? service) {
    currentService.value = service;
  }
}
