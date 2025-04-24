import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'InternApplications.dart';
import 'login_page.dart';

class InternDashboard extends StatefulWidget {
  @override
  _InternDashboardState createState() => _InternDashboardState();
}

class _InternDashboardState extends State<InternDashboard> {
  List<Post> posts = [];
  List<Post> favoritePosts = [];
  String? userEmail;
  String searchQuery = "";
  bool showFavorites = false;

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
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return LoginPage(); // ไปที่หน้า LoginPage
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // การเคลื่อนที่จากขวาไปซ้าย
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        // Fade transition สำหรับการเปลี่ยนแสง
        var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(animation);

        // ผสมการเคลื่อนไหวทั้งสองอย่าง
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
    ),
    (route) => false, // ไม่สามารถย้อนกลับไปยังหน้าก่อนหน้าได้
  );
}



    // เพิ่มฟังก์ชัน fetchPosts
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
    } else {
      print("Failed to fetch posts.");
    }
  }


    // เพิ่มฟังก์ชัน getUserEmail
  Future<void> getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    if (token == null) return;

    final response = await http.get(
      Uri.parse("http://localhost:5000/api/users/me"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);
      setState(() {
        userEmail = decodedResponse['email'];
      });
    }
  }


  String formatTime(String time) {
    DateTime postDateTime = DateTime.parse(time);
    return timeago.format(postDateTime);
  }

  void toggleFavorite(Post post) {
    setState(() {
      if (favoritePosts.contains(post)) {
        favoritePosts.remove(post);
      } else {
        favoritePosts.add(post);
      }
    });
  }

