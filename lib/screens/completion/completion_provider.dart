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

    final jwtToken =
    JwtDecoder.decode(token); // use jwt_decoder package to decode the token

    return jwtToken['student_id']; // ensure the token includes 'student_id'
  }


  String _studentID = '';
  String? _completionType;
  int _creditToGraduate = 0; // Here we can initialize it with a default value, for example 0.

  String get studentID => _studentID;
  String? get completionType => _completionType;
  int get creditToGraduate => _creditToGraduate;




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



  /*
  //과목 추가
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
    print('HTTP 응답 본문: ${response.body}');

    if (response.statusCode == 200) {
      print('서버 응답: ${response.body}'); // 서버의 응답을 출력
      return true;
    } else {
      print('에러 발생. 서버 응답: ${response.body}'); // 서버의 응답을 출력
      return false;
    }
  }

  // 과목 삭제
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
    print('HTTP 응답 본문: ${response.body}');

    if (response.statusCode == 200) {
      print('서버 응답: ${response.body}'); // 서버의 응답을 출력
      return true;
    } else {
      print('에러 발생. 서버 응답: ${response.body}'); // 서버의 응답을 출력
      return false;
    }
  }
*/


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
  // 전공기초과목의 학점을 합산
  int get totalCompulsoryCredits {
    return _completedCompulsory
        .fold(0, (sum, item) => sum + item.credit);
  }
  // 전공선택과목의 학점을 합산 = 총전공학점 계산
  int get totalElectiveCredits {
    return _completedElective
        .fold(0, (sum, item) => sum + item.credit);
  }



  //졸업최저이수학점을 분류하기 위한 학번 저장하는 메서드
  void setStudentId(String studentId) {
    _studentID = studentId;
    notifyListeners();
  }

  // SecureStorage에 이수유형을 저장하는 메서드
  Future<void> saveCompletionType() async {
    await storage.write(key: 'completionType', value: _completionType);
  }

  // SecureStorage에서 이수유형을 불러오는 메서드
  Future<void> loadCompletionType() async {
    String? data = await storage.read(key: 'completionType');
    if (data != null) {
      print('loadCompletionType() Data: $data'); // 로깅
      _completionType = data;
      notifyListeners();
    }
  }

//졸업최저이수학점
  //학번, 23학번 이상은 이수유형별 졸업최저이수학점을 계산해주는 메서드
  int setCreditToGraduate() {
    int enrollmentYear = int.parse(_studentID.substring(0, 2));

    if (enrollmentYear <= 18) {
      return 60;
    } else if (enrollmentYear <= 22) {
      return 66;
    } else {
      switch (_completionType) {
        case 'CS':
          return 54;
        case 'MD':
          return 60;
        case 'TR':
          return 63;
        case '부전공':
          return 42;
        case '다전공':
          return 36;
        default:
          throw Exception('Invalid completion type');
      }
    }
  }


  //이수유형별로 졸업기준학점을 설정  -setCreditToGraduate메서드를 호출해 _creditToGraduate 필드에 값을 할당
  Future<void> setCompletionType(String completionType) async {
    _completionType = completionType;
    _creditToGraduate = setCreditToGraduate(); // using the method to assign value to _creditToGraduate
    await saveCompletionType();
    notifyListeners();
  }




  //앱이 시작될 때 학번을 가져오고, 졸업 학점을 설정하고, 이수 유형을 불러오는 작업을 수행
  Future<void> init() async {
    _studentID = await getStudentIdFromToken();
    await loadCompletionType();
    setCreditToGraduate();
  }





}





