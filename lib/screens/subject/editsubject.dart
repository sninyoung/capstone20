import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditSubjectPage extends StatefulWidget {
  final int subjectId;

  EditSubjectPage({required this.subjectId});

  @override
  _EditSubjectPageState createState() => _EditSubjectPageState();
}

class _EditSubjectPageState extends State<EditSubjectPage> {
  TextEditingController _subjectNameController = TextEditingController();
  TextEditingController _creditController = TextEditingController();
  TextEditingController _subjectDivisionController = TextEditingController();
  TextEditingController _classGoalController = TextEditingController();
  TextEditingController _openingSemesterController = TextEditingController();
  TextEditingController _useLanguageController = TextEditingController();
  TextEditingController _subjectInfoController = TextEditingController();

  String _subjectId = '';
  int _proId = 0; // Changed the type to int
  String _proName = ''; // Added a new variable to store professor's name
  int _selectedSubjectDivision = 1; // 기본값으로 '전기' 선택
  int _selectedTypeMd = 0; // 기본값으로 '해당없음' 선택
  int _selectedTypeTr = 0; // 기본값으로 '해당없음' 선택
  int _selectedOpeningGrade = 1; // 기본값으로 1 선택
  int _selectedOpeningSemester = 1; // 기본값으로 1 선택

  Future<void> fetchSubjectInfo() async {
    final url = Uri.parse(
      'http://203.247.42.144:443/subject/info?subject_id=${widget.subjectId}',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final subjectInfoList = jsonDecode(response.body) as List<dynamic>;

      if (subjectInfoList.isNotEmpty) {
        final subjectInfo = subjectInfoList[0];

        setState(() {
          _subjectId = subjectInfo['subject_id'].toString();
          _proId = subjectInfo['pro_id'];
          _subjectNameController.text = subjectInfo['subject_name'].toString();
          _creditController.text = subjectInfo['credit'].toString();
          _selectedSubjectDivision = subjectInfo['subject_division'] == 2 ? 2 : 1;
          _classGoalController.text = subjectInfo['class_goal'].toString();
          _useLanguageController.text = subjectInfo['use_language'].toString();
          _subjectInfoController.text = subjectInfo['subject_info'].toString();

          int openingGrade = subjectInfo['opening_grade'];
          if (openingGrade != null && openingGrade >= 1 && openingGrade <= 4) {
            _selectedOpeningGrade = openingGrade;
          } else {
            _selectedOpeningGrade = 1; // 기본값으로 1 선택
          }

          String openingSemester = subjectInfo['opening_semester'].toString();
          if (openingSemester != null && (openingSemester == '1' || openingSemester == '2')) {
            _selectedOpeningSemester = int.parse(openingSemester);
          } else {
            _selectedOpeningSemester = 1; // 기본값으로 1 선택
          }

          int typeMd = subjectInfo['type_md'];
          if (typeMd != null && typeMd >= 1 && typeMd <= 4) {
            _selectedTypeMd = typeMd;
          } else {
            _selectedTypeMd = 0; // 기본값으로 0 선택
          }

          int typeTr = subjectInfo['type_tr'];
          if (typeTr != null && typeTr >= 1 && typeTr <= 4) {
            _selectedTypeTr = typeTr;
          } else {
            _selectedTypeTr = 0; // 기본값으로 0 선택
          }
        });

        await fetchProfessorName(); // Fetch professor's name after obtaining pro_id
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('과목 정보 조회에 실패했습니다'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('과목 정보를 불러오는 데 실패했습니다'),
        ),
      );
    }
  }

  Future<void> fetchProfessorName() async {
    final url = Uri.parse(
      'http://203.247.42.144:443/prof/info?pro_id=$_proId',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final professorInfoList = jsonDecode(response.body) as List<dynamic>;

      if (professorInfoList.isNotEmpty) {
        final professorInfo = professorInfoList[0];
        setState(() {
          _proName = professorInfo['name'].toString();
        });
      }
    }
  }

