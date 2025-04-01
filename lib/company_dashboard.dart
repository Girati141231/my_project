import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CompanyDashboard extends StatefulWidget {
  @override
  _CompanyDashboardState createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  List<Post> posts = [];
  TextEditingController positionController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController skillsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  // ฟังก์ชันในการดึงโพสต์จากเซิร์ฟเวอร์
  Future<void> fetchPosts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Token ไม่ถูกต้อง")));
      return;
    }

    final response = await http.get(
      Uri.parse("http://localhost:5000/api/posts"),
      headers: {
        "Authorization": "Bearer $token",  // เพิ่ม Bearer token
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> postsData = jsonDecode(response.body);
      setState(() {
        posts = postsData.map((e) => Post.fromJson(e)).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาดในการโหลดโพสต์")));
    }
  }

  // ฟังก์ชันในการเพิ่มโพสต์
  Future<void> addPost() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Token หรือ User ID ไม่ถูกต้อง")));
      return;
    }

    if (positionController.text.isEmpty || descriptionController.text.isEmpty || skillsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบ")));
      return;
    }

    final response = await http.post(
      Uri.parse("http://localhost:5000/api/posts"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",  // เพิ่ม Bearer token
      },
      body: jsonEncode({
        "position": positionController.text,
        "description": descriptionController.text,
        "skills": skillsController.text.split(", ").map((e) => e.trim()).toList(),
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("โพสต์ถูกเพิ่มเรียบร้อย")));
      fetchPosts();  // รีเฟรชโพสต์
    } else {
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: ${data['msg']}")));
    }
  }

  // ฟังก์ชันในการลบโพสต์
  Future<void> deletePost(String postId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Token ไม่ถูกต้อง")));
      return;
    }

    final response = await http.delete(
      Uri.parse("http://localhost:5000/api/posts/$postId"),
      headers: {
        "Authorization": "Bearer $token",  // เพิ่ม Bearer token
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("โพสต์ถูกลบเรียบร้อย")));
      fetchPosts();  // รีเฟรชโพสต์
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาดในการลบโพสต์")));
    }
  }

  // ฟังก์ชันในการแก้ไขโพสต์
  Future<void> editPost(String postId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Token ไม่ถูกต้อง")));
      return;
    }

    final response = await http.put(
      Uri.parse("http://localhost:5000/api/posts/$postId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",  // เพิ่ม Bearer token
      },
      body: jsonEncode({
        "position": positionController.text,
        "description": descriptionController.text,
        "skills": skillsController.text.split(", ").map((e) => e.trim()).toList(),
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("โพสต์ถูกแก้ไขเรียบร้อย")));
      fetchPosts();  // รีเฟรชโพสต์
    } else {
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: ${data['msg']}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Company Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: positionController,
              decoration: InputDecoration(labelText: 'ตำแหน่งงาน'),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'คำอธิบาย'),
            ),
            TextField(
              controller: skillsController,
              decoration: InputDecoration(labelText: 'ทักษะ'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: addPost,
              child: Text("เพิ่มโพสต์"),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return ListTile(
                    title: Text(post.position),
                    subtitle: Text(post.description),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => editPost(post.id), // แก้ไขโพสต์
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => deletePost(post.id), // ลบโพสต์
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Post model
class Post {
  final String id;
  final String position;
  final String description;
  final List<String> skills;

  Post({required this.id, required this.position, required this.description, required this.skills});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'],
      position: json['position'],
      description: json['description'],
      skills: List<String>.from(json['skills']),
    );
  }
}






















