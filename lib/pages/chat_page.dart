import 'dart:async';

import 'package:flutter/material.dart';

import '../api/chat_api.dart';
import '../models/chat_message.dart';
import '../services/chat_ws_service.dart';

class ChatPage extends StatefulWidget {
  final ChatApi chatApi;
  final ChatWsService chatWs;

  const ChatPage({super.key, required this.chatApi, required this.chatWs});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  StreamSubscription<ChatMessage>? _wsSubscription;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _connectWs();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final fetched = await widget.chatApi.fetchMessages();
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(fetched);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar mensajes: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _connectWs() async {
    try {
      await widget.chatWs.connect();
      _wsSubscription = widget.chatWs.messages.listen((event) {
        if (!mounted) return;
        setState(() {
          _messages.add(event);
        });
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo conectar al chat: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    _messageController.clear();

    try {
      // Solo envía por REST; el backend creará el mensaje
      // y lo emitirá por WebSocket, que ya estás escuchando.
      await widget.chatApi.sendMessage(content);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo enviar el mensaje: $e')),
      );
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    widget.chatWs.disconnect();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final alignment = message.isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft;
                      final bubbleColor = message.isMine
                          ? Colors.blueAccent
                          : Colors.grey.shade300;
                      final textColor = message.isMine
                          ? Colors.white
                          : Colors.black87;
                      return Align(
                        alignment: alignment,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: bubbleColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            message.content,
                            style: TextStyle(color: textColor),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu mensaje',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
