import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddSubjectPage extends StatefulWidget {
  @override
  _AddSubjectPageState createState() => _AddSubjectPageState();
}

class _AddSubjectPageState extends State<AddSubjectPage> {
  TextEditingController subjectIdController = TextEditingController();
  TextEditingController subjectNameController = TextEditingController();
  TextEditingController creditController = TextEditingController();
  TextEditingController classGoalController = TextEditingController();
  TextEditingController useLanguageController = TextEditingController();
  TextEditingController subjectInfoController = TextEditingController();

  String? _selectedOpeningGrade;
  String? _selectedOpeningSemester;
  int? _selectedSubjectDivision;
  int? _selectedTypeMd;
  int? _selectedTypeTr;

  List<String> openingGradeOptions = [
    '1학년',
    '2학년',
    '3학년',
    '4학년',
    '미정',
  ];

  List<String> openingSemesterOptions = [
    '1학기',
    '2학기',
    '미정',
  ];

  List<String> subjectDivisionOptions = [
    '전기',
    '전선',
  ];

  List<String> typeMdOptions = [
    '웹/앱 개발자',
    '백엔드 개발자',
    'DB전문가',
    '정보보안',
    '해당없음',
  ];

  List<String> typeTrOptions = [
    '풀스택 개발자',
    '정보보안전문가',
    'SW엔지니어',
    '해당없음',
  ];

  List<Map<String, dynamic>> professorNames = [];
  String? selectedProName;
  int? selectedProId;

  @override
  void initState() {
    super.initState();
    _getProfessorNames();
  }

