import 'dart:convert';
import 'package:chat_front2/vistas/pantalla_login.dart';
import 'package:chat_front2/vistas/registerscreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _passwordVisible = false;

  Future<void> loginUser() async {
    final String email = emailController.text;
    final String password = passwordController.text;

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String token = responseData['token'];
        String uid = responseData['uid'];

        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PantallaLogin(
                  email: emailController.text,
                  token: uid
              )
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 10),
                Text("Correo o contraseña incorrectos"),
              ],
            ),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 10),
              Text("Error de conexión"),
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
        title: Text(
          'Iniciar Sesión',
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
            children: [
              SizedBox(height: 30),
              // Logo o ícono
              Icon(
                Icons.supervised_user_circle,
                size: 100,
                color: Colors.blue[600],
              ),
              SizedBox(height: 20),
              // Texto de bienvenida
              Text(
                'Bienvenido',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              Text(
                'Inicia sesión para continuar',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 40),
              // Campo de email
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.email, color: Colors.blue[600]),
                    labelText: 'Correo electrónico',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Campo de contraseña
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: passwordController,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock, color: Colors.blue[600]),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.blue[600],
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                    labelText: 'Contraseña',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 30),
              // Botón de inicio de sesión
              Container(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: loginUser,
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
                      Icon(Icons.login, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Iniciar Sesión',
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
              SizedBox(height: 20),
              // Botón de registro
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "¿No tienes cuenta? ",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      "Regístrate",
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}