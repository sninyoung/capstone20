import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/drawer.dart';
import 'package:capstone/screens/subject/subjectinfo.dart';
import 'package:capstone/screens/completion/completion_status.dart';


//이수과목 선택 페이지
class CompletionSelect extends StatefulWidget {
  CompletionSelect({Key? key}) : super(key: key);
  @override
  _CompletionSelectState createState() => _CompletionSelectState();
}

class _CompletionSelectState extends State<CompletionSelect> {
  final int subjectId;
  List<Subject> subjects = [];

  @override
  void initState() {
    super.initState();
    fetchSubjectById();
  }

  Future<void> fetchSubjectById() async {
    final response = await http
        .get(Uri.parse('http://3.39.88.187:3000/subject/${widget.subjectId}'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        subjects = data.map((item) => Subject.fromJson(item)).toList();
      });
    } else {
      throw Exception('Failed to load subjects');
    }
  }

  Subject? findSubjectByName(String name) {
    return subjects.firstWhere(
          (subject) => subject.subjectName == name,
      orElse: () => Subject(
        subjectName: '',
        subjectDivision: 0,
        subjectId: 0,
        subjectCredit: 0,
      ),
    );
  }

  List<Subject> _compulsorySelections = [];
  List<Subject> _electiveSelections = [];

  late String studentId; // 학번 저장용 변수
  List<String> courses = [];

  List<Subject> compulsorySubjects = [];
  List<Subject> electiveSubjects = [];


  // 과목정보 불러오기 및 분류
  Future<List<List<Map<String, dynamic>>>> fetchSubjects() async {
    final response = await http.get(Uri.parse('http://3.39.88.187:3000/subject/'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      List<Map<String, dynamic>> subjects = List<Map<String, dynamic>>.from(data);

      List<Map<String, dynamic>> compulsorySubjects = [];
      List<Map<String, dynamic>> electiveSubjects = [];

      for (var subject in subjects) {
        if (subject['subject_division'] == 1) {
          compulsorySubjects.add(subject);
        } else if (subject['subject_division'] == 2) {
          electiveSubjects.add(subject);
        }
      }
      return [compulsorySubjects, electiveSubjects];
    } else {
      throw Exception('Failed to fetch subjects');
    }
  }


  @override
  void initState() {
    super.initState();
    // 이곳에서 학번을 불러옴
    _getStudentId();
    fetchSubjects();
  }

  // 저장된 학번 불러오기
  _getStudentId() async {
    studentId = await storage.read(key: 'student_id') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<Subject>>>(
      future: fetchSubjectById(),
      builder: (BuildContext context, AsyncSnapshot<Map<String, List<Subject>>> snapshot) {
        if (snapshot.hasData) {
          List<Subject>  compulsorySubjects = snapshot.data!['compulsory']!;
          List<Subject>  electiveSubjects = snapshot.data!['elective']!;

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
            body: Container(
              color: const Color(0xff341F87),
              child: Column(
                children: [
                  MultiSelectChipField<Subject>(
                    items: compulsorySubjects
                        .map((subject) =>
                        MultiSelectItem<Subject>(subject, subject.subjectName))
                        .toList(),
                    title: Text("전공기초과목"),
                    selectedChipColor: Colors.blue,
                    onTap: (values) {
                      setState(() {
                        _compulsorySelections = values ?? [];
                      });
                    },
                  ),
                  MultiSelectChipField<Subject>(
                    items: electiveSubjects
                        .map((subject) =>
                        MultiSelectItem<Subject>(subject, subject.subjectName))
                        .toList(),
                    title: Text("전공선택과목"),
                    selectedChipColor: Colors.blue,
                    onTap: (values) {
                      setState(() {
                        _electiveSelections = values ?? [];
                      });
                    },
                  ),

                  ElevatedButton(
                    onPressed: () async {
                      // 선택한 과목들을 courses 변수에 할당
                      courses.clear(); // 기존의 선택한 과목들을 초기화
                      courses.addAll(_compulsorySelections.map((subject) => subject.subjectName).where((name) => name != null).cast<String>());
                      courses.addAll(_electiveSelections.map((subject) => subject.subjectName).where((name) => name != null).cast<String>());

                      bool success = await postRequiredCourses(studentId, courses);
                      if (success) {
                        // 성공적으로 이수과목 정보가 저장되었을 경우 알림
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('이수한 과목이 성공적으로 저장되었습니다!')),
                        );
                        // Navigator.push(context, MaterialPageRoute(builder: (context) => CompletionStatusPage()),
                        // );
                      } else {
                        // 요청이 실패했을 경우 에러 메시지 표시
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('이수한 과목 저장을 실패했습니다. ')),
                        );
                      }
                    },
                    child: Text('저장'),
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        return CircularProgressIndicator(); // 데이터를 기다리는 동안에는 CircularProgressIndicator를 표시
      },
    );
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



//과목
class Subject {
  final String subjectName;
  final int subjectDivision;
  final int subjectId;
  final int subjectCredit;

  Subject({
    required this.subjectName,
    required this.subjectDivision,
    required this.subjectId,
    required this.subjectCredit,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      subjectName: json['subject_name'] ?? '',
      subjectDivision: json['subject_division'] ?? 0,
      subjectId: json['subject_id'] ?? 0,
      subjectCredit: json['credit'] ?? 0,
    );
  }
}