import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _passwordVisible = false;

  Future<void> registerUser() async {
    final String email = emailController.text;
    final String password = passwordController.text;

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text("Usuario registrado con éxito"),
              ],
            ),
            backgroundColor: Colors.green[400],
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 10),
                Text("Error al registrarse"),
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
          'Registro',
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
              Icon(
                Icons.person_add_rounded,
                size: 100,
                color: Colors.blue[600],
              ),
              SizedBox(height: 20),
              Text(
                'Crear nueva cuenta',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              Text(
                'Únete a nuestra comunidad',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 40),
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
              Container(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (passwordController.text.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.white),
                              SizedBox(width: 10),
                              Text("La contraseña debe tener al menos 6 caracteres"),
                            ],
                          ),
                          backgroundColor: Colors.red[400],
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      registerUser();
                    }
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
                      Icon(Icons.person_add, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Crear Cuenta',
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