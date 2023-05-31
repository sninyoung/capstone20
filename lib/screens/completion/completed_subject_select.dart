import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:core';
import 'dart:async';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/drawer.dart';
import 'package:capstone/screens/completion/completion_status.dart';

// 이수과목 선택 페이지

// 학생 모델
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

class SubjectSelect extends StatefulWidget {
  final int subjectId;

  SubjectSelect({Key? key, required this.subjectId}) : super(key: key);

  @override
  _SubjectSelectState createState() => _SubjectSelectState();
}

class _SubjectSelectState extends State<SubjectSelect> {
  final storage = new FlutterSecureStorage();
  //final TextEditingController _controller = TextEditingController();
  //Future<CompletedSubjects>? _futureCompletedSubjects;

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
    super.initState();
    fetchSubjects();
    fetchUser();
    //_compulsorySelections = [];
    //_electiveSelections = [];
    //_compulsorySelections.removeWhere((subject) => subject == null);
    //_electiveSelections.removeWhere((subject) => subject == null);
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

  Subject? findSubjectByName(String name) {
    return _subjects.firstWhere(
      (subject) => subject.subjectName == name,
      orElse: () => Subject(
        subjectName: '',
        subjectDivision: 0,
        subjectId: 0,
        proId: 0,
        credit: 0,
      ),
    );
  }

  // 유저 정보 불러오기
  Future<void> fetchUser() async {
    final storage = FlutterSecureStorage();
    final String? token = await storage.read(key: 'token');
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    // JWT 디코딩을 위한 라이브러리를 사용하여 토큰 파싱
    final List<String> tokenParts = token.split('.');
    if (tokenParts.length != 3) {
      throw Exception('Invalid token format');
    }

    final String encodedPayload = tokenParts[1];
    final String payload = utf8.decode(base64Url.decode(encodedPayload));
    final Map<String, dynamic> claims = json.decode(payload);

    // 토큰의 만료 시간 확인
    final int? expirationTime = claims['exp'];
    final int currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (expirationTime == null || currentTimestamp >= expirationTime) {
      throw Exception('Token has expired');
    }

    final Uri url = Uri.parse('http://3.39.88.187:3000/user/infotoken');
    final Uri uriWithParams = url.replace(queryParameters: {'token': token});

    final http.Response response = await http.get(
      uriWithParams,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        final Map<String, dynamic> user = data[0];
        _student = Student.fromJson(user);
      } else {
        throw Exception('Failed to parse user data');
      }
      setState(() {});
    } else {
      throw Exception('Failed to load user: ${response.statusCode}');
    }
  }

  // 이수과목 정보 저장
  Future<void> saveCompletedSubjects(
      int studentId, int subjectId, int proId) async {
    if (subjectId == null) {
      print('과목 ID가 null입니다.');
      return;
    }

    final url = Uri.parse('http://3.39.88.187:3000/user/required/add');

    final body = json.encode({
      'student_id': studentId,
      'subject_id': subjectId,
      'pro_id': proId,
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이수과목이 성공적으로 저장되었습니다.'),
        ),
      );
      final responseData = json.decode(response.body);
      print('서버 응답: $responseData'); // 서버의 응답을 출력합니다.
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이수과목 저장에 실패하였습니다. 상태 코드: ${response.statusCode}'),
        ),
      );
      final responseData = json.decode(response.body);
      print('서버 응답: $responseData'); // 에러 발생 시 서버의 응답을 출력합니다.
    }
  }

  // 이수과목 가져오기
  Future<List<Subject>> fetchCompletedSubjects(int studentId) async {
    final Uri url = Uri.parse('http://3.39.88.187:3000/user/required?student_id=${widget.subjectId}');
    final Uri uriWithParams =
        url.replace(queryParameters: {'student_id': studentId.toString()});

    final http.Response response = await http.get(
      uriWithParams,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final List<Subject> completedSubjects =
          data.map((item) => Subject.fromJson(item)).toList();
      return completedSubjects;
    } else {
      throw Exception(
          'Failed to load completed subjects: ${response.statusCode}');
    }
  }

  // 데이터 다시 가져오기
  FutureBuilder<List<Subject>> buildFutureBuilder() {
    return FutureBuilder<List<Subject>>(
      future: fetchCompletedSubjects(_student?.studentId ?? 0),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          final completedSubjects = snapshot.data!;
          return Text('Completed subjects retrieved: ${completedSubjects.toString()}');
        } else {
          return Text('No data available');
        }
      },
    );
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
                              _compulsorySelections = values.isNotEmpty ? values.cast<Subject>() : [];
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
                              _electiveSelections = values.isNotEmpty ? values.cast<Subject>() : [];
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
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  if (_compulsorySelections.isEmpty &&
                      _electiveSelections.isEmpty) {
                    print("선택된 과목이 없습니다.");
                    return;
                  }

                  try {
                    for (var subject in _compulsorySelections) {
                      if (subject != null && _student != null) {
                        await saveCompletedSubjects(_student!.studentId,
                            subject.subjectId, subject.proId ?? 0);
                        print(
                            '저장된 필수 과목: ${subject.subjectName} - 과목 ID: ${subject.subjectId} - 학번: ${_student!.studentId}');
                      }else{
                        _compulsorySelections = [];
                      }
                    }

                    for (var subject in _electiveSelections) {
                      if (subject != null && _student != null) {
                        await saveCompletedSubjects(_student?.studentId ?? 0,
                            subject.subjectId, subject.proId ?? 0);
                        print(
                            '저장된 선택 과목: ${subject.subjectName} - 과목 ID: ${subject.subjectId} - 학번: ${_student!.studentId}');
                      }else{
                        _electiveSelections = [];
                      }
                    }

                    List<Subject> completedSubjects =
                        await fetchCompletedSubjects(_student!.studentId);
                    print('모든 선택한 과목이 저장되었습니다.');
                    print('Completed subjects retrieved: $completedSubjects');
                  } catch (e) {
                    print("과목 저장 중 오류 발생: $e");
                  }

                  //print('모든 선택한 과목이 저장되었습니다.');

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
              SizedBox(height: 20.0),
              buildFutureBuilder(),
            ],
          ),
        ),
      ),
    );
  }
}
