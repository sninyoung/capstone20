import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:core';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/screens/completion/subject_model.dart';
import 'package:capstone/screens/completion/mycompletion.dart';
import 'package:capstone/screens/completion/completed_subject_select.dart';

//Provider을 이용해 이수현황을 관리

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


//Provider 클래스
class CompletionProvider extends ChangeNotifier {
  final storage = new FlutterSecureStorage();

  List<Subject> _completedCompulsory = []; //선언과 동시에 초기화해줘야 함.
  List<Subject> _completedElective = [];

  List<Subject> get completedCompulsory => _completedCompulsory;
  List<Subject> get completedElective => _completedElective;

  List<Subject> _prevCompulsorySelections = [];
  List<Subject> _prevElectiveSelections = [];

  String _selectedYear = "2019~2022년도";  // 초기값 설정
  String _selectedMajor = "주전공";  // 초기값 설정

  final List<String> admissionYears = ["2011~2018년도", "2019~2022년도", "2023년도 이후"];
  final Map<String, List<String>> majorTypes = {
    "2011~2018년도": ["주전공", "다전공", "부전공"],
    "2019~2022년도": ["주전공", "다전공", "부전공"],
    "2023년도 이후": ["1 :CS", "2 :MD", "3 :TR", "4 :부전공(컴공과)", "4 :부전공(타학과)", "5 :다전공"],
  };

  String get selectedYear => _selectedYear;
  String get selectedMajor => _selectedMajor;

  CompletionProvider({String? selectedYear, String? selectedMajor}) {
    _selectedYear = selectedYear ?? _selectedYear;
    _selectedMajor = selectedMajor ?? _selectedMajor;
  }


