import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:core';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/drawer.dart';
import 'package:capstone/screens/completion/mycompletion.dart';
import 'package:capstone/screens/completion/completed_subject_provider.dart';
import 'package:capstone/screens/completion/subject_model.dart';

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

// 이수과목 선택 페이지
class CompletedSubjectSelectPage extends StatefulWidget {
  final int? studentId;
  final int? subjectId;

  CompletedSubjectSelectPage(
      {this.subjectId, this.studentId});
  @override
  _CompletedSubjectSelectPageState createState() =>
      _CompletedSubjectSelectPageState();
}

class _CompletedSubjectSelectPageState
    extends State<CompletedSubjectSelectPage> {
  List<Subject> _subjects = [];
  List<MultiSelectItem<Subject>> _compulsoryItems = [];
  List<MultiSelectItem<Subject>> _electiveItems = [];
  List<Subject> _compulsorySelections = [];
  List<Subject> _electiveSelections = [];
  List<Subject> compulsorySubjects = [];
  List<Subject> electiveSubjects = [];


  @override
  void initState() {
    super.initState();
    //UI 렌더링이 완료된 후에 Provider의 데이터를 사용
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchSubjects();
    });
  }


  //사용자 인증 jwt 토큰 방식
  Future<String> getStudentIdFromToken() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) {
      throw Exception('Token is not found');
    }

    final jwtToken =
        JwtDecoder.decode(token); // use jwt_decoder package to decode the token

    return jwtToken['student_id']; // ensure the token includes 'student_id'
  }

  // 과목정보 불러오기
  Future<void> fetchSubjects() async {
    final response =
        await http.get(Uri.parse('http://3.39.88.187:3000/subject/'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      _subjects = data.map((item) => Subject.fromJson(item)).toList();

      // Update _compulsoryItems and _electiveItems here.
      _compulsoryItems = _subjects
          .where((subject) => subject.subjectDivision == 1)
          .map((subject) =>
              MultiSelectItem<Subject>(subject, subject.subjectName))
          .toList();

      _electiveItems = _subjects
          .where((subject) => subject.subjectDivision == 2)
          .map((subject) =>
              MultiSelectItem<Subject>(subject, subject.subjectName))
          .toList();

      setState(() {});
    } else {
      throw Exception('Failed to load subjects');
    }
  }

  //총 전공학점
  void calculateTotalMajorCredit() {
    int totalMajorCredit = 0;
    for (var subject in _electiveSelections) {
      totalMajorCredit += subject.credit;
    }

    // 이수과목 선택 페이지에서 계산한 학점을 설정
    Provider.of<TotalCredit>(context, listen: false)
        .setTotalCredit(totalMajorCredit);
  }

  // 빌드
  @override
  Widget build(BuildContext context) {
    final completedSubjectProvider = context.watch<CompletedSubject>();

    // 이후 completedSubjectProvider를 이용하여 UI를 업데이트하거나,
    // completedSubjectProvider.completedSubjects를 사용하여 이수과목의 상태를 감시

    return ChangeNotifierProvider(
      create: (context) => CompletedSubject(),
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
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                SizedBox(height: 20),
                //이수한 과목을 선택하세요 문구
                Container(
                  child: const Text(
                    '이수한 과목을 선택하세요!',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(height: 30),

                //전기 전선 MultiSelectBottomSheetField
                Column(
                  children: [
                    //전공기초과목 field
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xffF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xff858585),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          MultiSelectBottomSheetField(
                            initialChildSize: 0.4,
                            listType: MultiSelectListType.CHIP,
                            searchable: false,
                            buttonText: const Text(
                              "전공기초과목",
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            title: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: const Text(
                                "전공기초과목",
                                style: TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            items: _compulsoryItems
                                .map((subject) => MultiSelectItem<Subject>(
                                subject as Subject, subject.value.subjectName))
                                .toList(),
                            initialValue: _compulsorySelections,
                            onConfirm: (values) {
                              var completedSubjectProvider =
                                  context.read<CompletedSubject>();
                              _compulsorySelections = values.cast<Subject>();

                              // Update the completed subjects in the provider
                              completedSubjectProvider
                                  .updateCompulsory(_compulsorySelections);
                            },
                            chipDisplay: MultiSelectChipDisplay(
                              onTap: (value) {
                                setState(() {
                                  _compulsorySelections.remove(value);
                                });
                              },
                            ),
                          ),
                          _compulsorySelections == null ||
                                  _compulsorySelections.isEmpty
                              ? Container(
                                  padding: EdgeInsets.all(10),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "선택안함",
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),

                    //전공선택과목 field
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xffF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xff858585),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          MultiSelectBottomSheetField(
                            items: _electiveItems,
                            initialChildSize: 0.6,
                            listType: MultiSelectListType.CHIP,
                            searchable: true,
                            buttonText: Text(
                              "전공선택과목",
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            title: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "전공선택과목",
                                style: TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            initialValue: _electiveSelections,
                            onConfirm: (values) {
                              var completedSubjectProvider =
                                  context.read<CompletedSubject>();
                              _electiveSelections = values.cast<Subject>();

                              // Update the completed subjects in the provider
                              completedSubjectProvider
                                  .updateElective(_electiveSelections);
                            },
                            chipDisplay: MultiSelectChipDisplay(
                              onTap: (value) {
                                setState(() {
                                  _electiveSelections.remove(value);
                                });
                              },
                            ),
                            checkColor: Color(0xff8BB4F2),
                          ),
                          _electiveSelections == null ||
                                  _electiveSelections.isEmpty
                              ? Container(
                                  padding: EdgeInsets.all(10),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "선택안함",
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 80),

                //저장버튼
                ElevatedButton(
                  onPressed: () async {
                    if (_compulsorySelections.isEmpty &&
                        _electiveSelections.isEmpty) {
                      print("선택된 과목이 없습니다.");
                      return;
                    }

                    try {
                      final completedSubject =
                          Provider.of<CompletedSubject>(context, listen: false);

                      _compulsorySelections.forEach((subject) {
                        completedSubject.addSubject(subject);
                      });

                      _electiveSelections.forEach((subject) {
                        completedSubject.addSubject(subject);
                      });

                      await completedSubject.saveCompletedSubjects();

                      print('모든 선택한 과목이 저장되었습니다.');
                    } catch (e) {
                      print("과목 저장 중 오류 발생: $e");
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CompletionStatusPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xffffff),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    backgroundColor: const Color(0xff341F87),
                    minimumSize: Size(100, 50),
                  ),
                  child: Text('저장'),
                ),

                SizedBox(height: 50.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
