import 'package:capstone/screens/gScore/gscore_list_screen.dart';
import 'package:capstone/screens/gScore/gscore_self_calc_screen.dart';
import 'package:capstone/screens/gScore/gscore_myscore.dart';
import 'package:capstone/screens/login/profile.dart';
import 'package:flutter/material.dart';
import 'package:capstone/main.dart';
import 'package:capstone/screens/post/party_board.dart';
import 'package:capstone/screens/post/free_board.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/screens/login/login_form.dart';
import 'package:capstone/screens/post/QnA_board.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:capstone/screens/post/notice.dart';
import 'package:capstone/screens/prof/prof_profile.dart';

class MyDrawer extends StatefulWidget {

  const MyDrawer({Key? key}) : super(key: key);


  @override
  _MyDrawerState createState() => _MyDrawerState();
}


class _MyDrawerState extends State<MyDrawer> {
  int? _userPermission; //추가

  String _errorMessage = '';
  bool _isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _studentinfo();
  }


  void logout(BuildContext context) async {
    final storage = new FlutterSecureStorage();
    await storage.delete(key: 'token');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false,
    );
  }

  String? _accountName;
  String? _accountEmail;
  void _studentinfo() async {

    setState(() => _isLoading = true);

    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '토큰이 없습니다.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('게시글 작성에 실패했습니다. (로그인 만료)')));
      });
      return;
    }


    final response = await http.get(
      Uri.parse('http://3.39.88.187:3000/user/student'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
    );

    if (response.statusCode == 201) {
      // Success

      final responseData = jsonDecode(response.body);
      setState(() {
        _accountName = responseData[0]['student_id'].toString();
        _accountEmail = responseData[0]['name'];
        _userPermission = responseData[0]['permission']; // 추가

      });
    } else {
      // Failure
      setState(() {
        final responseData = jsonDecode(response.body);

        _isLoading = false;
        _errorMessage = responseData['message'];
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_accountName == null) {
      return Center(child: CircularProgressIndicator());
    }
    final String fileName = _accountName! + '.png';
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    color: Color(0xffC1D3FF),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: Image.network(
                      'http://3.39.88.187:3000/user/loding?image=$fileName',
                      errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                        return Image.asset(
                          'assets/profile.png',
                          fit: BoxFit.cover,
                        );
                      },
                    ).image,
                    backgroundColor: Colors.white,
                  ),
                  accountName: Text(_accountName ?? ''),
                  accountEmail: Text(_accountEmail ?? ''),

                ),
                ListTile(
                  leading: Icon(Icons.home, color: Colors.grey[800]),
                  title: Text('홈'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyHomePage()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.announcement, color: Colors.grey[800]),
                  title: Text('공지사항'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Notice()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.chat, color: Colors.grey[800]),
                  title: Text('구인구직 게시판'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PartyBoardScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.article, color: Colors.grey[800]),
                  title: Text('자유게시판'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => FreeBoardScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.article, color: Colors.grey[800]),
                  title: Text('Q&A게시판'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => QnABoardScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.subdirectory_arrow_left, color: Colors.grey[800]),
                  title: Text('졸업점수 신청 및 내역'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => GScoreForm()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.calculate, color: Colors.grey[800]),
                  title: Text('졸업 점수 셀프 계산기'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SelfCalcScreen()),
                    );
                  },
                ),
                ListTile(
                    leading: Icon(Icons.person, color: Colors.grey[800]),
                    title: Text('나의 졸업인증 점수'),
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MyScorePage()),
                      );
                    }
                ),
                ListTile(
                    leading: Icon(Icons.person, color: Colors.grey[800]),
                    title: Text('프로필'),
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Profile()),
                      );
                    }
                ),
                if (_userPermission == 2)
                  ListTile(
                  leading: Icon(Icons.person, color: Colors.grey[800]),
                  title: Text('교수 정보 관리'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfProfile()),
                    );
                  },
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.grey[800]),
            title: Text('로그아웃'),
            onTap: () {
              logout(context);
            },
          ),
        ],
      ),
    );
  }
}
