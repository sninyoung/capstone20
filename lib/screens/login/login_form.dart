import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/screens/login/signup_form.dart';
import 'package:capstone/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 20.0);
  TextEditingController student_id = TextEditingController();
  TextEditingController password = TextEditingController();
  String fcmToken = '';

  final _formKey = GlobalKey<FormState>();

  late var timer;
  @override
  void initState() {
    super.initState();
    student_id = TextEditingController(text: "");
    password = TextEditingController(text: "");
    _checkSession();
    _getFCMToken();

  }

  @override
  void dispose() { //필요없으면 지움
    student_id.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage()),
      );
    }
  }

  Future<void> _getFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    setState(() {
      fcmToken = token ?? '';
    });
  }

  @override
  Future<String?> loginUser(String studentId, String password) async {
    final String apiUrl = 'http://203.247.42.144:443/user/login';
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'student_id': studentId, // 로그인에 필요한 정보 전달
        'password': password,
        'fcmToken': fcmToken,
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

  Future<void> sendVerificationEmail(String email) async {
    final String apiUrl = 'http://203.247.42.144:443/user/sendverificationpassword';

    if (!email.endsWith("@gm.hannam.ac.kr")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("이메일 형식이 올바르지 않습니다."),
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("비밀번호 초기화가 완료되었습니다."),
          ),
        );

        return null;

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("비밀번호 초기화 이메일 발송에 실패했습니다."),
          ),
        );
      }
    } catch (error) {
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("오류가 발생했습니다."),
        ),
      );
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
                  child: ElevatedButton( //child - 버튼을 생성
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final String? errorMsg = await loginUser(student_id.text, password.text);
                        if (errorMsg == null) { // 로그인 성공
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => MyHomePage()),
                          );
                        } else { // 로그인 실패
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red,));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shadowColor:  const Color(0xffC1D3FF),
                      primary: const Color(0xffC1D3FF),
                      side: BorderSide(color: const Color(0xffC1D3FF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9.0),
                      ),
                      fixedSize: Size(double.infinity, 38), // 버튼의 세로 길이를 50으로 설정
                    ),
                    child: Text(
                      "로그인",
                      style: style.copyWith(
                        color: Colors.white,
                        fontSize: 22.0,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10), //View같은 역할 중간에 띄는 역할
                Padding( //네번째 padding
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SignUpPage()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            primary: const Color(0xffC1D3FF),
                            side: BorderSide(color: Colors.white ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.0),
                            ),
                          ),
                          child: Text(
                            "가입하기",
                            style: style.copyWith(
                              color: const Color(0xffC1D3FF),

                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Container(
                        width: 1,
                        height: 40,
                        color: const Color(0xffC1D3FF),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            String enteredEmail = '';

                            enteredEmail = await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('임시 비밀번호 발급을 위해 이메일 입력'),
                                  content: TextField(
                                    onChanged: (value) {
                                      enteredEmail = value;
                                    },
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: Text('확인'),
                                      onPressed: () {
                                        sendVerificationEmail(enteredEmail);
                                        Navigator.of(context).pop(enteredEmail);
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            primary: const Color(0xffC1D3FF),
                            side: BorderSide(color:Colors.white ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.0),
                            ),
                          ),
                          child: Text(
                            "비밀번호 찾기",
                            style: style.copyWith(
                              color: const Color(0xffC1D3FF),
                            ),
                          ),
                        ),
                      ),
                    ],
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