void showApplicationDialog(Post post) {
  final resumeController = TextEditingController();
  final coverLetterController = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false, // ไม่ให้ปิดโดยการคลิกที่ด้านนอก
    builder: (context) => Dialog(
      backgroundColor: Color(0xFF110721), // --background
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300), // เวลาในการอนิเมชัน
        curve: Curves.easeInOut, // ความนุ่มนวล
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: child,
          );
        },
        child: Container(
          padding: EdgeInsets.all(16.0),
          constraints: BoxConstraints(maxWidth: 400), // ขนาดกรอบไม่เกิน 400px
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "สมัครงาน: ${post.position}",
                style: TextStyle(
                  color: Color(0xFFeae1f9), // --text
                  fontFamily: 'Mitr',
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: resumeController,
                maxLines: 3,
                style: TextStyle(color: Color(0xFFeae1f9), fontFamily: 'Mitr'),
                decoration: InputDecoration(
                  labelText: "เรซูเม่",
                  labelStyle: TextStyle(color: Color(0xFFeae1f9), fontFamily: 'Mitr'),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFae88e6)), // --primary
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFae88e6)), // --primary
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: coverLetterController,
                maxLines: 3,
                style: TextStyle(color: Color(0xFFeae1f9), fontFamily: 'Mitr'),
                decoration: InputDecoration(
                  labelText: "จดหมายสมัครงาน",
                  labelStyle: TextStyle(color: Color(0xFFeae1f9), fontFamily: 'Mitr'),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFae88e6)), // --primary
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFae88e6)), // --primary
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      "ยกเลิก",
                      style: TextStyle(
                        color: Color(0xFFd76b43), // --accent
                        fontFamily: 'Mitr',
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFae88e6), // --primary
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await submitApplication(
                        context,
                        post.id,
                        resumeController.text,
                        coverLetterController.text,
                      );
                    },
                    child: Text(
                      "ยืนยันการสมัคร",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Mitr',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}


    // เพิ่มฟังก์ชัน submitApplication
Future<void> submitApplication(BuildContext context, String postId, String resume, String coverLetter) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("token");

  final response = await http.post(
    Uri.parse("http://localhost:5000/api/applications"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "postId": postId,
      "resume": resume,
      "coverLetter": coverLetter,
    }),
  );

  if (response.statusCode == 201) {
    // ส่งใบสมัครสำเร็จ
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("ส่งใบสมัครเรียบร้อย"),
        backgroundColor: Colors.green, // สีเขียวสำหรับสำเร็จ
      ),
    );
  } else {
    // เกิดข้อผิดพลาดในการสมัคร
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("เกิดข้อผิดพลาดในการสมัคร"),
        backgroundColor: Colors.red, // สีแดงสำหรับข้อผิดพลาด
      ),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    List<Post> filteredPosts = (showFavorites ? favoritePosts : posts)
        .where((post) => post.position.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
  backgroundColor: Color(0xFF110721), // --background
  appBar: AppBar(
    backgroundColor: Color(0xFF110721),
    foregroundColor: Color(0xFFeae1f9), // --text
    title: Text(
      showFavorites ? "Favorite Posts" : "Intern Dashboard",
      style: TextStyle(fontFamily: 'Candal'), // ใช้ฟอนต์ Candal
    ),
    actions: [
      IconButton(
        icon: Icon(showFavorites ? Icons.list : Icons.favorite),
        onPressed: () {
          setState(() {
            showFavorites = !showFavorites;
          });
        },
        color: Color(0xFFae88e6), // --primary
      ),
      IconButton(
        icon: Icon(Icons.assignment),
  tooltip: "ดูสถานะใบสมัคร",
  onPressed: () {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return InternApplications();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // การเคลื่อนไหวจากขวาไปซ้าย
          const begin = Offset(1.0, 0.0); // เริ่มต้นจากขวา
          const end = Offset.zero; // จุดที่หยุด
          const curve = Curves.easeInOut; // ความนุ่มนวล

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          // การจาง
          var fadeTween = Tween(begin: 0.0, end: 1.0).animate(animation);

          // ผสมทั้งสองการเคลื่อนไหว
          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: fadeTween, // ใช้ fadeTween ที่ได้จาก animation
              child: child,
            ),
          );
        },
      ),
    );
  },
  color: Color(0xFFae88e6), // --primary
      ),
      IconButton(
        icon: Icon(Icons.logout),
        onPressed: logout,
        color: Color(0xFFd76b43), // --accent
      ),
    ],
  ),
  body: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      children: [
        TextField(
          style: TextStyle(color: Color(0xFFeae1f9), fontFamily: 'Mitr'), // --text
          decoration: InputDecoration(
            labelText: "ค้นหาตำแหน่งงาน",
            labelStyle: TextStyle(color: Color(0xFFae88e6), fontFamily: 'Mitr'), // --primary
            prefixIcon: Icon(Icons.search, color: Color(0xFFae88e6)), // --primary
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Color(0xFF1f1330), // custom: เข้มกว่าพื้นหลังนิด
          ),
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
        ),
        SizedBox(height: 10),
        Expanded(
          child: filteredPosts.isEmpty
              ? Center(child: Text("ไม่มีโพสต์", style: TextStyle(color: Color(0xFFae88e6), fontFamily: 'Mitr'))) // --primary
              : ListView.builder(
                  itemCount: filteredPosts.length,
                  itemBuilder: (context, index) {
                    final post = filteredPosts[index];
                    return Card(
                      color: Color(0xFF1f1330), // เข้ากับ --background
                      elevation: 3,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ExpansionTile(
                        collapsedIconColor: Color(0xFFae88e6), // --primary
                        iconColor: Color(0xFFae88e6), // --primary
                        title: Text(post.position,
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFeae1f9), fontFamily: 'Mitr')), // --text
                        subtitle: Text(
                          post.description.length > 50
                              ? post.description.substring(0, 50) + "..."
                              : post.description,
                          style: TextStyle(color: Color(0xFFae88e6), fontFamily: 'Mitr'), // --primary
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            favoritePosts.contains(post) ? Icons.favorite : Icons.favorite_border,
                            color: favoritePosts.contains(post)
                                ? Color(0xFFd76b43) // --accent
                                : Color(0xFFae88e6), // --primary
                          ),
                          onPressed: () => toggleFavorite(post),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post.description, style: TextStyle(color: Color(0xFFeae1f9), fontFamily: 'Mitr')), // --text
                                SizedBox(height: 4),
                                Wrap(
                                  children: post.skills.map((skill) => Chip(
                                    backgroundColor: Color(0xFF881d2a), // --secondary
                                    label: Text(skill, style: TextStyle(color: Colors.white, fontFamily: 'Mitr')),
                                  )).toList(),
                                ),
                                SizedBox(height: 8),
                                Text("โพสต์โดย: ${post.email}",
                                    style: TextStyle(fontSize: 12, color: Color(0xFFae88e6), fontFamily: 'Mitr')), // --primary
                                Text("โพสต์เมื่อ: ${formatTime(post.createdAt)}",
                                    style: TextStyle(fontSize: 12, color: Color(0xFFae88e6), fontFamily: 'Mitr')), // --primary
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () => showApplicationDialog(post),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFd76b43), // --accent
                                  ),
                                  child: Text("สมัครงาน", style: TextStyle(color: Colors.white, fontFamily: 'Mitr')),
                                ),
                              ],
                            ),
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

class Post {
  final String id;
  final String position;
  final String description;
  final List<String> skills;
  final String email;
  final String createdAt;

  Post({
    required this.id,
    required this.position,
    required this.description,
    required this.skills,
    required this.email,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'],
      position: json['position'],
      description: json['description'],
      skills: List<String>.from(json['skills']),
      email: json['companyId']?['email'] ?? 'ไม่ระบุ',
      createdAt: json['createdAt'],
    );
  }

  
}








