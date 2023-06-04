import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/screens/login/login_form.dart';
import 'package:capstone/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 20.0);
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController verificationCode = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController password2 = TextEditingController();
  String _selectedItem = '';
  final _formKey = GlobalKey<FormState>();
  final _key = GlobalKey<ScaffoldState>();
  final storage = FlutterSecureStorage();
  String _selectedGrade = "1학년";
  int gradeValue = 1;
  String fcmToken = '';

  final List<String> _grades = [
    '1학년',
    '2학년',
    '3학년',
    '4학년',
  ];

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: "");
    email = TextEditingController(text: "");
    verificationCode = TextEditingController(text: "");
    password = TextEditingController(text: "");
    password2 = TextEditingController(text: "");
    _getFCMToken();
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    verificationCode.dispose();
    password.dispose();
    password2.dispose();
    super.dispose();
  }

  Future<void> _getFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    setState(() {
      fcmToken = token ?? '';
    });
  }

  Future<void> sendVerificationEmail(String email) async {
    final String apiUrl = 'http://203.247.42.144:443/user/sendverificationemail';

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
            content: Text("인증 이메일이 발송되었습니다."),
          ),
        );

        final jsonResponse = jsonDecode(response.body);
        final storage = FlutterSecureStorage();
        await storage.write(key: 'verificationCode', value: jsonResponse['verificationCode']);
        return null;

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("인증 이메일 발송에 실패했습니다."),
          ),
        );
      }
    } catch (error) {
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("오류났습니다."),
        ),
      );
    }
  }

  Future<void> signup(String email, String verificationCode, String name, String password, int grade) async {
    final String apiUrl = 'http://203.247.42.144:443/user/signup';
    final String studentId = email.split('@')[0];
    final String nameValue = name.trim();
    final String emailValue = email.trim();
    final String passwordValue = password.trim();
    final String password2Value = password.trim();
    final int gradeValue = grade;
    final String _verificationCode = verificationCode.trim();
    final String fcm_token = fcmToken.trim();
    print("실행됨");

    if (passwordValue != password2Value) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("비밀번호가 다릅니다."),
      ));
      return;
    }

    try {
      final storage = FlutterSecureStorage();
      final savedVerificationCode = await storage.read(key: 'verificationCode');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'student_id': studentId,
          'name': nameValue,
          'email': emailValue,
          'verificationCode': savedVerificationCode,
          'password': passwordValue,
          'grade': gradeValue,
          '_verificationCode': _verificationCode,
          'fcm_token': fcm_token,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("회원가입에 성공했습니다."),
        ));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else if (response.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("이미 가입된 학번입니다."),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("회원 가입에 실패했습니다."),
        ));
      }
    } catch (error) {
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("회원 가입에 실패했습니다."),
      ));
    }
  }

  void _showGradeSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(

          content: SingleChildScrollView(
            child: ListBody(
              children: _grades.map((grade) {
                return GestureDetector(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      grade,
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedGrade = grade;
                      gradeValue = _grades.indexOf(grade) + 1;
                    });
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text("계정 만들기"),
        backgroundColor: Color(0xffC1D3FF),
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  controller: email,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "이메일을 입력 해 주세요";
                    } else if (!value.endsWith("@gm.hannam.ac.kr")) {
                      return "이메일 형식이 올바르지 않습니다";
                    }
                    return null;
                  },
                  style: style,
                  decoration: InputDecoration(
                      labelText: "이메일", border: OutlineInputBorder()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22.0),
                child: Material(
                  elevation: 5.0,
                  borderRadius: BorderRadius.circular(9.0),
                  shadowColor:  const Color(0xffC1D3FF),
                  color: const Color(0xffC1D3FF),
                  child: MaterialButton(
                    onPressed: () async {
                      try {
                        await sendVerificationEmail(email.text);
                      } catch (error) {
                        print(error);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("인증메일 발송에 실패했습니다."),
                        ));
                      }

                    },

                    child: Text(
                      "인증하기",
                      style: style.copyWith(
                          color: Colors.white, fontSize: 21.0),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  controller: verificationCode,
                  validator: (value) =>
                  (value!.isEmpty) ? "인증번호를 입력 해 주세요" : null,
                  style: style,
                  decoration: InputDecoration(
                    labelText: "인증번호",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  controller: name,
                  validator: (value) =>
                  (value!.isEmpty) ? "이름을 입력 해 주세요" : null,
                  style: style,
                  decoration: InputDecoration(
                      labelText: "이름", border: OutlineInputBorder()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  obscureText: true,
                  controller: password,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "비밀번호를 입력 해 주세요";
                    } else if (value.length < 8) {
                      return "비밀번호는 8자 이상이어야 합니다";
                    } else if (!RegExp(
                        r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#$%^&*(),.?":{}|<>]).{8,}$')
                        .hasMatch(value) || value.contains('?')) {
                      return "비밀번호는 대문자, 소문자, 숫자, 특수문자를 포함하며 '?' 문자를 사용할 수 없습니다";
                    }

                    return null;
                  },
                  style: style,
                  decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock),
                      labelText: "비밀번호",
                      border: OutlineInputBorder()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  obscureText: true,
                  controller: password2,
                  validator: (value) =>
                  (value != password.text) ? "비밀번호가 다릅니다" : null,
                  style: style,
                  decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock),
                      labelText: "비밀번호 확인",
                      border: OutlineInputBorder()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  readOnly: true,
                  onTap: _showGradeSelectionDialog,
                  controller: TextEditingController(text: _selectedGrade),
                  style: style,
                  decoration: InputDecoration(
                      labelText: "학년", border: OutlineInputBorder()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22.0),
                child: Material(
                  elevation: 5.0,
                  borderRadius: BorderRadius.circular(9.0),
                  color: const Color(0xffC1D3FF),
                  shadowColor:  const Color(0xffC1D3FF),
                  child: MaterialButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          await signup(
                              email.text,
                              verificationCode.text,
                              name.text,
                              password.text,
                              gradeValue);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginPage()),
                          );
                        } catch (error) {
                          print(error);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("회원 가입에 실패했습니다."),
                            backgroundColor: Colors.red,
                          )
                          );
                        }
                      }
                    },
                    child: Text(
                      "회원가입",
                      style: style.copyWith(
                          color: Colors.white, fontSize: 21.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

