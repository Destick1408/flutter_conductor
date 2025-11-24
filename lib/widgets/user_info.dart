import 'package:flutter/material.dart';
import 'package:flutter_conductor/models/user.dart';

class UserInfo extends StatelessWidget {
  final User? user;

  const UserInfo({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center, // centrado horizontal
        children: [
          // Usa la foto del usuario si existe, caso contrario una imagen por defecto
          NetworkImage(user?.fotoPerfil ?? '').url.isNotEmpty
              ? CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(user!.fotoPerfil!),
                )
              : const CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('assets/default_avatar.png'),
                ),

          const SizedBox(height: 8),

          Text(
            'Usuario: ${user?.username ?? ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Nombre: ${user?.firstName ?? ''} ${user?.lastName ?? ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            'DNI: ${user?.dni ?? ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            'Rol: ${user?.role ?? ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
