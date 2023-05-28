import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/drawer.dart';
import 'package:capstone/screens/completion/completion_status.dart';


//이수과목 선택 페이지
void main() {
  runApp(MaterialApp(
    title: '이수과목 선택',
    home: CompletionSelect(),
  ));
}



//과목정보 불러오기
Future<Map<String, List<Subject>>> fetchAndDivideSubjects() async {
  var dio = Dio();
  final response = await dio.get('http://3.39.88.187:3000/subject/');

  if (response.statusCode == 200) {
    List subjects = response.data as List;

    List<Subject> compulsorySubjects = [];
    List<Subject> electiveSubjects = [];

    for (var subject in subjects) {
      if (subject['subject_division'] == 1) {
        compulsorySubjects.add(Subject(subject['subject_division'], subject['subject_name']));
      } else if (subject['subject_division'] == 2) {
        electiveSubjects.add(Subject(subject['subject_division'], subject['subject_name']));
      }
    }

    return {
      'compulsory': compulsorySubjects,
      'elective': electiveSubjects,
    };
  } else {
    throw Exception('Failed to load subjects');
  }
}


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




//이수과목 선택 페이지
class CompletionSelect extends StatefulWidget {
  CompletionSelect({Key? key}) : super(key: key);
  @override
  _CompletionSelectState createState() => _CompletionSelectState();
}

class _CompletionSelectState extends State<CompletionSelect> {
  List<Subject?> _compulsorySelections = [];
  List<Subject?> _electiveSelections = [];

  late String studentId; // 학번 저장용 변수
  List<String> courses = [];

  @override
  void initState() {
    super.initState();
    // 이곳에서 학번을 불러옴
    _getStudentId();
  }

  // 저장된 학번 불러오기
  _getStudentId() async {
    studentId = await storage.read(key: 'student_id') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<Subject>>>(
      future: fetchAndDivideSubjects(),
      builder: (BuildContext context, AsyncSnapshot<Map<String, List<Subject>>> snapshot) {
        if (snapshot.hasData) {
          List<Subject> compulsorySubjects = snapshot.data!['compulsory']!;
          List<Subject> electiveSubjects = snapshot.data!['elective']!;

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
                        MultiSelectItem<Subject>(subject, subject.subject_name))
                        .toList(),
                    title: Text("전공기초과목"),
                    selectedChipColor: Colors.blue,
                    onTap: (values) {
                      setState(() {
                        _compulsorySelections = values ?? []; //null 체크 추가
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
                        _electiveSelections = values ?? [];
                      });
                    },
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // 선택한 과목들을 courses 변수에 할당
                      courses.clear(); // 기존의 선택한 과목들을 초기화
                      courses.addAll(_compulsorySelections.map((subject) => subject?.subject_name).where((name) => name != null).cast<String>());
                      courses.addAll(_electiveSelections.map((subject) => subject?.subject_name).where((name) => name != null).cast<String>());

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

