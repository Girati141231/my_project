import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';


class InternApplications extends StatefulWidget {
  @override
  _InternApplicationsState createState() => _InternApplicationsState();
}

class _InternApplicationsState extends State<InternApplications> {
  List<Application> applications = [];

  @override
  void initState() {
    super.initState();
    fetchApplications();
  }

  // ฟังก์ชันในการดึงข้อมูลใบสมัคร
  Future<void> fetchApplications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    print("TOKEN ที่ได้จาก SharedPreferences: $token"); // 👉 เพิ่มตรงนี้

    if (token == null) return;

    final response = await http.get(
      Uri.parse("http://localhost:5000/api/intern/applications"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        applications = data.map((e) => Application.fromJson(e)).toList();
      });
    } else {
      print("Failed to fetch applications. Response: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถดึงข้อมูลได้'), backgroundColor: Colors.red),
      );
    }
  }

  String formatTime(String time) {
    try {
      DateTime dateTime = DateTime.parse(time);
      return timeago.format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: Color(0xFF110721), // --background
  appBar: AppBar(
    backgroundColor: Color(0xFF110721), // --background
    foregroundColor: Color(0xFFeae1f9), // --text
    title: Text(
      "Job Application Status",
      style: TextStyle(
        fontFamily: 'Candal', // ฟอนต์ Candal
      ),
    ),
  ),
  body: Padding(
    padding: const EdgeInsets.all(16.0),
    child: applications.isEmpty
        ? Center(
            child: Text(
              "ไม่มีใบสมัครที่ส่งไป",
              style: TextStyle(
                color: Color(0xFFae88e6), // --primary
                fontFamily: 'Mitr',
              ),
            ),
          )
        : ListView.builder(
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];
              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 8),
                color: Color(0xFF1f1330), // ดาร์กเข้ากับพื้นหลัง
                child: ListTile(
                  contentPadding: EdgeInsets.all(12),
                  title: Text(
                    "จากโพสต์: ${app.position}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFeae1f9), // --text
                      fontFamily: 'Mitr',
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(
                        "สถานะ: ${app.status}",
                        style: TextStyle(
                          color: _getStatusColor(app.status), // สีเปลี่ยนตามสถานะ
                          fontFamily: 'Mitr',
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "วันที่สมัคร: ${formatTime(app.createdAt)}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFae88e6), // --primary
                          fontFamily: 'Mitr',
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward, color: Color(0xFFae88e6)), // --primary
                  onTap: () => navigateToDetails(context, app),
                ),
              );
            },
          ),
  ),
);


  }

  // ฟังก์ชันในการแปลงสถานะเป็นสี
  Color _getStatusColor(String status) {
    switch (status) {
      case "pending":
        return Colors.orange;
      case "accepted":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return const Color(0xFFae88e6);  // ถ้าสถานะไม่ตรงตามที่กำหนด
    }
  }

  // ฟังก์ชันในการไปยังหน้ารายละเอียดใบสมัคร (เพิ่มทรานซิชัน)
// ฟังก์ชันในการไปยังหน้ารายละเอียดใบสมัคร (เพิ่มทรานซิชันที่สวยงามขึ้น)
void navigateToDetails(BuildContext context, Application app) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return ApplicationDetailsPage(app: app);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // ตั้งค่าสำหรับการเลื่อน (Slide)
        const begin = Offset(1.0, 0.0); // เริ่มต้นจากขวา
        const end = Offset.zero; // จุดที่หยุด
        const curve = Curves.easeInOut; // ความนุ่มนวลในการเคลื่อนไหว

        // ใช้ Tween เพื่อทำให้การเคลื่อนไหวมีกลิ่นอายที่นุ่มนวล
        var slideTween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var slideAnimation = animation.drive(slideTween);

        // เพิ่มการขยายตัว (Scale)
        var scaleTween = Tween(begin: 0.95, end: 1.0); // ขยายจาก 95% ไป 100%
        var scaleAnimation = animation.drive(scaleTween);

        // เพิ่มการจาง (Fade)
        var fadeTween = Tween(begin: 0.0, end: 1.0); // ทำให้เริ่มต้นจากความโปร่งใสแล้วค่อยๆ ปรากฏ
        var fadeAnimation = animation.drive(fadeTween);

        // รวมทั้งสามทรานซิชัน (เลื่อน, ขยาย, จาง)
        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          ),
        );
      },
    ),
  );
}


}

