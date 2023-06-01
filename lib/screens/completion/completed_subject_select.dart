import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:core';
import 'dart:async';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/drawer.dart';
import 'package:capstone/screens/completion/completion_status.dart';



// 과목 모델
class Subject {
  final int subjectId;
  final int proId;
  final String subjectName;
  final int credit;
  final int subjectDivision;
  final int? typeMd;
  final int? typeTr;

  Subject({
    required this.subjectId,
    required this.proId,
    required this.subjectName,
    required this.credit,
    required this.subjectDivision,
    this.typeMd,
    this.typeTr,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      subjectId: json['subject_id'],
      proId: json['pro_id'],
      subjectName: json['subject_name'],
      credit: json['credit'],
      subjectDivision: json['subject_division'],
      typeMd: json['type_md'],
      typeTr: json['type_tr'],
    );
  }
}

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
class SubjectSelect extends StatefulWidget {
  final int subjectId;

  SubjectSelect({Key? key, required this.subjectId}) : super(key: key);

  @override
  _SubjectSelectState createState() => _SubjectSelectState();
}

class _SubjectSelectState extends State<SubjectSelect> {
  final storage = new FlutterSecureStorage();
  final TextEditingController _controller = TextEditingController();
  Future<CompletedSubjects>? _futureCompletedSubjects;

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
    fetchSubjects();
    fetchCompletedSubjects();
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


  //사용자 인증 jwt 토큰 방식
  Future<String> getStudentIdFromToken() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) {
      throw Exception('Token is not found');
    }

    final jwtToken = JwtDecoder.decode(token); // use jwt_decoder package to decode the token

    return jwtToken['student_id']; // ensure the token includes 'student_id'
  }



  //이수과목 저장
  Future<void> saveCompletedSubjects(List<CompletedSubjects> completedSubjects) async {
    final url = Uri.parse('http://3.39.88.187:3000/user/required/add');

    final studentId = await getStudentIdFromToken();

    final data = completedSubjects
        .map((completedSubject) => {
      'student_id': studentId,
      'subject_id': completedSubject.subjectId,
      'pro_id': completedSubject.proId,
    })
        .toList();

    final body = json.encode(data);
    print('Request body: $body');  // 로깅
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    //이수과목 저장 성공/실패 알림
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이수과목이 성공적으로 저장되었습니다.'),
        ),
      );
      print('서버 응답: ${response.body}'); // 서버의 응답을 출력합니다.
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이수과목 저장에 실패하였습니다. 상태 코드: ${response.statusCode}'),
        ),
      );
      print('서버 응답: ${response.body}'); // 에러 발생 시 서버의 응답을 출력합니다.
    }
  }



  // 이수과목 가져오기
  Future<List<Subject>> fetchCompletedSubjects() async {
    final Uri completedSubjectsUrl = Uri.parse('http://3.39.88.187:3000/user/required?student_id=${widget.subjectId}');
    final http.Response completedSubjectsResponse = await http.get(completedSubjectsUrl);

    if (completedSubjectsResponse.statusCode == 200) {
      final List<dynamic> completedSubjectsData = json.decode(completedSubjectsResponse.body);
      print('Completed subjects response body: ${completedSubjectsResponse.body}');

      List<Future<Subject>> futureSubjects = [];
      for (var item in completedSubjectsData) {
        final CompletedSubjects completedSubject = CompletedSubjects.fromJson(item);

        final Uri subjectUrl = Uri.parse('http://3.39.88.187:3000/user/required/subject?subject_id=${completedSubject.subjectId}');

        Future<Subject> futureSubject = http.get(subjectUrl).then((subjectResponse) {
          if (subjectResponse.statusCode == 200) {
            final List<dynamic> subjectData = json.decode(subjectResponse.body);
            print('Subject response body: ${subjectResponse.body}');

            return Subject.fromJson(subjectData[0]);
          } else {
            throw Exception('Failed to load subject data: ${subjectResponse.statusCode}');
          }
        });

        futureSubjects.add(futureSubject);
      }

    //모든 Futures가 완료될 때까지 기다렸다가 과목 리스트를 작성
      List<Subject> completedSubjects = await Future.wait(futureSubjects);

      print('Retrieved Subject objects: $completedSubjects');
      return completedSubjects;
    } else {
      throw Exception('Failed to load completed subjects: ${completedSubjectsResponse.statusCode}');
    }
  }


  // 총전공학점 계산
  int calculateTotalMajorCredit() {
    int totalMajorCredit = 0;
    for (var subject in _electiveSelections) {
      totalMajorCredit += subject.credit;
    }
    return totalMajorCredit;
  }


  // 빌드
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
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              SizedBox(height: 20),
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
                          items: _compulsoryItems,
                          onConfirm: (values) {
                            setState(() {
                              _compulsorySelections = values.cast<Subject>();
                            });
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
                                ),
                              )
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
                            setState(() {
                              _electiveSelections = values.cast<Subject>();
                            });
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
              ElevatedButton(
                onPressed: () async {
                  if (_compulsorySelections.isEmpty && _electiveSelections.isEmpty) {
                    print("선택된 과목이 없습니다.");
                    return;
                  }

                  try {
                    List<CompletedSubjects> compulsorySubjects = _compulsorySelections.map((subject) => CompletedSubjects(
                        studentId: widget.subjectId,
                        subjectId: subject.subjectId,
                        proId: subject.proId)).toList();

                    List<CompletedSubjects> electiveSubjects = _electiveSelections.map((subject) => CompletedSubjects(
                        studentId: widget.subjectId,
                        subjectId: subject.subjectId,
                        proId: subject.proId)).toList();

                    await saveCompletedSubjects([...compulsorySubjects, ...electiveSubjects]);

                    List<Subject> completedSubjects = await fetchCompletedSubjects();
                    print('모든 선택한 과목이 저장되었습니다.');
                    print('Completed subjects retrieved: $completedSubjects');
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
              )
,
              SizedBox(height: 50.0),
            ],
          ),
        ),
      ),
    );
  }
}
