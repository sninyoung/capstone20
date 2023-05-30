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
      final List<Subject> subjects =
          data.map((item) => Subject.fromJson(item)).toList();
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
      body: s(
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
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '총 전공학점 : ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '48',
                    style: TextStyle(
                      color: Color(0xff2D0BB7),
                      fontSize: 16.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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
            SizedBox(height: 40.0,),

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
                  //전공 이수과목 title 왼쪽 정렬
                  Row(
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
                  //이수과목 편집 버튼 오른쪽 끝 정렬
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        height: 40,
                        width: 120,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (csontext) => SubjectSelect(
                                        subjectId: 1111111,
                                      )),
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

            //전공선택과목 ListView
            Container(
              padding: const EdgeInsets.all(20.0),
              margin: const EdgeInsets.only(left: 30.0, right: 30.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    width: 0.8,
                    color: Color(0xff858585),
                    style: BorderStyle.solid),
                color: Color(0xffffffff),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text(
                        '전공선택과목',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(
                        width: 8.0,
                      ),
                      Text(
                        ' 16과목',
                        style: TextStyle(
                          color: Color(0xff858585),
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 15.0,
                  ),
                  //전공선택과목 이수과목 리스트
                  Text('웹서버 프로그래밍'),
                ],
              ),
            ),
            SizedBox(height: 20,),

            //전공기초과목 ListView
            Container(
              padding: const EdgeInsets.all(20.0),
              margin: const EdgeInsets.only(left: 30.0, right: 30.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    width: 0.8,
                    color: Color(0xff858585),
                    style: BorderStyle.solid),
                color: Color(0xffffffff),
              ),
              child: Column(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text(
                        '전공기초과목',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(
                        height: 8.0,
                      ),
                      Text(
                        '※ 전공기초과목은 필수이수과목이고 전공기초학점은 교양학점으로 인정됨.',
                        style: TextStyle(
                          color: Color(0xff858585),
                          fontSize: 10.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 15.0,
                  ),
                  //전공선택과목 이수과목 리스트
                  Text('파이썬 프로그래밍'),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
