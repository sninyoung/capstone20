import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/drawer.dart';
import 'package:capstone/screens/completion/completion_status.dart';

//이수과목 선택 페이지
class Student {
  final int studentId;

  Student({
    required this.studentId,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      studentId: json['student_id'],
    );
  }
}

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

class SubjectSelect extends StatefulWidget {
  final int subjectId;

  SubjectSelect({Key? key, required this.subjectId}) : super(key: key);

  @override
  _SubjectSelectState createState() => _SubjectSelectState();
}

class _SubjectSelectState extends State<SubjectSelect> {
  List<Subject> _subjects = [];
  List<MultiSelectItem<Subject>> _compulsoryItems = [];
  List<MultiSelectItem<Subject>> _electiveItems = [];
  List<Subject> _compulsorySelections = [];
  List<Subject> _electiveSelections = [];
  List<Subject> compulsorySubjects = [];
  List<Subject> electiveSubjects = [];

  Student? _student;

  @override
  void initState() {
    //_compulsorySelections = _subjects;
    super.initState();
    fetchSubjects();
    fetchUser();
  }

//과목정보 불러오기
  Future<void> fetchSubjects() async {
    final response =
        await http.get(Uri.parse('http://3.39.88.187:3000/subject/'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      _subjects = data.map((item) => Subject.fromJson(item)).toList();

      // Update _items here.
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

  Subject? findSubjectByName(String name) {
    return _subjects.firstWhere(
      (subject) => subject.subjectName == name,
      orElse: () => Subject(
        subjectName: '',
        subjectDivision: 0,
        subjectId: 0,
        credit: 0,
      ),
    );
  }

  //유저 정보 불러오기
  Future<void> fetchUser() async {
    final response = await http.get(Uri.parse('http://3.39.88.187:3000/user'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      _student = Student.fromJson(data);

      setState(() {});
    } else {
      throw Exception('Failed to load user');
    }
  }

  //과목 정보 저장
  Future<void> saveSubjects() async {
    final compulsorySubjectIds =
        _compulsorySelections.map((e) => e.subjectId).toList();
    final electiveSubjectIds =
        _electiveSelections.map((e) => e.subjectId).toList();

    final data = {
      'student_id': _student?.studentId,
      'compulsory_subjects': compulsorySubjectIds,
      'elective_subjects': electiveSubjectIds,
    };

    final response = await http.post(
      Uri.parse('http://3.39.88.187:3000/user/required/add'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save subjects');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
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
              SizedBox(height: 40),
              Container(
                child: Text(
                  '이수한 과목을 선택하세요!',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 50),
              Column(
                children: [
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
                          buttonText: Text(
                            "전공기초과목",
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          title: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "전공기초과목",
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          items: _compulsoryItems,
                          onConfirm: (values) {
                            _compulsorySelections = values.cast<Subject>();
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
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "선택안함",
                                  style: TextStyle(color: Colors.black54),
                                ))
                            : Container(),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 40,
                  ),
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
                          items: _electiveItems,
                          onConfirm: (values) {
                            _electiveSelections = values.cast<Subject>();
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
                                ))
                            : Container(),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  await saveSubjects();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CompletionStatusPage(
                                student_id: '',
                                grade: '',
                                major_type: '',
                              )));
                },
                style: ElevatedButton.styleFrom(
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xffffff),
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    backgroundColor: const Color(0xff341F87),
                    minimumSize: Size(100, 50)),
                child: Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
