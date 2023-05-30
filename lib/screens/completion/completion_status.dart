import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:core';
import 'package:capstone/drawer.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/screens/completion/completed_subject_select.dart';


//나의 이수현황

//과목 모델
class Subject {
  final int subjectId;
  final String subjectName;
  final int credit;
  final int subjectDivision;
  final int? typeMd;
  final int? typeTr;

  Subject({
    required this.subjectId,
    required this.subjectName,
    required this.credit,
    required this.subjectDivision,
    this.typeMd,
    this.typeTr,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      subjectId: json['subject_id'],
      subjectName: json['subject_name'],
      credit: json['credit'],
      subjectDivision: json['subject_division'],
      typeMd: json['type_md'],
      typeTr: json['type_tr'],
    );
  }
}


//나의이수현황 페이지
class CompletionStatusPage extends StatefulWidget {
  const CompletionStatusPage({Key? key}) : super(key: key);
  @override
  State<CompletionStatusPage> createState() => _CompletionStatusPageState();
}

class _CompletionStatusPageState extends State<CompletionStatusPage> {
  final storage = new FlutterSecureStorage();


  //이수과목 정보 불러오기
  Future<List<Subject>> fetchCompletedSubjects() async {
    final token = await storage.read(key: 'token'); // Storage에서 토큰 읽기
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final response = await http.get(
      Uri.parse('http://3.39.88.187:3000/user/required'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token, // 헤더에 토큰 추가
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final List<Subject> subjects = data.map((item) => Subject.fromJson(item)).toList();
      return subjects;
    } else {
      throw Exception('Failed to load saved subjects');
    }
  }






  //빌드
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '이수과목',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xffC1D3FF),
        centerTitle: true,
        elevation: 0.0,
      ),
        drawer: MyDrawer(),
        body: Text('나의 이수현황'),
    );
  }
}