  //JWT 토큰에서 학생 ID를 가져오는 메서드 - 학생ID로 사용자를 식별과 인증
  Future<String> getStudentIdFromToken() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) {
      throw Exception('Token is not found');
    }

    // JWT 토큰의 만료 여부 확인
    if(JwtDecoder.isExpired(token)){
      throw Exception('Token has expired');
    }

    final jwtToken =
    JwtDecoder.decode(token); // use jwt_decoder package to decode the token

    return jwtToken['student_id']; // ensure the token includes 'student_id'
  }


  //이수과목 관련 함수
  //로컬에 과목을 추가하는 메서드
  void addSubject(Subject subject) {
    if (subject.subjectDivision == 1) {
      //_completedCompulsory 리스트에 subjectId가 같은 과목이 있는지 검사
      if (!_completedCompulsory.any((element) => element.subjectId == subject.subjectId)) {
        _completedCompulsory.add(subject);
        print('로컬에 과목 추가 성공');
        notifyListeners();
      }
    } else if (subject.subjectDivision == 2) {
      if (!_completedElective.any((element) => element.subjectId == subject.subjectId)) {
        _completedElective.add(subject);
        print('로컬에 과목 추가 성공');
        notifyListeners();
      }
    }
  }

  //로컬에서 과목을 삭제하는 메서드
  void removeSubject(Subject subject) {
    if (subject.subjectDivision == 1) {
      _completedCompulsory.remove(subject);
    } else if (subject.subjectDivision == 2) {
      _completedElective.remove(subject);
    }
    print('로컬에서 과목 삭제 성공');
    notifyListeners();
  }


  // SecureStorage에 이수한 과목을 저장하는 메서드
  Future<void> saveSubjects() async {
    List<Subject> allSubjects = []
      ..addAll(_completedCompulsory)
      ..addAll(_completedElective);

    await storage.write(
        key: 'completedSubjects',
        value: jsonEncode(
            allSubjects.map((subject) => subject.toJson()).toList()));
  }


  // SecureStorage에서 기존에 저장된 이수한 과목을 불러오는 메서드
  Future<void> loadSubjects() async {
    String? data = await storage.read(key: 'completedSubjects');
    if (data != null) {
      print('기존에 저장된 이수한 과목을 불러오는 메서드 loadSubjects() Data: $data'); //로깅
      var subjectData = jsonDecode(data) as List;
      _completedCompulsory = subjectData
          .map((item) => Subject.fromJson(item))
          .where((subject) => subject.subjectDivision == 1)
          .toList();
      _completedElective = subjectData
          .map((item) => Subject.fromJson(item))
          .where((subject) => subject.subjectDivision == 2)
          .toList();
      notifyListeners();
    }
  }



  //서버에서 최신 데이터를 가져와 로컬 저장소를 업데이트 하는 메서드
  Future<void> fetchCompletedSubjects(String studentId) async {
    final Uri completedSubjectsUrl =
    Uri.parse('http://203.247.42.144:443/user/required?student_id=$studentId');
    final http.Response completedSubjectsResponse =
    await http.get(completedSubjectsUrl);

    if (completedSubjectsResponse.statusCode == 200) {
      final List<dynamic> completedSubjectsData =
      json.decode(completedSubjectsResponse.body);

      List<Subject> completedSubjects = [];

      for (var item in completedSubjectsData) {
        final CompletedSubjects completedSubject =
        CompletedSubjects.fromJson(item);

        final Uri subjectUrl = Uri.parse(
            'http://203.247.42.144:443/user/required/subject?subject_id=${completedSubject.subjectId}');

        var subjectResponse = await http.get(subjectUrl);
        if (subjectResponse.statusCode == 200) {
          final List<dynamic> subjectData =
          json.decode(subjectResponse.body);
          Subject subject = Subject.fromJson(subjectData[0]);
          completedSubjects.add(subject);
        } else {
          throw Exception(
              'Failed to load subject data: ${subjectResponse.statusCode}');
        }
      }

      _completedCompulsory = completedSubjects.where((subject) => subject.subjectDivision == 1).toList();
      _completedElective = completedSubjects.where((subject) => subject.subjectDivision == 2).toList();

      // SecureStorage에 이수한 과목 정보를 저장
      saveSubjects();

      notifyListeners();
    } else {
      throw Exception(
          'Failed to load completed subjects: ${completedSubjectsResponse.statusCode}');
    }
  }


  //서버에 이수과목을 저장하는 메서드(배열방식으로)
  Future<void> saveCompletedSubjects() async {
    final url = Uri.parse('http://203.247.42.144:443/user/required/add');
    final studentId = await getStudentIdFromToken();

    final List<Map<String, dynamic>> data = [];
    for (final subject in _completedCompulsory) {
      data.add({
        'student_id': studentId,
        'subject_id': subject.subjectId,
        'pro_id': subject.proId,
      });
    }
    for (final subject in _completedElective) {
      data.add({
        'student_id': studentId,
        'subject_id': subject.subjectId,
        'pro_id': subject.proId,
      });
    }

    final body = json.encode(data);
    print('이수한 과목 정보를 보내는 saveCompletedSubjects 메서드 Request body: $body'); // 로깅
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      print('서버 응답: ${response.body}'); // 서버의 응답을 출력합니다.
    } else {
      print('서버 응답: ${response.body}'); // 에러 발생 시 서버의 응답을 출력합니다.
    }

    // 이수과목 변경이 성공적으로 이루어진 후에는 서버로부터 최신 데이터를 가져와 로컬 저장소를 업데이트합니다.
    await fetchCompletedSubjects(studentId);
  }

  //서버에서 이수과목을 삭제하는 메서드(배열방식으로)
  Future<void> deleteCompletedSubjects() async {
    final url = Uri.parse('http://203.247.42.144:443/user/required/delete');
    final studentId = await getStudentIdFromToken();

    final List<Map<String, dynamic>> data = [];
    for (final subject in _completedCompulsory) {
      data.add({
        'student_id': studentId,
        'subject_id': subject.subjectId,
        'pro_id': subject.proId,
      });
    }
    for (final subject in _completedElective) {
      data.add({
        'student_id': studentId,
        'subject_id': subject.subjectId,
        'pro_id': subject.proId,
      });
    }

    final body = json.encode(data);
    print('이수한 과목 정보를 삭제하는 deleteCompletedSubjects 메서드 Request body: $body'); // 로깅

    final response = await http.delete(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      print('서버 응답: ${response.body}'); // 서버의 응답을 출력합니다.
    } else {
      print('서버 응답: ${response.body}'); // 에러 발생 시 서버의 응답을 출력합니다.
    }
  }


  //변경사항을 확인하고 서버에 업데이트하는 메서드
  Future<void> confirmSelections(
      List<Subject> compulsorySelections,
      List<Subject> electiveSelections,
      ) async {
    // 전공 기초과목 처리
    for (Subject subject in compulsorySelections) {
      if (!_prevCompulsorySelections.contains(subject)) {
        addSubject(subject);
        await saveCompletedSubjects();
      }
    }
    for (Subject subject in _prevCompulsorySelections) {
      if (!compulsorySelections.contains(subject)) {
        removeSubject(subject);
        await deleteCompletedSubjects();
      }
    }
    _prevCompulsorySelections = List<Subject>.from(compulsorySelections);

    // 전공 선택과목 처리
    for (Subject subject in electiveSelections) {
      if (!_prevElectiveSelections.contains(subject)) {
        addSubject(subject);
        await saveCompletedSubjects();
      }
    }
    for (Subject subject in _prevElectiveSelections) {
      if (!electiveSelections.contains(subject)) {
        removeSubject(subject);
        await deleteCompletedSubjects();
      }
    }
    _prevElectiveSelections = List<Subject>.from(electiveSelections);

    print('서버에 보낼 전공기초과목: $compulsorySelections');
    print('서버에 보낼 전공선택과목: $electiveSelections');
  }


  //전공기초과목 업데이트
  void updateCompulsory(List<Subject> newSubjects) {
    //새로운 과목 리스트가 기존의 _completedCompulsory와 다를 때만 업데이트
    if (_completedCompulsory != newSubjects) {
      _completedCompulsory = newSubjects;
      notifyListeners();
    }
  }

  //전공선택과목 업데이트
  void updateElective(List<Subject> newSubjects) {
    if (_completedElective != newSubjects) {
      _completedElective = newSubjects;
      notifyListeners();
    }
  }




  //전공학점 관련 함수
  //전공기초과목 학점
  int get totalCompulsoryCredits {
    return _completedCompulsory
        .fold(0, (sum, item) => sum + item.credit); // 전공기초과목의 학점을 합산
  }



