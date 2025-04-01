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
  String selectedRole = "intern"; // ค่าเริ่มต้นเป็น Intern
  bool isLoading = false;
  bool _isPasswordVisible = false; // ตัวแปรในการจัดการการแสดงรหัส

  Future<void> register() async {
    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse("http://localhost:5000/register"), // URL ของ API
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
      Navigator.pop(context); // กลับไปหน้า Login
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["msg"]), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: "Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isPasswordVisible, // ซ่อนรหัสเมื่อ _isPasswordVisible เป็น false
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text("Role: "),
                Radio(
                  value: "company",
                  groupValue: selectedRole,
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value.toString();
                    });
                  },
                ),
                Text("Company"),
                Radio(
                  value: "intern",
                  groupValue: selectedRole,
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value.toString();
                    });
                  },
                ),
                Text("Intern"),
              ],
            ),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: register,
                    child: Text("Register"),
                  ),
          ],
        ),
      ),
    );
  }
}

