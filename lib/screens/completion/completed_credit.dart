import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:core';
import 'dart:async';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/screens/completion/completion_status.dart';
import 'package:capstone/screens/completion/completed_subject_select.dart';


//이수과목과 전공학점 상태 관리 페이지


// 과목 모델
class Subject {
  final int subjectId;
  final int proId;
  final String subjectName;
  final int credit;
  final int subjectDivision;
  final int? typeMd;
  final int? typeTr;

  Subject({
    required this.subjectId,
    required this.proId,
    required this.subjectName,
    required this.credit,
    required this.subjectDivision,
    this.typeMd,
    this.typeTr,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      subjectId: json['subject_id'],
      proId: json['pro_id'],
      subjectName: json['subject_name'],
      credit: json['credit'],
      subjectDivision: json['subject_division'],
      typeMd: json['type_md'],
      typeTr: json['type_tr'],
    );
  }

  @override
  String toString() {
    return 'Subject{subjectId: $subjectId, proId: $proId, subjectName: $subjectName, credit: $credit, subjectDivision: $subjectDivision, typeMd: $typeMd, typeTr: $typeTr}';
  }
}

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



//총 전공학점
class TotalCredit extends ChangeNotifier {
  int _totalCredit = 0;

  int get totalCredit => _totalCredit;

  void setTotalCredit(int value) {
    _totalCredit = value;
    notifyListeners();  // 학점이 변경되었으므로 관련된 위젯들에게 알립니다.
  }
}

//이수과목
class CompletedSubjectNotifier extends ChangeNotifier {
  List<Subject> _compulsorySubjects = [];
  List<Subject> _electiveSubjects = [];

  List<Subject> get compulsorySubjects => _compulsorySubjects;
  List<Subject> get electiveSubjects => _electiveSubjects;

  final _storage = FlutterSecureStorage();

  // Retrieve the saved subjects from secure storage upon initializing the notifier
  CompletedSubjectNotifier() {
    loadSubjects();
  }

  // ...

  Future<void> saveSubjects(List<Subject> compulsory, List<Subject> elective) async {
    // Convert subjects to json
    List<Map<String, dynamic>> compulsoryJson = compulsory
        .map((subject) => subject.toJson())
        .toList();
    List<Map<String, dynamic>> electiveJson = elective
        .map((subject) => subject.toJson())
        .toList();

    // Save to secure storage
    await _storage.write(key: 'compulsorySubjects', value: jsonEncode(compulsoryJson));
    await _storage.write(key: 'electiveSubjects', value: jsonEncode(electiveJson));

    // Update state and notify listeners
    _compulsorySubjects = compulsory;
    _electiveSubjects = elective;

    // Save subjects to the server
    await _saveCompletedSubjects([..._compulsorySubjects, ..._electiveSubjects]);

    notifyListeners();
  }

  Future<void> _saveCompletedSubjects(List<Subject> subjects) async {
    final url = Uri.parse('http://3.39.88.187:3000/user/required/add');
    final studentId = await getStudentIdFromToken();
    final data = subjects
        .map((subject) => {
      'student_id': studentId,
      'subject_id': subject.subjectId,
      'pro_id': subject.proId,
    })
        .toList();

    final body = json.encode(data);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit subjects. Server response: ${response.body}');
    }

    print('이수과목이 성공적으로 저장되었습니다.'); // 로깅
    print('서버 응답: ${response.body}'); // 서버의 응답을 출력합니다.
  }
}
