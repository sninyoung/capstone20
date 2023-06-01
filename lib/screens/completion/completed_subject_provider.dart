import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:core';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/screens/completion/completion_Class_subject.dart';
import 'package:capstone/screens/completion/mycompletion.dart';
import 'package:capstone/screens/completion/completed_subject_select.dart';


//이수과목과 전공학점 - Provider을 이용한 상태 관리


// 이수과목 모델
class CompletedSubjects {
  final int studentId;
  final int subjectId;
  final int proId;

  const CompletedSubjects({
    required this.studentId,
    required this.subjectId,
    required this.proId,
  });

  factory CompletedSubjects.fromJson(Map<String, dynamic> json) {
    return CompletedSubjects(
      studentId: json['student_id'],
      subjectId: json['subject_id'],
      proId: json['pro_id'],
    );
  }
}

//ChangeNotifier : 앱의 상태를 나타냄
class CompletedSubjectProvider with ChangeNotifier {
  final storage = new FlutterSecureStorage();
  List<Subject> _completedSubjects = [];
  List<Subject> get completedSubjects => _completedSubjects;

  //사용자 인증 jwt 토큰 방식
  Future<String> getStudentIdFromToken() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) {
      throw Exception('Token is not found');
    }

    final jwtToken =
    JwtDecoder.decode(token); // use jwt_decoder package to decode the token

    return jwtToken['student_id']; // ensure the token includes 'student_id'
  }

  //기존에 저장된 이수과목들을 불러오기
  Future<void> loadSubjects() async {
    String? data = await storage.read(key: 'completedSubjects');
    if (data != null) {
      var subjectData = jsonDecode(data) as List;
      _completedSubjects = subjectData.map((item) => Subject.fromJson(item)).toList();
      notifyListeners();
    }
  }


  void addSubject(Subject subject) {
    _completedSubjects.add(subject);
    notifyListeners();
  }

  void removeSubject(Subject subject) {
    _completedSubjects.remove(subject);
    notifyListeners();
  }

  Future<void> saveSubjects() async {
    await storage.write(key: 'completedSubjects', value: jsonEncode(_completedSubjects.map((subject) => subject.toJson()).toList()));
  }

  //이수과목 저장하기
  Future<void> saveCompletedSubjects() async {
    final url = Uri.parse('http://3.39.88.187:3000/user/required/add');
    final studentId = await getStudentIdFromToken();

    final data = _completedSubjects.map((completedSubject) => {
      'student_id': studentId,
      'subject_id': completedSubject.subjectId,
      'pro_id': completedSubject.proId,
    }).toList();

    final body = json.encode(data);
    print('Request body: $body'); // 로깅
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      print('서버 응답: ${response.body}'); // 서버의 응답을 출력합니다.
    } else {
      print('서버 응답: ${response.body}'); // 에러 발생 시 서버의 응답을 출력합니다.
    }
  }


  //이수과목 가져오기
  Future<void> fetchCompletedSubjects(int studentId) async {
    final Uri completedSubjectsUrl =
    Uri.parse('http://3.39.88.187:3000/user/required?student_id=$studentId');
    final http.Response completedSubjectsResponse =
    await http.get(completedSubjectsUrl);

    if (completedSubjectsResponse.statusCode == 200) {
      final List<dynamic> completedSubjectsData =
      json.decode(completedSubjectsResponse.body);

      List<Subject> completedSubjects = [];

      for (var item in completedSubjectsData) {
        final CompletedSubjects completedSubject =
        CompletedSubjects.fromJson(item);

        final Uri subjectUrl = Uri.parse(
            'http://3.39.88.187:3000/user/required/subject?subject_id=${completedSubject.subjectId}');

        var subjectResponse = await http.get(subjectUrl);
        if (subjectResponse.statusCode == 200) {
          final List<dynamic> subjectData =
          json.decode(subjectResponse.body);
          Subject subject = Subject.fromJson(subjectData[0]);
          completedSubjects.add(subject);
        } else {
          throw Exception(
              'Failed to load subject data: ${subjectResponse.statusCode}');
        }
      }

      _completedSubjects = completedSubjects;
      notifyListeners();
    } else {
      throw Exception(
          'Failed to load completed subjects: ${completedSubjectsResponse.statusCode}');
    }
  }
}


//총 전공학점
class TotalCredit extends ChangeNotifier {
  int _totalCredit = 0;

  int get totalCredit => _totalCredit;

  void setTotalCredit(int value) {
    _totalCredit = value;
    notifyListeners();  // 학점이 변경되었으므로 관련된 위젯들에게 알립니다.
  }
}



//추후에 23학번 이수유형별 전공학점 관리