  Future<void> _getProfessorNames() async {
    final url = Uri.parse('http://203.247.42.144:443/prof/');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;

      setState(() {
        professorNames = data
            .map((item) => {'name': item['name'], 'pro_id': item['pro_id']})
            .toList();
      });
    }
  }

  Future<void> addSubject() async {
    final url = Uri.parse('http://203.247.42.144:443/subject/add');
    Map<String, dynamic> body = {
      'subject_id': subjectIdController.text.isNotEmpty
          ? subjectIdController.text
          : '0',
      'pro_id': selectedProId ?? 0, // 변경: 선택된 교수의 pro_id 값을 가져옴
      'subject_name': subjectNameController.text.isNotEmpty
          ? subjectNameController.text
          : '',
      'credit': creditController.text.isNotEmpty ? creditController.text : '0',
      'subject_division': _selectedSubjectDivision.toString(),
      'class_goal': classGoalController.text.isNotEmpty
          ? classGoalController.text
          : '',
      'opening_semester': getOpeningSemesterValue(_selectedOpeningSemester!),
      'opening_grade': getOpeningGradeValue(_selectedOpeningGrade!),
      'type_md': _selectedTypeMd.toString(),
      'type_tr': _selectedTypeTr.toString(),
      'use_language': useLanguageController.text.isNotEmpty
          ? useLanguageController.text
          : '',
      'subject_info': subjectInfoController.text.isNotEmpty
          ? subjectInfoController.text
          : '',
    };

    final response = await http.post(url, body: jsonEncode(body), headers: {
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('성공적으로 추가되었습니다'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('추가 Error'),
        ),
      );
    }
  }

  int? getOpeningGradeValue(String grade) {
    if (grade == '1학년') {
      return 1;
    } else if (grade == '2학년') {
      return 2;
    } else if (grade == '3학년') {
      return 3;
    } else if (grade == '4학년') {
      return 4;
    } else {
      return 0;
    }
  }

  int getOpeningSemesterValue(String semester) {
    if (semester == '1학기') {
      return 1;
    } else if (semester == '2학기') {
      return 2;
    } else {
      return 0;
    }
  }

  int? getSubjectDivisionValue(String division) {
    if (division == '전기') {
      return 1;
    } else if (division == '전선') {
      return 2;
    } else {
      return null;
    }
  }

  int? getTypeMdValue(String typeMd) {
    if (typeMd == '웹/앱 개발자') {
      return 1;
    } else if (typeMd == '백엔드 개발자') {
      return 2;
    } else if (typeMd == 'DB전문가') {
      return 3;
    } else if (typeMd == '정보보안') {
      return 4;
    } else {
      return 0;
    }
  }

  int? getTypeTrValue(String typeTr) {
    if (typeTr == '풀스택 개발자') {
      return 1;
    } else if (typeTr == '정보보안전문가') {
      return 2;
    } else if (typeTr == 'SW엔지니어') {
      return 3;
    } else if (typeTr == '해당없음') {
      return 0;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '과목 추가',
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: subjectNameController,
              decoration: InputDecoration(
                labelText: '과목명',
              ),
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: selectedProName, // 변경: selectedProId 대신 selectedProName 사용
              decoration: InputDecoration(
                labelText: '담당 교수',
              ),
              items: professorNames.map((professor) {
                return DropdownMenuItem<String>(
                  value: professor['name'],
                  child: Text(professor['name']),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedProName = newValue;
                  selectedProId = professorNames
                      .firstWhere((professor) =>
                  professor['name'] == newValue)['pro_id']; // 변경: pro_id 값 가져옴
                });
              },
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: subjectIdController,
              decoration: InputDecoration(
                labelText: '학수번호 (필수기입)',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: creditController,
              decoration: InputDecoration(
                labelText: '학점 (숫자만 입력)',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: subjectInfoController,
              decoration: InputDecoration(
                labelText: '교과목 개요',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: useLanguageController,
              decoration: InputDecoration(
                labelText: '사용하는 언어',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: classGoalController,
              decoration: InputDecoration(
                labelText: '학습목표',
              ),
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: _selectedOpeningGrade,
              decoration: InputDecoration(
                labelText: '개설학년',
              ),
              items: openingGradeOptions.map((String grade) {
                return DropdownMenuItem<String>(
                  value: grade,
                  child: Text(grade),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedOpeningGrade = newValue!;
                });
              },
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: _selectedOpeningSemester,
              decoration: InputDecoration(
                labelText: '개설학기',
              ),
              items: openingSemesterOptions.map((String semester) {
                return DropdownMenuItem<String>(
                  value: semester,
                  child: Text(semester),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedOpeningSemester = newValue!;
                });
              },
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<int>(
              value: _selectedSubjectDivision,
              decoration: InputDecoration(
                labelText: '이수구분(전기, 전선)',
              ),
              items: subjectDivisionOptions.map((String division) {
                return DropdownMenuItem<int>(
                  value: getSubjectDivisionValue(division),
                  child: Text(division),
                );
              }).toList(),
              onChanged: (int? newValue) {
                setState(() {
                  _selectedSubjectDivision = newValue!;
                });
              },
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<int>(
              value: _selectedTypeMd,
              decoration: InputDecoration(
                labelText: 'MD',
              ),
              items: typeMdOptions.map((String typeMd) {
                return DropdownMenuItem<int>(
                  value: getTypeMdValue(typeMd),
                  child: Text(typeMd),
                );
              }).toList(),
              onChanged: (int? newValue) {
                setState(() {
                  _selectedTypeMd = newValue!;
                });
              },
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<int>(
              value: _selectedTypeTr,
              decoration: InputDecoration(
                labelText: 'TR',
              ),
              items: typeTrOptions.map((String typeTr) {
                return DropdownMenuItem<int>(
                  value: getTypeTrValue(typeTr),
                  child: Text(typeTr),
                );
              }).toList(),
              onChanged: (int? newValue) {
                setState(() {
                  _selectedTypeTr = newValue!;
                });
              },
            ),
            SizedBox(height: 32.0),
            SizedBox(
              width: double.infinity,
              height: 30.0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 150.0),
                child: ElevatedButton(
                  onPressed: () {
                    addSubject();
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      Color(0xffC1D3FF),
                    ),
                  ),
                  child: Text('추가'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