/*  //총 전공학점 : 전공선택과목 학점
  Future<int> getTotalElectiveCredits() async {
    int baseCredits = _completedElective
        .fold(0, (sum, item) => sum + item.credit); // 전공선택과목의 학점을 합산

    int admissionYear = await getAdmissionYear();
    if (admissionYear >= 2019 && admissionYear <= 2022) {
      // 이수한 전공기초과목에서 "컴퓨터개론"이라는 과목이 있는지 확인
      bool hasIntroToComputer = _completedCompulsory
          .any((subject) => subject.subjectName == "컴퓨터개론");

      if (hasIntroToComputer) {
        baseCredits += 3;  // "컴퓨터개론"이라는 과목이 있다면 3학점을 추가
      }
    }

    return baseCredits;

    19~22학번이 컴퓨터개론을 수강했을 경우 3학점 추가 로직.
  }*/

  //총 전공학점 : 전공선택과목 학점
  Future<int> getTotalElectiveCredits() async {
    int totalCredits = _completedElective
        .fold(0, (sum, item) => sum + item.credit); // 전공선택과목의 학점을 합산
    return totalCredits;
  }


  //학번으로 입학년도 구하는 메서드
  Future<int> getAdmissionYear() async {
    String studentId = await getStudentIdFromToken();
    String yearStr = studentId.substring(2, 4);
    int year = int.parse(yearStr);

    // 학번이 2000년 이후의 경우 대비
    if(year < 40) year += 2000;
    else year += 7510; //관리자 권한 조교 ID일 때 처리

    return year;
  }


  //입학년도 선택
  void setSelectedYear(String newValue) {
    _selectedYear = newValue;

    // 기본 전공유형을 설정합니다.
    if (_selectedYear == "2011~2018년도" || _selectedYear == "2019~2022년도") {
      _selectedMajor = "주전공";
    } else if (_selectedYear == "2023년도 이후") {
      _selectedMajor = "1 :CS";
    }
    notifyListeners();
  }


  //전공유형 선택
  Future<void> setSelectedMajor(String newValue) async {
    _selectedMajor = newValue;
    await storage.write(key: 'selectedMajor', value: newValue);
    notifyListeners();
  }


  //졸업기준학점 저장
  Future<void> saveCreditToGraduate(int credits) async {
    await FlutterSecureStorage().write(key: 'creditsToGraduate', value: credits.toString());
  }

