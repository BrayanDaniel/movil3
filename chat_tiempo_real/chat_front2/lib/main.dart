// lib/main.dart

import 'package:chat_front2/vistas/loginscreen.dart';
import 'package:flutter/material.dart';



/*void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}*/

/*class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Auth',
      home: HomeScreen(),
    );
  }
}*/

void main() {
  //WidgetsFlutterBinding.ensureInitialized();
  //await Firebase.initializeApp();
  runApp(MiAplicacion());
}

class MiAplicacion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aplicación de Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      //home: PantallaLogin(),
      home: LoginScreen(),
    );
  }
}