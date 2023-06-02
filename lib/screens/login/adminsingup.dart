import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // JSON Encode, Decode를 위한 패키지
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // flutter_secure_storage 패키지
import 'package:capstone/screens/login/login_form.dart';

/// 회원가입 화면
class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 20.0);
  TextEditingController student_id = TextEditingController();
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController verificationCode = TextEditingController(); // 이메일 인증번호 입력 필드 추가
  TextEditingController password= TextEditingController();
  TextEditingController password2 = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _key = GlobalKey<ScaffoldState>();
  final storage = FlutterSecureStorage();
  String _selectedGrade = "1학년"; //초기값은 1학년으로 설정
  int gradeValue =1;

  @override
  void initState() {
    super.initState();
    student_id = TextEditingController(text: "");
    name = TextEditingController(text: "");
    email = TextEditingController(text: "");
    verificationCode = TextEditingController(text: "");
    password = TextEditingController(text: "");
    password2 = TextEditingController(text: "");
  }

  @override
  void dispose() {
    student_id.dispose();
    name.dispose();
    email.dispose();
    verificationCode.dispose();
    password.dispose();
    password2.dispose();
    super.dispose();
  }

  Future<void> adminsignup(String student_id, String email, String name, String password) async {
    final String apiUrl='http://203.247.42.144:443/user/adminsignup';
    final String studentId = student_id.trim();
    final String nameValue = name.trim();
    final String emailValue = email.trim();
    final String passwordValue = password.trim();
    final String password2Value = password.trim();
    print("실행됨");

    if (passwordValue != password2Value) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("비밀번호가 다릅니다."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    try {

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'student_id': studentId,
          'name': nameValue,
          'email': emailValue,
          'password': passwordValue,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("회원가입에 성공했습니다."),
          backgroundColor: Colors.green,
        ));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else if (response.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("이미 가입된 사번입니다."),
          backgroundColor: Colors.red,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("회원 가입에 실패했습니다"),
          backgroundColor: Colors.red,
        ));
      }
    } catch (error) {
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("회원 가입에 실패했습니다."),
        backgroundColor: Colors.red,
      ));
    }
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
                  controller: student_id,
                  validator: (value) =>
                  (value!.isEmpty) ? "사번을 입력 해 주세요" : null,
                  style: style,
                  decoration: InputDecoration(
                      labelText: "사번", border: OutlineInputBorder()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  controller: email,
                  validator: (value) {
                    if (value!.isEmpty) { return "이메일을 입력 해 주세요"; }
                    else if (!value.endsWith("@hnu.kr")) {
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Material(
                  elevation: 5.0,
                  borderRadius: BorderRadius.circular(30.0),
                  color: const Color(0xffC1D3FF),
                  child: MaterialButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          await adminsignup(student_id.text, email.text, name.text, password.text);
                          // 회원가입 성공 시 로그인 화면으로 이동
                          Navigator.pop(context);
                        } catch (error) {
                          print(error);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("회원 가입에 실패했습니다."),
                            backgroundColor: Colors.red,
                          ));
                        }
                      }
                    },
                    child: Text(
                      "회원 가입",
                      style: style.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold),
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