  Future<void> modifySubjectInfo() async {
    final url = Uri.parse('http://203.247.42.144:443/subject/modify');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'subject_id': _subjectId,
        'pro_id': _proId,
        'subject_name': _subjectNameController.text.isNotEmpty ? _subjectNameController.text : '',
        'credit': _creditController.text.isNotEmpty ? _creditController.text : '0',
        'subject_division': _selectedSubjectDivision.toString(),
        'class_goal': _classGoalController.text.isNotEmpty ? _classGoalController.text : '',
        'opening_semester': _selectedOpeningSemester.toString(),
        'opening_grade': _selectedOpeningGrade.toString(),
        'type_md': _selectedTypeMd.toString(),
        'type_tr': _selectedTypeTr.toString(),
        'use_language': _useLanguageController.text.isNotEmpty ? _useLanguageController.text : '',
        'subject_info': _subjectInfoController.text.isNotEmpty ? _subjectInfoController.text : '',
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('성공적으로 수정되었습니다'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('수정 Error'),
        ),
      );
    }
  }

  Future<void> deleteSubjectInfo() async {
    final url = Uri.parse('http://203.247.42.144:443/subject/delete');
    final response = await http.delete(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'subject_id': _subjectId,
        'pro_id': _proId,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('성공적으로 삭제되었습니다'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('삭제 Error'),
        ),
      );
    }
  }


  @override
  void initState() {
    super.initState();
    fetchSubjectInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '과목 수정',
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
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 5.0),
              Text(
                '※ 학수번호 및 담당교수는 수정이 불가합니다. 과목 삭제 후 다시 추가해주세요!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 16.0),
              Text(
                '학수번호: $_subjectId',
              ),
              SizedBox(height: 5.0),
              Text(
                '담당 교수: $_proName',
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _subjectNameController,
                decoration: InputDecoration(
                  labelText: '과목명',
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _creditController,
                decoration: InputDecoration(
                  labelText: '학점 (숫자만 입력)',
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _subjectInfoController,
                decoration: InputDecoration(
                  labelText: '교과목 개요',
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _useLanguageController,
                decoration: InputDecoration(
                  labelText: '사용하는 언어',
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _classGoalController,
                decoration: InputDecoration(
                  labelText: '학습목표',
                ),
              ),
              SizedBox(height: 16.0),
              DropdownButtonFormField<int>(
                value: _selectedOpeningGrade,
                decoration: InputDecoration(
                  labelText: '개설학년',
                ),
                items: [
                  DropdownMenuItem<int>(
                    value: 1,
                    child: Text('1학년'),
                  ),
                  DropdownMenuItem<int>(
                    value: 2,
                    child: Text('2학년'),
                  ),
                  DropdownMenuItem<int>(
                    value: 3,
                    child: Text('3학년'),
                  ),
                  DropdownMenuItem<int>(
                    value: 4,
                    child: Text('4학년'),
                  ),
                ],
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedOpeningGrade = newValue!;
                  });
                },
              ),
              SizedBox(height: 16.0),
              DropdownButtonFormField<int>(
                value: _selectedOpeningSemester,
                decoration: InputDecoration(
                  labelText: '개설학기',
                ),
                items: [
                  DropdownMenuItem<int>(
                    value: 1,
                    child: Text('1학기'),
                  ),
                  DropdownMenuItem<int>(
                    value: 2,
                    child: Text('2학기'),
                  ),
                ],
                onChanged: (int? newValue) {
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
                items: [
                  DropdownMenuItem<int>(
                    value: 1,
                    child: Text('전기'),
                  ),
                  DropdownMenuItem<int>(
                    value: 2,
                    child: Text('전선'),
                  ),
                ],
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
                items: [
                  DropdownMenuItem<int>(
                    value: 1,
                    child: Text('웹/앱 개발자'),
                  ),
                  DropdownMenuItem<int>(
                    value: 2,
                    child: Text('백엔드 개발자'),
                  ),
                  DropdownMenuItem<int>(
                    value: 3,
                    child: Text('DB전문가'),
                  ),
                  DropdownMenuItem<int>(
                    value: 4,
                    child: Text('정보보안'),
                  ),
                  DropdownMenuItem<int>(
                    value: 0,
                    child: Text('해당없음'),
                  ),
                ],
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
                items: [
                  DropdownMenuItem<int>(
                    value: 1,
                    child: Text('풀스택 개발자'),
                  ),
                  DropdownMenuItem<int>(
                    value: 2,
                    child: Text('정보보안전문가'),
                  ),
                  DropdownMenuItem<int>(
                    value: 3,
                    child: Text('SW엔지니어'),
                  ),
                  DropdownMenuItem<int>(
                    value: 0,
                    child: Text('해당없음'),
                  ),
                ],
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedTypeTr = newValue!;
                  });
                },
              ),
              SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      modifySubjectInfo();
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        Color(0xffC1D3FF),
                      ),
                    ),
                    child: Text('수정'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      deleteSubjectInfo();
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        Color(0xffC1D3FF),
                      ),
                    ),
                    child: Text('삭제'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subjectNameController.dispose();
    _creditController.dispose();
    _subjectDivisionController.dispose();
    _classGoalController.dispose();
    _openingSemesterController.dispose();
    _useLanguageController.dispose();
    _subjectInfoController.dispose();
    super.dispose();
  }
}