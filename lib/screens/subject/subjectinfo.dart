import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SubjectInfo extends StatefulWidget {
  final int subjectId; // 과목 ID 추가
  const SubjectInfo({Key? key, required this.subjectId}) : super(key: key);

  @override
  State<SubjectInfo> createState() => _SubjectInfoState();
}

class _SubjectInfoState extends State<SubjectInfo> {
  List<Subject> subjects = [];
  String proName = '';

  @override
  void initState() {
    super.initState();
    fetchSubjectById();
  }

  Future<void> fetchSubjectById() async {
    final response = await http.get(Uri.parse('http://203.247.42.144:443/subject/info?subject_id=${widget.subjectId}'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        subjects = data.map((item) => Subject.fromJson(item)).toList();
      });

      final subject = findSubjectById(widget.subjectId);
      if (subject != null) {
        fetchProfessorById(subject.proName);
      }
    } else {
      throw Exception('과목 정보를 불러오는 데 실패했습니다');
    }
  }

  Future<void> fetchProfessorById(int proId) async {
    final response = await http.get(Uri.parse('http://203.247.42.144:443/prof/info?pro_id=$proId'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final professor = data.firstWhere((item) => item['pro_id'] == proId, orElse: () => {});
      setState(() {
        proName = professor['name'] ?? '';
      });
    } else {
      throw Exception('교수 정보를 불러오는 데 실패했습니다');
    }
  }

  String getSubjectDivisionText(int division) {
    switch (division) {
      case 1:
        return '전기';
      case 2:
        return '전선';
      default:
        return '알 수 없음';
    }
  }

  Subject? findSubjectById(int subjectId) {
    return subjects.firstWhere(
          (subject) => subject.subjectId == subjectId,
      orElse: () => Subject(
        subjectName: '',
        subjectDivision: 0,
        subjectInfo: '',
        useLanguage: '',
        classGoal: '',
        subjectId: 0,
        subjectCredit: 0,
        openingGrade: 0,
        openingSemester: '',
        proName: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectId = widget.subjectId;

    final subject = findSubjectById(subjectId);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // 뒤로가기 버튼을 눌렀을 때 이전 화면으로 이동
          },
        ),
        title: Text(
          '과목 정보',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xffC1D3FF),
        centerTitle: true,
      ),
      body: subject != null
          ? SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(10),
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. 교과목 정보',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    alignment: Alignment.center,
                    width: double.infinity,
                    margin: EdgeInsets.all(5),
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '• 과목명\n',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    WidgetSpan(
                                      child: SizedBox(
                                        width: 10,
                                      ),
                                    ),
                                    TextSpan(
                                      text: subject.subjectName,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            SizedBox(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '• 학점\n',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    WidgetSpan(
                                      child: SizedBox(
                                        width: 10,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '${subject.subjectCredit}학점',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '• 담당교수\n',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    WidgetSpan(
                                      child: SizedBox(
                                        width: 10,
                                      ),
                                    ),
                                    TextSpan(
                                      text: proName,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            SizedBox(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '• 학수번호\n',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '\n', // 간격 추가
                                      style: TextStyle(
                                        fontSize: 2, // 간격 크기 조정
                                        color: Colors.transparent, // 투명한 색상으로 간격 생성
                                      ),
                                    ),
                                    WidgetSpan(
                                      child: SizedBox(
                                        width: 10,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '${subject.subjectId}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '• 이수구분\n',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    WidgetSpan(
                                      child: SizedBox(
                                        width: 10,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                      '${getSubjectDivisionText(subject.subjectDivision)}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            SizedBox(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '• 개설학년\n',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    WidgetSpan(
                                      child: SizedBox(
                                        width: 10,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                      '${subject.openingGrade}학년 ${subject.openingSemester}학기',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(10),
              padding: EdgeInsets.all(5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2. 교과목 개요',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.all(5),
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(
                      '${subject.subjectInfo}',
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(10),
              padding: EdgeInsets.all(5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '3. 사용하는 언어',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.all(5),
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(
                      '${subject.useLanguage}',
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(10),
              padding: EdgeInsets.all(5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '4. 학습목표',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.all(5),
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(
                      '${subject.classGoal}',
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          : Center(
        child: Text('과목을 찾을 수 없습니다.'),
      ),
    );
  }
}

class Subject {
  final String subjectName;
  final int subjectDivision;
  final String subjectInfo;
  final String useLanguage;
  final String classGoal;
  final int subjectId;
  final int subjectCredit;
  final int openingGrade;
  final String openingSemester;
  final int proName;

  Subject({
    required this.subjectName,
    required this.subjectDivision,
    required this.subjectInfo,
    required this.useLanguage,
    required this.classGoal,
    required this.subjectId,
    required this.subjectCredit,
    required this.openingGrade,
    required this.openingSemester,
    required this.proName,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      subjectName: json['subject_name'] ?? '',
      subjectDivision: json['subject_division'] ?? 0,
      subjectInfo: json['subject_info'] ?? '',
      useLanguage: json['use_language'] ?? '',
      classGoal: json['class_goal'] ?? '',
      subjectId: json['subject_id'] ?? 0,
      subjectCredit: json['credit'] ?? 0,
      openingGrade: json['opening_grade'] ?? 0,
      openingSemester: json['opening_semester'] ?? '',
      proName: json['pro_id'] ?? 0,
    );
  }
}
