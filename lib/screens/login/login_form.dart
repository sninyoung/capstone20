import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/screens/login/signup_form.dart';
import 'package:capstone/main.dart';


class LoginPage extends StatefulWidget { //StatefulWidget 로 설정
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> { //LoginPage  --> _LoginPageState 로 이동
  TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 20.0);
  TextEditingController student_id = TextEditingController();  //각각 변수들 지정(인스턴스생성)
  TextEditingController password = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() { //initState 초기화를 위해 필요한 저장공간.
    super.initState();
    student_id = TextEditingController(text: ""); //변수를 여기서 초기화함.
    password = TextEditingController(text: "");
  }

  @override
  void dispose() { //필요없으면 지움
    student_id.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Future<String?> loginUser(String studentId, String password) async {
    final String apiUrl = 'http://3.39.88.187:3000/user/login?student_id=$studentId&password=$password'; // API URL 지정

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'student_id': studentId, // 로그인에 필요한 정보 전달
        'password': password,
      }),
    );

    if (response.statusCode == 200) { // 로그인 성공
      final jsonResponse = jsonDecode(response.body);
      final storage = FlutterSecureStorage();
      await storage.write(key: 'token', value: jsonResponse['token']);
      return null;
    } else if (response.statusCode == 400) { // 잘못된 요청
      return '잘못된 요청입니다.';
    } else if (response.statusCode == 401) { // 로그인 실패
      return '아이디 또는 비밀번호가 일치하지 않습니다.';
    } else { // 서버 오류
      return '서버 오류가 발생했습니다.';
    }
  }

  @override
  Widget build(BuildContext context) { //Widget 여기서 UI화면 작성
    return Scaffold(
      appBar: AppBar(
        title: Text('로그인'), //APP BAR 만들기
        backgroundColor: Color(0xffC1D3FF),
      ),
      body: Padding( //body는 appbar아래 화면을 지정.
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Center( //가운데로 지정
            child: ListView( //ListView - children으로 여러개 padding설정
              shrinkWrap: true,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField( //TextFormField
                    controller: student_id, //student_id이 TextEditingController
                    validator: (value) =>
                    (value!.isEmpty) ? "학번을 입력해 주세요" : null, //hint 역할
                    style: style,
                    decoration: InputDecoration( //textfield안에 있는 이미지
                        prefixIcon: Icon(Icons.email),
                        labelText: "학번", //hint
                        border: OutlineInputBorder()), //클릭시 legend 효과
                  ),
                ),
                Padding( //두번째 padding <- LIstview에 속함.
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    obscureText: true,
                    controller: password,
                    validator: (value) =>
                    (value!.isEmpty) ? "비밀번호를 입력해 주세요" : null, //아무것도 누르지 않은 경우 이 글자 뜸.
                    style: style,
                    decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock),
                        labelText: "비밀번호",
                        border: OutlineInputBorder()),
                  ),
                ),
                Padding( //세번째 padding
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Material(
                    elevation: 5.0, //그림자효과
                    borderRadius: BorderRadius.circular(30.0), //둥근효과
                    color: const Color(0xffC1D3FF),
                    child: MaterialButton( //child - 버튼을 생성
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final String? errorMsg = await loginUser(student_id.text, password.text);
                          if (errorMsg == null) { // 로그인 성공
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => MyHomePage()),
                            );
                          } else { // 로그인 실패
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
                          }
                        }
                      },
                      child: Text(
                        "로그인",
                        style: style.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10), //View같은 역할 중간에 띄는 역할
                Center( //Center <- Listview
                  child: InkWell( //InkWell을 사용 -- onTap이 가능한 이유임.
                    child: Text(
                      '가입하기',
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpPage()),
                      );
                    },
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

