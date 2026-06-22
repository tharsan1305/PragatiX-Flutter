import 'package:flutter/material.dart';
import 'screens/login/login_page.dart';
//in this only the,Scaffold,AppBar,Text,Button,Card,Icons
void main() {
  // excution start from here
  runApp(MyApp());

}
class MyApp extends StatelessWidget{
  @override
  Widget build (BuildContext context){
    return MaterialApp(
      // here the matrial app provides the Themes,Navigation,Routes,Material Design UI
      debugShowCheckedModeBanner: false,
      home:LoginPage(),
    );
  }
}
