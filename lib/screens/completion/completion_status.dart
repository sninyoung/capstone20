import 'package:flutter/material.dart';
import 'package:capstone/drawer.dart';
import 'package:dio/dio.dart';
import 'dart:core';
import 'package:capstone/screens/completion/completed_subject_select.dart';


//나의이수현황 페이지
void main() {
  runApp(MaterialApp(
    title: '나의 이수현황',
    theme: ThemeData(
        primarySwatch: Colors.indigo,
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xff858585),
          ),
          titleSmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xff858585),
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          //버튼 글씨 폰트
          bodySmall: TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        )),
    home: CompletionStatusPage(),
  ));
}

class CompletionStatusPage extends StatefulWidget {
  @override
  State<CompletionStatusPage> createState() => _CompletionStatusPageState();
}

class _CompletionStatusPageState extends State<CompletionStatusPage> {
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
    body: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CompletionStatusTitle(),
          //StudentInfoWidget(studentId: '',),
          MajorCreditWidget(),
          CompletedSubjectTitle(),
          CompletedSubject(),
        ],
      ),
    ),
    );
  }
}

//나의이수현황 title
class CompletionStatusTitle extends StatelessWidget {
  const CompletionStatusTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xffffffff),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '나의 이수현황',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'completion status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//나의이수현황 학생정보 studentInfo
class StudentInfoWidget extends StatefulWidget {
  final String? studentId;
  StudentInfoWidget({required this.studentId});
  @override
  _StudentInfoWidgetState createState() => _StudentInfoWidgetState();
}

class _StudentInfoWidgetState extends State<StudentInfoWidget> {
  late Future<Map<String, dynamic>> futureStudentInfo;

  var studentInfo;

  Future<Map<String, dynamic>> fetchStudentInfo() async {
    var dio = Dio();
    var response = await dio.get('http://3.39.88.187:3000/user/info?',
        queryParameters: {"student_id": widget.studentId});
    if (response.statusCode == 200) {
      return response.data['users'][0] ?? {}; // If null, return an empty map
    } else {
      throw Exception('Failed to load student info');
    }
  }

  @override
  void initState() {
    super.initState();
    futureStudentInfo = fetchStudentInfo();
  }

  String getYearFromStudentId(String studentId) {
    if (studentId.length >= 8) {
      return "'${studentId.substring(2, 4)}학번";
    } else {
      return "학번 정보 없음";
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: fetchStudentInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        } else {
          String year = getYearFromStudentId(snapshot.data!['student_id']);
          if (studentInfo != null) {
            return SizedBox(
              width: double.infinity,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xffC1D3FF),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 20.0, top: 10.0, right: 20.0, bottom: 10.0),
                  child: Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          '${snapshot.data!['student_id']} 학번',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          ' | ',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(fontSize: 24),
                        ),
                        Text(
                          '${year} 학년',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          ' | ',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(fontSize: 24),
                        ),
                        Text(
                          '${snapshot.data!['major_type']}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          } else {
            return Text("No student data");
          }
        }
      },
    );
  }
}

//전공이수학점
Future<int> fetchSubjectCredits(List<String> courses) async {
  final dio = Dio();
  final token = await storage.read(key: 'token');
  int totalCredits = 0;

  for (String course in courses) {
    final response = await dio.get(
      'http://3.39.88.187:3000/subject/info',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
      queryParameters: {'course_name': course},
    );

    if (response.statusCode == 200) {
      totalCredits += (response.data['credit'] as num).toInt();
    } else {
      throw Exception('Failed to load subject credit');
    }
  }
  return totalCredits;
}


class MajorCreditWidget extends StatefulWidget {
  const MajorCreditWidget({Key? key}) : super(key: key);

  @override
  State<MajorCreditWidget> createState() => _MajorCreditWidgetState();
}

class _MajorCreditWidgetState extends State<MajorCreditWidget> {
  Map<String, dynamic> requiredCourses = {};
  int totalMajorCredits = 0;
  String get studentId => '';

  @override
  void initState() {
    super.initState();
    fetchRequiredCourses(studentId).then((data) {
      setState(() {
        requiredCourses = data;
        totalMajorCredits = fetchSubjectCredits(requiredCourses['courses']) as int;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xffF5F5F5),
          borderRadius: BorderRadius.circular(10)),
      height: 60,
      margin: EdgeInsets.fromLTRB(20, 25, 20, 40),
      child: Padding(
        padding: const EdgeInsets.only(
            left: 20.0, top: 10.0, right: 20.0, bottom: 10.0),
        child: Row(
          children: [
            Text(
              '전공학점 : ',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              '$totalMajorCredits',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(color: const Color(0xff2D0BB7)),
            ),
            Text(
              ' /',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              '66',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              '학점',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}


//전공이수과목 title
class CompletedSubjectTitle extends StatelessWidget {
  const CompletedSubjectTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
          color: Color(0xffffffff),
          border: Border(
              top: BorderSide(
                color: const Color(0xff858585),
                width: 0.8,
                style: BorderStyle.solid,
              ))),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    '전공 이수과목',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                    child: Text(
                      'completed subject',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CompletionSelect()));
              },
              style: ElevatedButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.bodySmall,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  backgroundColor: const Color(0xff341F87)),
              child: Text('이수과목 편집'),
            )
          ],
        ),
      ),
    );
  }
}


//이수한 과목 ListView로 보여줌
Future<Map<String, dynamic>> fetchRequiredCourses(String studentId) async {
  final dio = Dio();
  final token = await storage.read(key: 'token');

  final response = await dio.get(
    'http://3.39.88.187:3000/user/required',
    options: Options(
      headers: {'Authorization': 'Bearer $token'},
    ),
    queryParameters: {'student_id': studentId},
  );

  if (response.statusCode == 200) {
    return response.data;
  } else {
    throw Exception('Failed to load required courses');
  }
}

class CompletedSubject extends StatefulWidget {
  const CompletedSubject({Key? key}) : super(key: key);
  @override
  State<CompletedSubject> createState() => _CompletedSubjectState();
}

class _CompletedSubjectState extends State<CompletedSubject> {
  Map<String, dynamic> requiredCourses = {};

  List<Subject> compulsorySubjects = []; // 전공기초 과목 리스트
  List<Subject> electiveSubjects = []; // 전공선택 과목 리스트

  String studentId = ''; // 학생 ID
  List<String> courses = []; // 선택한 과목 리스트

  @override
  void initState() {
    super.initState();
    fetchRequiredCourses(studentId).then((data) {
      setState(() {
        requiredCourses = data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Completion Status'),
      ),
      body: ListView(
        children: [
          Text('Completed Compulsory Subjects'),
          ListView.builder(
            itemCount: requiredCourses['compulsorySubjects']?.length ?? 0,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(requiredCourses['compulsorySubjects'][index]),
              );
            },
          ),
          Text('Completed Elective Subjects'),
          ListView.builder(
            itemCount: requiredCourses['electiveSubjects']?.length ?? 0,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(requiredCourses['electiveSubjects'][index]),
              );
            },
          ),
        ],
      ),
    );
  }
}


