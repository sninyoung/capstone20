import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String _studentId = '';
  String _name = '';
  String _grade = '';
  String _email = '';
  String _introduction = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  void _fetchProfile() async {
    final storage = new FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    setState(() {
      _isLoading = true;
    });

    final response = await http.get(
      Uri.parse('https://example.com/api/profile'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final profile = json.decode(response.body);
      setState(() {
        _studentId = profile['student_id'];
        _name = profile['name'];
        _grade = profile['grade'];
        _email = profile['email'];
        _introduction = profile['introduction'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to load profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.blueGrey[600],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 20.0),
            Text(
              'Student ID:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            _isLoading
                ? CircularProgressIndicator()
                : Text(
                    _studentId,
                    style: TextStyle(fontSize: 20),
                  ),
            SizedBox(height: 20.0),
            Text(
              'Name:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            _isLoading
                ? CircularProgressIndicator()
                : Text(
                    _name,
                    style: TextStyle(fontSize: 20),
                  ),
            SizedBox(height: 20.0),
            Text(
              'Grade:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            _isLoading
                ? CircularProgressIndicator()
                : Text(
                    _grade,
                    style: TextStyle(fontSize: 20),
                  ),
            SizedBox(height: 20.0),
            Text(
              'Email:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            _isLoading
                ? CircularProgressIndicator()
                : Text(
                    _email,
                    style: TextStyle(fontSize: 20),
                  ),
            SizedBox(height: 20.0),
            Text(
              'Introduction:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            _isLoading
                ? CircularProgressIndicator()
                : Text(
                    _introduction,
                    style: TextStyle(fontSize: 20),
                  ),
          ],
        ),
      ),
    );
  }
}
