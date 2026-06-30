import 'package:flutter/material.dart';
import 'screens/login/login_page.dart';
//in this only the,Scaffold,AppBar,Text,Button,Card,Icons
void main() {
  // execution starts from here
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // here the material app provides the Themes,Navigation,Routes,Material Design UI
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
