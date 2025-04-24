import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'login_page.dart';
import 'CompanyApplications.dart'; 


class CompanyDashboard extends StatefulWidget {
  @override
  _CompanyDashboardState createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  List<Post> posts = [];
  String? userEmail;

  @override
  void initState() {
    super.initState();
    fetchPosts();
    getUserEmail();
  }

  Future<void> logout() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => LoginPage()),
    (route) => false,
  );
}


  Future<void> fetchPosts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    if (token == null) return;

    final response = await http.get(
      Uri.parse("http://localhost:5000/api/posts"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List<dynamic> postsData = jsonDecode(response.body);
      setState(() {
        posts = postsData.map((e) => Post.fromJson(e)).toList();
      });
    }
  }

  Future<void> getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    if (token == null) return;

    final response = await http.get(
      Uri.parse("http://localhost:5000/api/users/me"), // เปลี่ยนเป็น endpoint ที่ดึงข้อมูลผู้ใช้
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);
      setState(() {
        userEmail = decodedResponse['email'];
        print("User email: $userEmail");
      });
    } else {
      print("Failed to load email: ${response.statusCode}");
    }
  }

  Future<void> deletePost(String postId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    if (token == null) return;

    final response = await http.delete(
      Uri.parse("http://localhost:5000/api/posts/$postId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      fetchPosts();
    }
  }

  void showAddPostDialog() {
  TextEditingController positionController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController skillsController = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false, // ป้องกันการปิดเมื่อคลิกข้างนอก
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent, // ทำให้พื้นหลังโปร่งใส
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: ModalRoute.of(context)!.animation!,
            curve: Curves.easeInOut,
          ),
          child: AlertDialog(
            backgroundColor: Color(0xFF110721), // --background
            title: Text(
              "เพิ่มโพสต์ใหม่",
              style: TextStyle(color: Color(0xFFeae1f9), fontFamily: 'Mitr'), // --text
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400), // จำกัดขนาดสูงสุด
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: positionController,
                      style: TextStyle(color: Color(0xFFeae1f9)), // --text
                      decoration: InputDecoration(
                        labelText: 'ตำแหน่งงาน',
                        labelStyle: TextStyle(color: Color(0xFFeae1f9)), // --text
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFae88e6)), // --primary
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFae88e6)), // --primary
                        ),
                      ),
                    ),
                    TextField(
                      controller: descriptionController,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      style: TextStyle(color: Color(0xFFeae1f9)), // --text
                      decoration: InputDecoration(
                        labelText: 'คำอธิบาย',
                        labelStyle: TextStyle(color: Color(0xFFeae1f9)), // --text
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFae88e6)), // --primary
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFae88e6)), // --primary
                        ),
                      ),
                    ),
                    TextField(
                      controller: skillsController,
                      style: TextStyle(color: Color(0xFFeae1f9)), // --text
                      decoration: InputDecoration(
                        labelText: 'ทักษะ',
                        labelStyle: TextStyle(color: Color(0xFFeae1f9)), // --text
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFae88e6)), // --primary
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFae88e6)), // --primary
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("ยกเลิก", style: TextStyle(color: Color(0xFFd76b43), fontFamily: 'Mitr')), // --accent
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFae88e6), // --primary
                ),
                onPressed: () async {
                  await addPost(positionController.text, descriptionController.text, skillsController.text);
                  Navigator.pop(context);
                },
                child: Text("เพิ่มโพสต์", style: TextStyle(color: Colors.white, fontFamily: 'Mitr')),
              ),
            ],
          ),
        ),
      );
    },
  );
}




  Future<void> addPost(String position, String description, String skills) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    if (token == null) return;

    final response = await http.post(
      Uri.parse("http://localhost:5000/api/posts"),
      headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
      body: jsonEncode({"position": position, "description": description, "skills": skills.split(", ")}),
    );

    if (response.statusCode == 201) {
      fetchPosts();
    }
  }

  void showEditPostDialog(Post post) {
  TextEditingController positionController = TextEditingController(text: post.position);
  TextEditingController descriptionController = TextEditingController(text: post.description);
  TextEditingController skillsController = TextEditingController(text: post.skills.join(", "));

  showDialog(
    context: context,
    barrierDismissible: false, // ป้องกันการปิดเมื่อคลิกข้างนอก
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent, // ทำให้พื้นหลังโปร่งใส
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: ModalRoute.of(context)!.animation!,
            curve: Curves.easeInOut,
          ),
          child: AlertDialog(
            backgroundColor: Color(0xFF110721), // --background
            title: Text(
              "แก้ไขโพสต์",
              style: TextStyle(color: Color(0xFFeae1f9), fontFamily: 'Mitr'), // --text
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400), // จำกัดขนาดสูงสุด
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: positionController,
                      style: TextStyle(color: Color(0xFFeae1f9)), // --text
                      decoration: InputDecoration(
                        labelText: 'ตำแหน่งงาน',
                        labelStyle: TextStyle(color: Color(0xFFeae1f9)), // --text
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFae88e6)), // --primary
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFae88e6)), // --primary
                        ),
                      ),
                    ),
                    TextField(
                      controller: descriptionController,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      style: TextStyle(color: Color(0xFFeae1f9)), // --text
                      decoration: InputDecoration(
                        labelText: 'คำอธิบาย',
                        labelStyle: TextStyle(color: Color(0xFFeae1f9)), // --text
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFae88e6)), // --primary
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFae88e6)), // --primary
                        ),
                      ),
                    ),
                    TextField(
                      controller: skillsController,
                      style: TextStyle(color: Color(0xFFeae1f9)), // --text
                      decoration: InputDecoration(
                        labelText: 'ทักษะ',
                        labelStyle: TextStyle(color: Color(0xFFeae1f9)), // --text
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFae88e6)), // --primary
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFae88e6)), // --primary
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("ยกเลิก", style: TextStyle(color: Color(0xFFd76b43), fontFamily: 'Mitr')), // --accent
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFae88e6), // --primary
                ),
                onPressed: () async {
                  await editPost(post.id, positionController.text, descriptionController.text, skillsController.text);
                  Navigator.pop(context);
                },
                child: Text("บันทึกการแก้ไข", style: TextStyle(color: Colors.white, fontFamily: 'Mitr')),
              ),
            ],
          ),
        ),
      );
    },
  );
}




  Future<void> editPost(String postId, String position, String description, String skills) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    if (token == null) return;

    final response = await http.put(
      Uri.parse("http://localhost:5000/api/posts/$postId"),
      headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
      body: jsonEncode({"position": position, "description": description, "skills": skills.split(", ")}),
    );

    if (response.statusCode == 200) {
      fetchPosts();
    }
  }

  String formatTime(String time) {
    DateTime postDateTime = DateTime.parse(time);
    return timeago.format(postDateTime);
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
  backgroundColor: Color(0xFF110721), // --background
  appBar: AppBar(
    title: Text("Company Dashboard", style: TextStyle(color: Color(0xFFeae1f9), fontFamily: 'Candal')), // --text
    backgroundColor: Color(0xFF110721), // --background
    elevation: 0,
    iconTheme: IconThemeData(color: Color(0xFFae88e6)), // --text
    actions: [
      IconButton(
  icon: Icon(Icons.apps, color: const Color(0xFFae88e6)), // --primary
  tooltip: "ดูใบสมัครทั้งหมด", // เพิ่ม tooltip ด้วย
  onPressed: () {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CompanyApplications(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0); // เริ่มจากขวา
          const end = Offset.zero; // ไปตำแหน่งปัจจุบัน
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(animation);

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
      ),
    );
  },
),

      IconButton(
        icon: Icon(Icons.logout, color: const Color(0xFFd76b43)), // --accent
        onPressed: logout,
      ),
    ],
  ),
  body: Padding(
    padding: const EdgeInsets.all(16.0),
    child: posts.isEmpty
        ? Center(child: Text("ไม่มีโพสต์", style: TextStyle(color: Color(0xFFae88e6), fontFamily: 'Mitr'))) // --primary
        : ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                color: Color(0xFF1f1330), // --background
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ExpansionTile(
                  title: Text(post.position, style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Mitr', color: Color(0xFFeae1f9))), // --text
                  subtitle: Text(post.description.length > 50 ? post.description.substring(0, 50) + "..." : post.description, style: TextStyle(fontFamily: 'Mitr', color: Color(0xFFae88e6))), // --text
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.description, style: TextStyle(fontFamily: 'Mitr', color: Color(0xFFeae1f9))), // --text
                          SizedBox(height: 4),
                          Wrap(
                            children: post.skills.map((skill) => Chip(
                              backgroundColor: Color(0xFF881d2a), // --secondary
                              label: Text(skill, style: TextStyle(color: Colors.white, fontFamily: 'Mitr')) // --text
                            )).toList(),
                          ),
                          SizedBox(height: 8),
                          Text("โพสต์โดย: ${post.email}",
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFFae88e6), // ไม่มีการไฮไลท์เมลของผู้โพสต์
                                fontFamily: 'Mitr',
                              )),
                          Text("โพสต์เมื่อ: ${formatTime(post.createdAt)}", style: TextStyle(fontSize: 12, color: Color(0xFFae88e6), fontFamily: 'Mitr')), // --primary
                        ],
                      ),
                    ),
                  ],
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Color(0xFFae88e6)), // --primary
                        onPressed: () => showEditPostDialog(post),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Color(0xFFd76b43)), // --accent
                        onPressed: () => deletePost(post.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
  ),
  floatingActionButton: FloatingActionButton(
    onPressed: showAddPostDialog,
    child: Icon(Icons.add),
    backgroundColor: Color(0xFFd76b43), // --accent
  ),
);







}

}

class Post {
  final String id;
  final String position;
  final String description;
  final List<String> skills;
  final String email;
  final String createdAt;

  Post({required this.id, required this.position, required this.description, required this.skills, required this.email, required this.createdAt});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'],
      position: json['position'],
      description: json['description'],
      skills: List<String>.from(json['skills']),
      email: json['companyId']['email'],
      createdAt: json['createdAt'],
    );
  }
}






























