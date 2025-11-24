import 'package:flutter/material.dart';
import 'package:flutter_conductor/models/user.dart';
import 'package:flutter_conductor/widgets/user_info.dart';
import 'package:flutter_conductor/pages/ofertada_page.dart';

class DrawerProfile extends StatelessWidget {
  final User? user;

  const DrawerProfile({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DrawerHeader(user: user),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  const _SectionLabel('Cuenta'),
                  _DrawerTile(
                    icon: Icons.history,
                    label: 'Historial',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/history');
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.local_offer,
                    label: 'Servicios ofertados',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OfertadaPage(),
                        ),
                      );
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.card_travel,
                    label: 'Voucher',
                    onTap: () {},
                  ),
                  const _SectionLabel('Servicios'),
                  _DrawerTile(
                    icon: Icons.create_new_folder,
                    label: 'Crear Servicio',
                    onTap: () {},
                  ),
                  _DrawerTile(
                    icon: Icons.lock_clock_rounded,
                    label: 'Para Reservar',
                    onTap: () {},
                  ),
                  const _SectionLabel('Ajustes'),
                  _DrawerTile(
                    icon: Icons.settings,
                    label: 'Configuración',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFD740), Color(0xFFFFEE58)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserInfo(user: user),
          const SizedBox(height: 12),
          Text(
            'Gestiona tu cuenta y servicios',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey[700],
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[800]),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      shape: const Border(
        bottom: BorderSide(color: Color(0xFFE0E0E0)),
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
