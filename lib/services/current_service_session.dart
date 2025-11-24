import 'package:flutter/foundation.dart';

import '../models/service.dart';

class CurrentServiceSession {
  CurrentServiceSession._();

  static final CurrentServiceSession instance = CurrentServiceSession._();

  final ValueNotifier<Service?> currentService = ValueNotifier<Service?>(null);

  void setService(Service? service) {
    currentService.value = service;
  }
}
