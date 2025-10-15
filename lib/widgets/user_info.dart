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
        children: [
          NetworkImage(user?.fotoPerfil ?? '').url.isNotEmpty
              ? CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(user!.fotoPerfil!),
                )
              : const CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('assets/default_avatar.png'),
                ),
          Text('Usuario: ${user?.username ?? ''}'),
          Text('Nombre: ${user?.firstName ?? ''} ${user?.lastName ?? ''}'),
          Text('DNI: ${user?.dni ?? ''}'),
          Text('Rol: ${user?.role ?? ''}'),
        ],
      ),
    );
  }
}
