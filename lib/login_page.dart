import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'company_dashboard.dart';
import 'register_page.dart';
import 'intern_dashboard.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> login() async {
    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse("http://localhost:5000/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": emailController.text,
        "password": passwordController.text,
      }),
    );

    final data = jsonDecode(response.body);
    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", data["token"]);
      await prefs.setString("role", data["role"]);
      await prefs.setString("userId", data["userId"]);

      if (data["role"] == "company") {
        Navigator.pushReplacement(
          context,
          _createSlideRoute(CompanyDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          _createSlideRoute(InternDashboard()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["msg"]), backgroundColor: Colors.red),
      );
    }
  }

  // ฟังก์ชันสำหรับสร้าง SlideTransition พร้อม FadeTransition
  Route _createSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // เริ่มต้นจากขอบขวา
        const begin = Offset(1.0, 0.0);  // เริ่มต้นจากขอบขวาของหน้าจอ
        const end = Offset.zero;  // จบที่ตำแหน่งปกติ
        const curve = Curves.easeInOut;  // การเคลื่อนที่ที่นุ่มนวล

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        // การรวมการเคลื่อนไหวแบบ Slide และ Fade
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      transitionDuration: Duration(milliseconds: 500), // ระยะเวลา 500ms
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login", style: TextStyle(color: Color(0xFFeae1f9), fontFamily: 'Candal')),
        backgroundColor: Color(0xFF110721),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFFeae1f9)),
      ),
      backgroundColor: Color(0xFF110721),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/image.png',
                height: 310,
              ),
              SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: TextStyle(color: Color(0xFFae88e6), fontFamily: 'Candal'),
                  fillColor: Color(0xFF1f1330),
                  filled: true,
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: Color(0xFFeae1f9), fontFamily: 'Candal'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: TextStyle(color: Color(0xFFae88e6), fontFamily: 'Candal'),
                  fillColor: Color(0xFF1f1330),
                  filled: true,
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Color(0xFFae88e6),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isPasswordVisible,
                style: TextStyle(color: Color(0xFFeae1f9), fontFamily: 'Candal'),
              ),
              SizedBox(height: 20),
              isLoading
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFae88e6)),
                    )
                  : ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFd76b43),
                        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                      ),
                      child: Text("Login", style: TextStyle(color: Colors.white, fontFamily: 'Candal')),
                    ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => RegisterPage(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        var begin = Offset(1.0, 0.0);  // ขอบขวาของหน้าจอ
                        var end = Offset.zero;
                        var curve = Curves.easeInOut;
                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        var offsetAnimation = animation.drive(tween);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: offsetAnimation, child: child),
                        );
                      },
                      transitionDuration: Duration(milliseconds: 500),  // เวลาสำหรับทรานซิชัน
                    ),
                  );
                },
                child: Text(
                  "Don't have an account? Register here",
                  style: TextStyle(color: Color(0xFFae88e6), fontFamily: 'Candal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}