class ApplicationDetailsPage extends StatelessWidget {
  final Application app;

  ApplicationDetailsPage({required this.app});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: Color(0xFF110721), // --background
  appBar: AppBar(
    backgroundColor: Color(0xFF110721), // --background
    foregroundColor: Color(0xFFeae1f9), // --text
    title: Text(
      "Job Application Details",
      style: TextStyle(
        fontFamily: 'Candal', // ฟอนต์ Candal สำหรับ heading
      ),
    ),
  ),
  body: Padding(
    padding: const EdgeInsets.all(16.0),
    child: ListView(
      children: [
        Text(
          "จากโพสต์: ${app.position}",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFeae1f9), // --text
            fontFamily: 'Mitr',
          ),
        ),
        SizedBox(height: 16),
        Text(
          "สถานะ: ${app.status}",
          style: TextStyle(
            fontSize: 16,
            color: _getStatusColor(app.status), // ตามสถานะ
            fontFamily: 'Mitr',
          ),
        ),
        SizedBox(height: 16),
        Text(
  "เรซูเม่:",
  style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: Color(0xFFae88e6), // --primary
    fontFamily: 'Mitr',
  ),
),
SizedBox(height: 4),
Container(
  padding: EdgeInsets.all(8),
  decoration: BoxDecoration(
    color: Color(0xFF1f1330), // สีพื้นหลังเข้ากับธีม --background
    borderRadius: BorderRadius.circular(8),
  ),
  child: InkWell(
    onTap: () {
      // เปิดลิงก์เรซูเม่
      _launchURL(app.resume);
    },
    child: Text(
      app.resume, // แสดง URL ของเรซูเม่
      style: TextStyle(
        fontSize: 14,
        color: Colors.blue, // สีของลิงก์
      ),
    ),
  ),
),
SizedBox(height: 16),



        Text(
          "จดหมายสมัครงาน:",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFFae88e6), // --primary
            fontFamily: 'Mitr',
          ),
        ),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFF1f1330), // เข้ากับธีม --background
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            app.coverLetter,
            style: TextStyle(color: Color(0xFFeae1f9), fontFamily: 'Mitr'), // --text
          ),
        ),
        SizedBox(height: 16),
        Text(
          "วันที่สมัคร: ${timeago.format(DateTime.parse(app.createdAt))}",
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFFae88e6), // --primary
            fontFamily: 'Mitr',
          ),
        ),
      ],
    ),
  ),
);



  }

  // ฟังก์ชันในการแปลงสถานะเป็นสี
  Color _getStatusColor(String status) {
    switch (status) {
      case "pending":
        return Colors.orange;
      case "accepted":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.black;  // ถ้าสถานะไม่ตรงตามที่กำหนด
    }
  }

  void _launchURL(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw 'ไม่สามารถเปิด URL นี้ได้: $url';
  }
}
}

class Application {
  final String id;
  final String position;
  final String status;
  final String resume;
  final String coverLetter;
  final String createdAt;

  Application({
    required this.id,
    required this.position,
    required this.status,
    required this.resume,
    required this.coverLetter,
    required this.createdAt,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['_id'] ?? '',
      position: json['postId']['position'] ?? '',
      status: json['status'] ?? '',
      resume: json['resume'] ?? '',
      coverLetter: json['coverLetter'] ?? '',
      createdAt: json['appliedAt'] ?? '',
    );
  }
}














