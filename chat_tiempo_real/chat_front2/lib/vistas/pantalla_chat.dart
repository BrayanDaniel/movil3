import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controladores/controlador_chat.dart';
import '../modelos/mensaje.dart';
import 'package:http/http.dart' as http;

class PantallaChat extends StatefulWidget {
  final String usuario;
  final String token;

  PantallaChat({required this.usuario, required this.token});

  @override
  _PantallaChatState createState() => _PantallaChatState();
}

class _PantallaChatState extends State<PantallaChat> {
  final ControladorChat _controladorChat = ControladorChat();
  final TextEditingController _controladorMensaje = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Mensaje> _mensajes = [];

  @override
  void initState() {
    super.initState();
    _cargarMensajes();
    _controladorChat.conectarSocket((mensaje) {
      setState(() {
        _mensajes.add(mensaje);
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controladorChat.desconectarSocket();
    _scrollController.dispose();
    super.dispose();
  }

  void _cargarMensajes() async {
    try {
      final mensajes = await _controladorChat.obtenerMensajes();
      setState(() {
        _mensajes = mensajes;
      });
      _scrollToBottom();
    } catch (e) {
      print('Error al cargar mensajes: $e');
    }
  }

  void _enviarMensaje() {
    if (_controladorMensaje.text.isNotEmpty) {
      final mensaje = Mensaje(
        usuario: widget.usuario,
        mensaje: _controladorMensaje.text,
      );
      _controladorChat.enviarMensaje(mensaje);
      _controladorMensaje.clear();
      _scrollToBottom();
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': widget.token}),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 10),
                Text("Error al cerrar sesión"),
              ],
            ),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 10),
              Text("Error de conexión con el servidor"),
            ],
          ),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat Room',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'Conectado como ${widget.usuario}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.blue[600],
        elevation: 2,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.logout, color: Colors.white),
              label: Text('Salir', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _logout(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _mensajes.length,
              itemBuilder: (context, index) {
                final msg = _mensajes[index];
                final bool isMe = msg.usuario == widget.usuario;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue[600] : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 1,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMe)
                          Text(
                            msg.usuario,
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        Text(
                          msg.mensaje,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controladorMensaje,
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _enviarMensaje(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: _enviarMensaje,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}