import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:core';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/drawer.dart';
import 'package:capstone/screens/completion/completed_subject_provider.dart';
import 'package:capstone/screens/completion/completed_subject_select.dart';
import 'package:capstone/screens/completion/subject_model.dart';

//나의 이수현황


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
  const CompletionStatusPage({Key? key}) : super(key: key);

  @override
  State<CompletionStatusPage> createState() => _CompletionStatusPageState();
}

class _CompletionStatusPageState extends State<CompletionStatusPage> {
  final storage = FlutterSecureStorage();
  late Future<List<Subject>> futureCompletedSubjects;

  @override
  void initState() {
    super.initState();
    futureCompletedSubjects = fetchCompletedSubjects();
  }

  //이수과목 정보 불러오기
  Future<List<Subject>> fetchCompletedSubjects() async {
    print('Fetching completed subjects...');

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

      print('Completed subjects retrieved: $subjects');

      return subjects;
    } else {
      throw Exception('Failed to load saved subjects');
    }
  }

  //빌드
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => TotalCredit(),
        child: Scaffold(
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
                      Consumer<TotalCredit>(
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => CompletedSubjectSelectPage(),),
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
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                        width: 0.8,
                        color: Color(0xff858585),
                        style: BorderStyle.solid),
                    color: Color(0xffffffff),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                      FutureBuilder<List<Subject>>(
                        future: futureCompletedSubjects,
                        // 이전에 정의한 fetchCompletedSubjects 메소드 사용
                        builder: (BuildContext context,
                            AsyncSnapshot<List<Subject>> snapshot) {
                          print('FutureBuilder snapshot: $snapshot');
                          if (snapshot.hasData) {
                            // 데이터가 있을 경우
                            List<Subject> subjects = snapshot.data!;

                            // subjectDivision이 2인 과목들을 전공선택과목으로 간주하고 리스트 생성
                            List<Subject> electiveSubjects = subjects
                                .where(
                                    (subject) => subject.subjectDivision == 2)
                                .toList();

                            return ListView.builder(
                              shrinkWrap: true,
                              // 부모 크기에 맞게 자신의 크기를 줄임
                              physics: NeverScrollableScrollPhysics(),
                              // ListView 스크롤 비활성화
                              itemCount: electiveSubjects.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title:
                                  Text(electiveSubjects[index].subjectName),
                                  subtitle: Text(
                                      '${electiveSubjects[index].credit}학점'),
                                );
                              },
                            );
                          } else if (snapshot.hasError) {
                            // 에러가 발생한 경우
                            return Text('${snapshot.error}');
                          }

                          // 기본적으로 로딩 Spinner를 표시
                          return CircularProgressIndicator();
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 20,
                ),

                //전공기초과목 ListView
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  margin: const EdgeInsets.only(left: 30.0, right: 30.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                        width: 0.8,
                        color: Color(0xff858585),
                        style: BorderStyle.solid),
                    color: Color(0xffffffff),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                      FutureBuilder<List<Subject>>(
                        future: fetchCompletedSubjects(),
                        // fetchCompletedSubjects 메소드 직접 호출
                        builder: (BuildContext context,
                            AsyncSnapshot<List<Subject>> snapshot) {
                          print('FutureBuilder snapshot: $snapshot');
                          if (snapshot.hasData) {
                            // 데이터가 있을 경우
                            List<Subject> subjects = snapshot.data!;

                            // subjectDivision이 2인 과목들을 전공선택과목으로 간주하고 리스트 생성
                            List<Subject> electiveSubjects = subjects
                                .where(
                                    (subject) => subject.subjectDivision == 2)
                                .toList();

                            return ListView.builder(
                              shrinkWrap: true,
                              // 부모 크기에 맞게 자신의 크기를 줄임
                              physics: NeverScrollableScrollPhysics(),
                              // ListView 스크롤 비활성화
                              itemCount: electiveSubjects.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title:
                                  Text(electiveSubjects[index].subjectName),
                                  subtitle: Text(
                                      '${electiveSubjects[index].credit}학점'),
                                );
                              },
                            );
                          } else if (snapshot.hasError) {
                            // 에러가 발생한 경우
                            return Text('${snapshot.error}');
                          }

                          // 기본적으로 로딩 Spinner를 표시
                          return CircularProgressIndicator();
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 50.0),
              ],
            ),
          ),
        ));
  }
}