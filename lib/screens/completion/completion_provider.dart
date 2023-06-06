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

//Provider을 이용해 이수현황을 관리하는 파일




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


  //JWT 토큰에서 학생 ID를 가져오는 메서드 - 학생ID로 사용자를 식별해 이수정보를 저장하기 위함.
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

  //이수과목
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
  /*saveSubjects() 함수를 통해 이들 리스트의 모든 과목들이
  JSON 형태로 인코딩되어 FlutterSecureStorage에 저장됨*/


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
  /* loadSubjects()를 호출하여 SecureStorage에서 데이터를 로드하면
  _completedCompulsory와 _completedElective 리스트는 SecureStorage에 저장된 데이터로 업데이트
*/


  //서버에서 최신 데이터를 가져와 로컬 저장소를 업데이트 하는 메서드
  Future<void> fetchCompletedSubjects(int studentId) async {
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



  //서버에 이수과목 정보를 보내는 메서드 - 이수과목 저장
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
  }


  // 서버에서 이수과목 정보를 삭제하는 메서드
  //서버에서 단일 이수과목을 삭제하는 메서드
  Future<void> deleteCompletedSubject(int studentId, int subjectId, int proId) async {
    await deleteCompletedSubjects(studentId, [{
      'subject_id': subjectId,
      'pro_id': proId
    }]);
  }

  //서버에서 복수의 이수과목을 삭제하는 메서드
  Future<void> deleteCompletedSubjects(int studentId, List<Map<String, dynamic>> subjects) async {
    final url = Uri.parse('http://203.247.42.144:443/user/required/delete');

    final List<Map<String, dynamic>> body = subjects.map((subject) => {
      'student_id': studentId,
      ...subject,
    }).toList();

    print('이수한 과목 정보를 삭제하는 deleteCompletedSubjects 메서드 Request body: ${jsonEncode(body)}'); // 로깅
    final response = await http.delete(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print('서버 응답: ${response.body}'); // 서버의 응답을 출력합니다.
    } else {
      print('에러 발생. 서버 응답: ${response.body}'); // 에러 발생 시 서버의 응답을 출력합니다.
    }
  }



  //서버에 이수과목을 추가하고 저장하는 메서드
  Future<bool> addSubjectToServer(Subject subject) async {
    final studentId = await getStudentIdFromToken();

    final response = await http.post(
      Uri.parse('http://203.247.42.144:443/user/required/add'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'student_id': studentId,
        'subject_id': subject.subjectId,
        'pro_id': subject.proId,
      }),
    );

    print('HTTP 상태 코드: ${response.statusCode}');
    //print('HTTP 응답 본문: ${response.body}');

    if (response.statusCode == 200) {
      print('서버에 과목 추가 성공: ${response.body}'); // 서버의 응답을 출력
      return true;
    } else {
      print('서버에 과목 추가 실패. 에러 메시지: ${response.body}'); // 서버의 응답을 출력
      return false;
    }
  }


  //서버에 이수과목을 삭제 메서드
  Future<bool> removeSubjectFromServer(Subject subject) async {
    final studentId = await getStudentIdFromToken();

    final response = await http.delete(
      Uri.parse('http://203.247.42.144:443/user/required/delete'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'student_id': studentId,
        'subject_id': subject.subjectId,
        'pro_id': subject.proId,
      }),
    );

    print('HTTP 상태 코드: ${response.statusCode}');
    //print('HTTP 응답 본문: ${response.body}');

    if (response.statusCode == 200) {
      print('서버에서 과목 삭제 성공: ${response.body}'); // 서버의 응답을 출력
      return true;
    } else {
      print('서버에서 과목 삭제 실패. 에러 메시지: ${response.body}'); // 서버의 응답을 출력
      return false;
    }
  }


  // 모든 과목을 반환하는 메서드 - Provider가 관리하고 있는 모든 이수한 과목을 가져오기
  List<Subject> getAllSubjects() {
    return [..._completedCompulsory, ..._completedElective];
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



  //로컬에서 과목을 추가하는 메서드
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


  //전공학점 관리
  //전공기초과목 학점
  int get totalCompulsoryCredits {
    return _completedCompulsory
        .fold(0, (sum, item) => sum + item.credit); // 전공기초과목의 학점을 합산
  }


  //총 전공학점 : 전공선택과목 학점
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
  }

  //학번으로 입학년도 구하는 메서드
  Future<int> getAdmissionYear() async {
    String studentId = await getStudentIdFromToken();
    String yearStr = studentId.substring(2, 4);
    int year = int.parse(yearStr);

    // 학번이 2000년 이후의 경우 대비
    if(year < 40) year += 2000;
    else year += 7504; //관리자 권한 조교 ID일 때 처리

    return year;
  }



  //졸업기준학점 설정하는 메서드
  Future<int> getCreditToGraduate() async {
    int admissionYear = await getAdmissionYear();
    if (admissionYear <= 2018) {
      return 60;
    } else if (admissionYear <= 2022) {
      return 66;
    } else {
      return 54;
    }
  }



//부족한 전공학점 계산하는 메서드
  Future<int> getLackingCredits() async {
    int creditsToGraduate = await getCreditToGraduate();
    int totalElectiveCredits = await getTotalElectiveCredits();

    // 이수한 전공학점이 졸업 기준학점보다 작은 경우 부족한 학점을 계산하고 반환합니다.
    // 그렇지 않으면, 0을 반환합니다.
    return (creditsToGraduate > totalElectiveCredits)
        ? creditsToGraduate - totalElectiveCredits
        : 0;
  }

}