//입학년도와 전공유형을 선택한 값에 따라 졸업기준학점을 설정해주는 메서드
  Future<int?> getCreditToGraduate() async {
    late int? credits;
    if (_selectedYear == "2011~2018년도") {
      if (_selectedMajor == "주전공") {
        credits = 60;
      } else if (_selectedMajor == "다전공") {
        credits = 36;
      } else if (_selectedMajor == "부전공") {
        credits = 21;
      }
    } else if (_selectedYear == "2019~2022년도") {
      if (_selectedMajor == "주전공") {
        credits = 66;
      } else if (_selectedMajor == "다전공") {
        credits = 36;
      } else if (_selectedMajor == "부전공") {
        credits = 21;
      }
    } else if (_selectedYear == "2023년도 이후") {
      if (_selectedMajor == "1 :CS") {
        credits = 54;
      } else if (_selectedMajor == "2 :MD") {
        credits = 60;
      } else if (_selectedMajor == "3 :TR") {
        credits = 63;
      } else if (_selectedMajor == "4 :부전공(컴공과)") {
        credits = 42;
      } else if (_selectedMajor == "4 :부전공(타학과)") {
        credits = 21;
      }else if (_selectedMajor == "5 :다전공") {
        credits = 36;
      }
    }

    if (credits != null) {
      await saveCreditToGraduate(credits);
    }

    return credits;
  }


  // SecureStorage에서 저장된 전공유형 값 가져오는 메서드
  Future<String?> getSelectedMajor() async {
    return await storage.read(key: 'selectedMajor');
  }


//부족한 전공학점 계산하는 메서드
  Future<int> getLackingCredits() async {
    int? creditsToGraduate = await getCreditToGraduate();
    int totalElectiveCredits = await getTotalElectiveCredits();

    // 이수한 전공학점이 졸업 기준학점보다 작은 경우 부족한 학점을 계산하고 반환합니다.
    // 그렇지 않으면, 0을 반환합니다.
    return (creditsToGraduate != null && creditsToGraduate > totalElectiveCredits)
        ? creditsToGraduate - totalElectiveCredits
        : 0;
  }


  // 필수 이수 과목을 반환하는 메서드
  Future<Set<String>> getRequiredCourses() async {
    Map<String, Map<String, Set<String>>> requiredCourses = {
      "2011~2018년도": {
        "주전공": {"프로그래밍실습", "이산구조", "컴퓨터개론", "확률 및 통계", "정보보호개론"},
        "다전공": {"프로그래밍실습", "확률 및 통계"},
        "부전공": {},
      },
      "2019~2022년도": {
        "주전공": {"프로그래밍실습", "이산구조", "공학과 경영", "확률 및 통계", "파이썬프로그래밍"},
        "다전공": {"프로그래밍실습", "확률 및 통계", "파이썬프로그래밍"},
        "부전공": {},
      },
      "2023년도 이후": {
        "주전공": {"프로그래밍실습", "이산구조", "컴퓨터개론", "확률 및 통계", "파이썬프로그래밍"},
        "다전공": {"프로그래밍실습", "이산구조", "컴퓨터개론", "확률 및 통계", "파이썬프로그래밍"},
        "부전공": {"프로그래밍실습", "이산구조", "컴퓨터개론", "확률 및 통계", "파이썬프로그래밍"},
      },
    };

    String? selectedYear = _selectedYear;
    String? selectedMajor = _selectedMajor;

    if (selectedYear != null && selectedMajor != null) {
      return requiredCourses[selectedYear]![selectedMajor] ?? {};
    }

    return {};
  }

// 필수 이수 과목 중 이수하지 않은 과목을 반환하는 메서드
  Future<List<String>> getMissingCourses(
      Set<String> requiredCourses, List<String> completedCourses) async {
    return requiredCourses.difference(completedCourses.toSet()).toList();
  }





}





