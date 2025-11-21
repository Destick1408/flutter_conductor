import 'package:flutter/material.dart';

import '../api/auth.dart';
import '../api/chat_api.dart';
import '../pages/chat_page.dart';
import '../services/chat_ws_service.dart';

class SimpleBottomNav extends StatelessWidget {
  final Color backgroundColor;
  final Color selectedColor;
  final Color unselectedColor;

  const SimpleBottomNav({
    super.key,
    this.backgroundColor = Colors.black,
    this.selectedColor = Colors.yellowAccent,
    this.unselectedColor = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.history),
              color: unselectedColor,
              onPressed: () => Navigator.pushNamed(context, '/history'),
              tooltip: 'Historial',
            ),
            IconButton(
              icon: const Icon(Icons.message),
              color: unselectedColor,
              onPressed: () async {
                final token = AuthApi.accessToken ?? await AuthApi.getAccessToken();
                final userId = AuthApi.currentUserId ?? await AuthApi.getCurrentUserId();

                if (token == null || token.isEmpty || userId == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Inicia sesión para abrir el chat')),
                    );
                  }
                  return;
                }

                final chatApi = ChatApi(conductorId: userId, token: token);
                final chatWs =
                    ChatWsService.forConductor(conductorId: userId, token: token);

                if (context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatPage(chatApi: chatApi, chatWs: chatWs),
                    ),
                  );
                }
              },
              tooltip: 'Mensaje',
            ),
            SizedBox(width: 48), // Espacio para el botón flotante
            IconButton(
              icon: const Icon(Icons.calendar_today),
              color: unselectedColor,
              onPressed: () {},
              tooltip: 'Reservas',
            ),
            IconButton(
              icon: const Icon(Icons.local_offer),
              color: unselectedColor,
              onPressed: () {},
              tooltip: 'Ofertas',
            ),
          ],
        ),
      ),
    );
  }
}
