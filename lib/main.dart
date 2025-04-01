import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      routes: {
        "/": (context) => LoginPage(),
        "/register": (context) => RegisterPage(),
        "/company_dashboard": (context) => Scaffold(body: Center(child: Text("Company Dashboard"))),
        "/intern_dashboard": (context) => Scaffold(body: Center(child: Text("Intern Dashboard"))),
      },
    );
  }
}















