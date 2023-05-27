import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:core';
import 'package:capstone/main.dart';
import 'package:capstone/screens/completion/completed_subject_select.dart';


//나의이수현황 페이지
void main() {
  runApp(MaterialApp(
    title: '나의 이수현황',
    home: completionStatusPage(),
  ));
}

class completionStatusPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CompletionStatusTitle(),
          StudentInfoWidget(
            studentId: '',
          ),
          MajorCreditWidget(),
          CompletedSubjectTitle(),
          //CompletedElectiveList(),
        ],
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

  get studentInfo => null;

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
class MajorCreditWidget extends StatelessWidget {
  const MajorCreditWidget({Key? key}) : super(key: key);

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
              '48',
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

//이수한 과목 ListView
class CompletedElectiveSubject extends StatefulWidget {
  @override
  _CompletedElectiveSubjectState createState() =>
      _CompletedElectiveSubjectState();
}

class _CompletedElectiveSubjectState extends State<CompletedElectiveSubject> {
  final List<String> _selectedSubjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    try {
      final dio = Dio();
      final response =
      await dio.get('http://3.39.88.187:3000/user/required/add');

      if (response.statusCode == 200) {
        var jsonData = response.data;
        setState(() {
          for (var item in jsonData) {
            _selectedSubjects.add(item["subject_name"]);
          }
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load subjects');
      }
    } catch (error) {
      throw Exception('Failed to fetch subjects: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('선택한 이수과목'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _selectedSubjects.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_selectedSubjects[index]),
          );
        },
      ),
    );
  }
}
