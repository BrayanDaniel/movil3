import 'package:pruebafirebase/pages/home_page.dart';
import 'package:pruebafirebase/pages/login_register_page.dart';
import 'package:flutter/cupertino.dart';

import 'auth.dart';

class WidgetTree extends StatefulWidget{
  const WidgetTree({Key? key}):super(key: key);

  @override
  State<StatefulWidget> createState()=>_WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return StreamBuilder(
        stream: Auth().authStateChanges,
        builder: (context,snapshot){
          if(snapshot.hasData){
            return HomePage();
          }else{
            return const LoginPage();
          }
        }
    );
  }
}