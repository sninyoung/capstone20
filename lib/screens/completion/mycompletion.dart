import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:core';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/drawer.dart';
import 'package:capstone/screens/completion/completion_provider.dart';
import 'package:capstone/screens/completion/completed_subject_select.dart';
import 'package:capstone/screens/completion/subject_model.dart';

//나의 이수현황


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CompletionProvid(),
      child: MaterialApp(
        title: 'Capstone',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: CompletionStatusPage(),
      ),
    );
  }
}

//이수과목 모델
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

//나의이수현황 페이지
class CompletionStatusPage extends StatefulWidget {
  @override
  State<CompletionStatusPage> createState() => _CompletionStatusPageState();
}

class _CompletionStatusPageState extends State<CompletionStatusPage> {
  final storage = FlutterSecureStorage();
  late Future<List<Subject>> futureCompletedSubjects;

  @override
  void initState() {
    super.initState();
    Provider.of<CompletionProvid>(context, listen: false).loadSubjects();
  }

  //이수과목 정보 불러오기
  Future<List<Subject>> fetchCompletedSubjects() async {
    print('Fetching completed subjects...');

    final token = await storage.read(key: 'token'); // Storage에서 토큰 읽기
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/user/required'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token, // 헤더에 토큰 추가
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final List<Subject> subjects =
      data.map((item) => Subject.fromJson(item)).toList();

      print('Completed subjects retrieved: $subjects');

      return subjects;
    } else {
      throw Exception('Failed to load saved subjects');
    }
  }


  //빌드
  @override
  Widget build(BuildContext context) {
    CompletionProvid completedSubjectProvider =
    Provider.of<CompletionProvid>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            //나의 이수현황 title
            Container(
              alignment: Alignment.centerLeft,
              height: 120,
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Color(0xffffffff),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '나의 이수현황',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 26.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(
                    height: 8.0,
                  ),
                  const Text(
                    'completion status',
                    style: TextStyle(
                      color: Color(0xff858585),
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            //학생정보
            SizedBox(
              height: 60,
              child: Container(
                padding: EdgeInsets.fromLTRB(30, 16, 16, 16),
                decoration: BoxDecoration(
                  color: Color(0xffC1D3FF),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '20학번 | ',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '4학년 | ',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '단일전공',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40.0),

            //전공학점
            Container(
              height: 80,
              padding: EdgeInsets.fromLTRB(22, 16, 16, 16),
              margin: EdgeInsets.only(left: 30.0, right: 30.0),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Color(0xffF5F5F5),
                  boxShadow: [
                    BoxShadow(
                        color: Color(0xff858585),
                        offset: Offset(0, 5),
                        blurRadius: 5.0,
                        spreadRadius: 0.0)
                  ]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '총 전공학점 :  ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  //총전공학점
                  /*Consumer<TotalCredit>(
                    builder: (context, totalCredit, child) {
                      return Text(
                        '${Provider.of<TotalCredit>(context).totalCredit}',
                        style: TextStyle(
                          color: Color(0xff2D0BB7),
                          fontSize: 18.0,
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    },
                  ),*/
                  Text(
                    ' /66학점',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 40.0,
            ),

            //전공 이수과목 & 이수과목 편집 버튼
            Container(
              height: 80,
              padding: EdgeInsets.fromLTRB(30, 16, 16, 16),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                      color: Color(0xff858585),
                      width: 0.8,
                    )),
                color: Color(0xffffffff),
              ),
              child: Row(
                children: [
                  //전공 이수과목 title
                  Row(
                    //왼쪽 정렬
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '전공 이수과목',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16.0,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(
                              height: 5.0,
                            ),
                            const Text(
                              'completed subject',
                              style: TextStyle(
                                color: Color(0xff858585),
                                fontSize: 13.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 10.0,
                      )
                    ],
                  ),
                  //이수과목 편집 버튼
                  Expanded(
                    child: Align(
                      //오른쪽 끝 정렬
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        height: 40,
                        width: 120,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) {
                                return ChangeNotifierProvider<CompletionProvid>.value(
                                  value: Provider.of<CompletionProvid>(context, listen: false),
                                  child: CompletedSubjectSelectPage(),
                                );
                              }),
                            );
                          },
                          child: const Text('이수과목 편집'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xff341F87),
                            padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            minimumSize: Size(100, 35),
                            textStyle: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10.0,
                  ),
                ],
              ),
            ),
            SizedBox(height: 15.0),

            //과목명 보여주기 제발
            FutureBuilder(
              future: completedSubjectProvider.loadSubjects(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('과목을 불러오는 중 오류가 발생했습니다. ${snapshot.error}'),
                  );
                } else {
                  return SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '전공기초과목',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 20),
                                ),
                                ...completedSubjectProvider.completedCompulsory
                                    .map((subject) => Text(subject.subjectName)),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          Container(
                            padding: EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '전공선택과목',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 20),
                                ),
                                ...completedSubjectProvider.completedElective
                                    .map((subject) => Text(subject.subjectName)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),



          ],
        ),
      ),
    );
  }
}
