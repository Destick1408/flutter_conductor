import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Pedir todos los permisos necesarios
  static Future<bool> requestAllPermissions() async {
    debugPrint('📋 Solicitando permisos necesarios...');

    // 1. Permisos de ubicación
    final locationStatus = await Permission.location.request();
    debugPrint('📍 Permiso de ubicación: $locationStatus');

    // 2. Permiso de ubicación en segundo plano (Android 10+)
    if (await _isAndroid10OrHigher()) {
      final backgroundLocationStatus = await Permission.locationAlways
          .request();
      debugPrint(
        '🌍 Permiso de ubicación en segundo plano: $backgroundLocationStatus',
      );
    }

    // 3. Verificar todos los permisos
    final allGranted = await _checkAllPermissions();

    if (!allGranted) {
      debugPrint('⚠️ Algunos permisos no fueron concedidos');
      return false;
    }

    debugPrint('✅ Todos los permisos concedidos');
    return true;
  }

  // Pedir exclusión de optimización de batería
  static Future<void> requestBatteryOptimization() async {
    debugPrint('🔋 Solicitando exclusión de optimización de batería...');

    final status = await Permission.ignoreBatteryOptimizations.status;

    if (!status.isGranted) {
      final result = await Permission.ignoreBatteryOptimizations.request();
      debugPrint('🔋 Resultado: $result');

      if (result.isGranted) {
        debugPrint('✅ Exclusión de batería concedida');
      } else {
        debugPrint('⚠️ Exclusión de batería denegada');
      }
    } else {
      debugPrint('✅ Ya tiene exclusión de batería');
    }
  }

  // Verificar todos los permisos
  static Future<bool> _checkAllPermissions() async {
    final location = await Permission.location.status;
    final locationAlways = await Permission.locationAlways.status;

    return location.isGranted &&
        (locationAlways.isGranted || !(await _isAndroid10OrHigher()));
  }

  // Verificar si es Android 10 o superior
  static Future<bool> _isAndroid10OrHigher() async {
    // En Android 10+ (API 29+) se necesita locationAlways
    return true; // Simplificado, podrías usar device_info_plus para verificar
  }

  // Mostrar diálogo si los permisos fueron denegados permanentemente
  static Future<void> showPermissionDeniedDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permisos necesarios'),
        content: const Text(
          'Esta aplicación necesita permisos de ubicación y optimización de batería '
          'para funcionar correctamente en segundo plano.\n\n'
          '¿Deseas abrir la configuración para conceder los permisos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Abrir configuración'),
          ),
        ],
      ),
    );
  }

  // Verificar estado de permisos
  static Future<Map<String, bool>> checkPermissionsStatus() async {
    return {
      'location': (await Permission.location.status).isGranted,
      'locationAlways': (await Permission.locationAlways.status).isGranted,
      'batteryOptimization':
          (await Permission.ignoreBatteryOptimizations.status).isGranted,
    };
  }
}
