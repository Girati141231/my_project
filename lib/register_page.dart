import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String selectedRole = "intern";
  bool isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> register() async {
    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse("http://localhost:5000/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": emailController.text,
        "password": passwordController.text,
        "role": selectedRole,
      }),
    );

    final data = jsonDecode(response.body);
    setState(() => isLoading = false);

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration successful!"), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["msg"]), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Register", style: TextStyle(color: Color(0xFFeae1f9), fontFamily: 'Candal')),
        backgroundColor: Color(0xFF110721),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFFeae1f9)),
      ),
      backgroundColor: Color(0xFF110721),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              Center(
                child: Image.asset(
                  'assets/image.png',
                  height: 310,
                ),
              ),
              SizedBox(height: 1),
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
              SizedBox(height: 10),
              Row(
                children: [
                  Text("Role: ", style: TextStyle(color: Color(0xFFeae1f9), fontFamily: 'Candal')),
                  Radio(
                    value: "company",
                    groupValue: selectedRole,
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value.toString();
                      });
                    },
                  ),
                  Text("Company", style: TextStyle(color: Color(0xFFeae1f9), fontFamily: 'Candal')),
                  Radio(
                    value: "intern",
                    groupValue: selectedRole,
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value.toString();
                      });
                    },
                  ),
                  Text("Intern", style: TextStyle(color: Color(0xFFeae1f9), fontFamily: 'Candal')),
                ],
              ),
              SizedBox(height: 20),
              isLoading
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFae88e6)),
                    )
                  : ElevatedButton(
                      onPressed: register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFd76b43),
                        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                      ),
                      child: Text("Register", style: TextStyle(color: Colors.white, fontFamily: 'Candal')),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}


