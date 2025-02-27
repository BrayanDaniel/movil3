import 'package:chat_front2/vistas/pantalla_chat.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PantallaLogin extends StatelessWidget {
  final String email;
  final String token;

  PantallaLogin({required this.email, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Sala de Chat - Login',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 2,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              // Ícono de chat
              Icon(
                Icons.chat_bubble_rounded,
                size: 100,
                color: Colors.blue[600],
              ),
              SizedBox(height: 20),
              // Mensaje de bienvenida centrado
              Align(
                alignment: Alignment.center,
                child: Text(
                  'Bienvenido, usuario ${email}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
              SizedBox(height: 40),
              // Botón de iniciar chat
              Container(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // Navegar a la pantalla de chat al presionar el botón
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PantallaChat(
                          usuario: email,
                          token: token,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Iniciar Chat',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
