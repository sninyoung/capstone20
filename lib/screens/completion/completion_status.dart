import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:core';
import 'package:capstone/drawer.dart';
import 'package:capstone/screens/completion/completed_subject_select.dart';

//나의 이수현황 페이지

//과목 모델
class Subject {
  final String subject_name;
  final int credit;
  final int subject_division;

  //과목 모델
  Subject({required this.subject_name,
    required this.credit,
    required this.subject_division});

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      subject_name: json['subject_name'],
      credit: json['credit'],
      subject_division: json['subject_division'],
    );
  }
}

//서버로부터 user의 이수과목 정보를 가져오기 위한 함수
Future<List<Subject>> fetchSubjects() async {
  final response =
  await http.get(Uri.parse('http://3.39.88.187:3000/user/required'));

  if (response.statusCode == 200) {
    List jsonResponse = json.decode(response.body);
    return jsonResponse.map((item) => Subject.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load subjects');
  }
}

//이수과목 리스트뷰  SubjectList(subjects: fetchSubjects()
class SubjectList extends StatelessWidget {
  final Future<List<Subject>> subjects;

  SubjectList({Key? key, required this.subjects}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Subject>>(
      future: subjects,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              String title =
              snapshot.data![index].subject_division == 'compulsory'
                  ? '[전기]' + snapshot.data![index].subject_name
                  : '[전선]' + snapshot.data![index].subject_name;
              return ListTile(
                title: Text(title),
              );
            },
          );
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        return CircularProgressIndicator();
      },
    );
  }
}

class CompletionStatusPage extends StatefulWidget {
  final String student_id;
  final String grade;
  final String major_type;

  const CompletionStatusPage({Key? key,
    required this.student_id,
    required this.grade,
    required this.major_type})
      : super(key: key);

  @override
  State<CompletionStatusPage> createState() => _CompletionStatusPageState();
}

class _CompletionStatusPageState extends State<CompletionStatusPage> {
  late List<Subject> _compulsorySelections;
  late List<Subject> _electiveSelections;

  @override
  void initState() {
    super.initState();
    _compulsorySelections = [];
    _electiveSelections = [];
    //futureUser = fetchUser();
  }

  Future<void> _fetchData() async {
    var response =
    await http.get(Uri.parse('http://3.39.88.187:3000/user/required'));
    var decodedData = jsonDecode(response.body);

    List<Subject> compulsorySelections = [];
    List<Subject> electiveSelections = [];

    for (var subject in decodedData['compulsory']) {
      compulsorySelections.add(Subject.fromJson(subject));
    }
    for (var subject in decodedData['elective']) {
      electiveSelections.add(Subject.fromJson(subject));
    }

    setState(() {
      _compulsorySelections = compulsorySelections;
      _electiveSelections = electiveSelections;
    });
  }

  int calculateTotalCredit(List<Subject> subjects) {
    int total = 0;
    for (var subject in subjects) {
      total += subject.credit;
    }
    return total;
  }


  /*//헤더에 토큰 추가 방법으로 특정 학생 정보 가져오기
  //${_student?.studentId} 부분은 현재 사용자의 ID -> 사용자가 로그인할 때 서버로부터 받아야 함
  //_student는 현재 로그인한 학생의 정보를 저장하는 변수
  Future<void> fetchCompletedSubjects() async {
    late Future<User> futureUser;
    final headers = { 'Authorization': 'Bearer ${_student?.token}'};

    final response = await http.get(
      Uri.parse('http://3.39.88.187:3000/user/required'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      _completedSubjects = data.map((item) => Subject.fromJson(item)).toList();

      setState(() {});
    } else {
      throw Exception('Failed to load completed subjects');
    }
  }*/

  /*//학생 정보 불러오기
  Future<User> fetchUser() async {
    final headers = { 'Authorization': 'Bearer ${_student?.token}'}; // 로그인 토큰
    final response = await http.get(
      Uri.parse('http://3.39.88.187:3000/user/info'),
      // user 정보를 받아오는 api endpoint
      headers: headers,
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user');
    }
  }*/

  /*//이수과목 정보 불러오기
  Future<void> fetchCompletedSubjects() async {
    var response = await http.get(Uri.parse(
        'http://3.39.88.187:3000/user/required?student_id=${_student
            ?.studentId}'));
    var decodedData = jsonDecode(response.body);

    List<Subject> compulsorySelections = [];
    List<Subject> electiveSelections = [];

    if (response.statusCode == 200) {
      for (var subject in decodedData['compulsory']) {
        compulsorySelections.add(Subject.fromJson(subject));
      }
      for (var subject in decodedData['elective']) {
        electiveSelections.add(Subject.fromJson(subject));
      }
      setState(() {
        _compulsorySelections = compulsorySelections;
        _electiveSelections = electiveSelections;
      });
    } else {
      throw Exception('Failed to load completed subjects');
    }
  }*/

//총 전공학점 계산
/*  int calculateTotalCredit(List<Subject> subjects) {
    int total = 0;
    for (var subject in subjects) {
      total += subject.credit;
    }
    return total;
  }*/

//빌드
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '나의 이수현황',
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
      body: Text('나의 이수현황')
    );
  }
}


/*
class User {
  final String student_id;
  final int grade;
  final String major_type;

  User({
    required this.student_id,
    required this.grade,
    required this.major_type,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      student_id: json['student_id'],
      grade: json['grade'],
      major_type: json['major_type'],
    );
  }
}
*/

