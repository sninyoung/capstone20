import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/screens/completion/completion_status.dart';

//이수과목 선택 페이지

void main() {
  runApp(MaterialApp(
    title: '나의 이수현황',
    home: CompletionSelect(),
  ));
}

//과목정보 불러오기
Future<List> fetchSubjects() async {
  var dio = Dio();
  final response = await dio.get('http://3.39.88.187:3000/subject/');

  if (response.statusCode == 200) {
    return response.data as List;
  } else {
    throw Exception('Failed to load subjects');
  }
}

//전공기초 전공선택 분류

List<Subject> compulsorySubjects = [];
List<Subject> electiveSubjects = [];

class Subject {
  final int subject_division;
  final String subject_name;

  Subject(this.subject_division, this.subject_name);
}

void divideSubjects(List subjects) {
  for (var subject in subjects) {
    if (subject['subject_division'] == 1) {
      compulsorySubjects
          .add(Subject(subject['subject_division'], subject['subject_name']));
    } else if (subject['subject_division'] == 2) {
      electiveSubjects
          .add(Subject(subject['subject_division'], subject['subject_name']));
    }
  }
}

// 이수과목 정보 저장
final storage = FlutterSecureStorage();

Future<bool> postRequiredCourses(String studentId, List<String> courses) async {
  final token = await storage.read(key: 'token');
  final response = await http.post(
    Uri.parse('http://3.39.88.187:3000/user/required/add'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(<String, dynamic>{
      'student_id': studentId,
      'courses': courses,
    }),
  );
  return response.statusCode == 200;
}


//
class CompletionSelect extends StatefulWidget {
  CompletionSelect({Key? key}) : super(key: key);

  @override
  _CompletionSelectState createState() => _CompletionSelectState();
}

class _CompletionSelectState extends State<CompletionSelect> {
  List<Subject> _compulsorySelections = [];
  List<Subject> _electiveSelections = [];

  String get studentId => '';
  List<String> courses = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MultiSelectChipField<Subject>(
          items: compulsorySubjects
              .map((subject) =>
                  MultiSelectItem<Subject>(subject, subject.subject_name))
              .toList(),
          title: Text("전공기초과목"),
          selectedChipColor: Colors.blue,
          onTap: (values) {
            setState(() {
              _compulsorySelections = values;
            });
          },
        ),
        MultiSelectChipField<Subject>(
          items: electiveSubjects
              .map((subject) =>
                  MultiSelectItem<Subject>(subject, subject.subject_name))
              .toList(),
          title: Text("전공선택과목"),
          selectedChipColor: Colors.blue,
          onTap: (values) {
            setState(() {
              _electiveSelections = values;
            });
          },
        ),
        ElevatedButton(
          onPressed: () async {
            // 선택한 과목들을 courses 변수에 할당
            courses.clear(); // 기존의 선택한 과목들을 초기화
            courses.addAll(_compulsorySelections.map((subject) => subject.subject_name));
            courses.addAll(_electiveSelections.map((subject) => subject.subject_name));

            bool success = await postRequiredCourses(studentId, courses);
            if (success) {
              // 성공적으로 이수과목 정보가 저장되었을 경우 알림
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Subjects successfully saved!')),
              );
              Navigator.push(context, MaterialPageRoute(builder: (context) => CompletionStatusPage(context)),
              );
            } else {
              // 요청이 실패했을 경우 에러 메시지 표시
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to save subjects.')),
              );
            }
          },
          child: Text('저장'),
        )
,

      ],
    );
  }
}

