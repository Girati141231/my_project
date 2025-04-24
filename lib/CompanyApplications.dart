import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;

class CompanyApplications extends StatefulWidget {
  @override
  _CompanyApplicationsState createState() => _CompanyApplicationsState();
}

class _CompanyApplicationsState extends State<CompanyApplications> {
  List<Application> applications = [];

  @override
  void initState() {
    super.initState();
    fetchApplications();
  }

  // ดึงข้อมูลใบสมัครจาก API
  Future<void> fetchApplications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token ไม่พบ!'), backgroundColor: Colors.red),
      );
      return;
    }

    final response = await http.get(
      Uri.parse("http://localhost:5000/api/company/applications"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        applications = data.map((e) => Application.fromJson(e)).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถดึงข้อมูลใบสมัครได้'), backgroundColor: Colors.red),
      );
    }
  }

  // อัปเดตสถานะใบสมัคร
  Future<void> updateStatus(String applicationId, String status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token ไม่พบ!'), backgroundColor: Colors.red),
      );
      return;
    }

    final response = await http.put(
      Uri.parse("http://localhost:5000/api/company/applications/$applicationId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"status": status}),
    );

    if (response.statusCode == 200) {
      fetchApplications();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถอัพเดตสถานะใบสมัครได้'), backgroundColor: Colors.red),
      );
    }
  }

  // เปิด URL ด้วย url_launcher
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'ไม่สามารถเปิดลิงก์ได้: $url';
    }
  }

  // เปลี่ยนสีสถานะตามเงื่อนไข
  Color _getStatusColor(String status) {
    switch (status) {
      case "pending":
        return Colors.orange;
      case "accepted":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return const Color(0xFFae88e6);
    }
  }

  void navigateToDetails(BuildContext context, Application app) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          ApplicationDetailsPage(app: app),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
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
          style: TextStyle(fontFamily: 'Candal'),
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
                    color: Color(0xFF1f1330), // --background (เข้ม)
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
                              color: _getStatusColor(app.status),
                              fontFamily: 'Mitr',
                            ),
                          ),
                          SizedBox(height: 2),
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ปุ่ม Dropdown ที่จัดแต่งให้สวยงาม
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(0xFF1f1330),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Color(0xFFae88e6)),
                            ),
                            child: DropdownButton<String>(
                              value: app.status,
                              icon: Icon(Icons.arrow_drop_down, color: Color(0xFFae88e6)),
                              dropdownColor: Color(0xFF1f1330),
                              underline: SizedBox(),
                              style: TextStyle(color: Color(0xFFeae1f9), fontFamily: 'Mitr'),
                              items: <String>['pending', 'accepted', 'rejected'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: TextStyle(color: Color(0xFFeae1f9), fontFamily: 'Mitr'),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newStatus) {
                                if (newStatus != null) {
                                  updateStatus(app.id, newStatus);
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Color(0xFFae88e6)), // --primary
                        ],
                      ),
                      onTap: () => navigateToDetails(context, app),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class ApplicationDetailsPage extends StatelessWidget {
  final Application app;

  ApplicationDetailsPage({required this.app});

  Color _getStatusColor(String status) {
    switch (status) {
      case "pending":
        return Colors.orange;
      case "accepted":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'ไม่สามารถเปิดลิงก์ได้: $url';
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
          "Job Application Details",
          style: TextStyle(fontFamily: 'Candal'),
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
                color: _getStatusColor(app.status),
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
                color: Color(0xFF1f1330),
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: () {
                  _launchURL(app.resume);
                },
                child: Text(
                  app.resume,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
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
                color: Color(0xFFae88e6),
                fontFamily: 'Mitr',
              ),
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF1f1330),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                app.coverLetter,
                style: TextStyle(
                  color: Color(0xFFeae1f9),
                  fontFamily: 'Mitr',
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              "วันที่สมัคร: ${timeago.format(DateTime.parse(app.createdAt))}",
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFae88e6),
                fontFamily: 'Mitr',
              ),
            ),
          ],
        ),
      ),
    );
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






















