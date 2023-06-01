import 'package:capstone/screens/completion/completed_subject_select.dart';
import 'package:capstone/screens/completion/mycompletion.dart';
import 'package:capstone/screens/gScore/gscore_list_screen.dart';
import 'package:capstone/screens/gScore/gscore_self_calc_screen.dart';
import 'package:capstone/screens/gScore/gscore_myscore.dart';
import 'package:capstone/screens/gScore/gscore_admin_check.dart';
import 'package:capstone/screens/login/adminsingup.dart';
import 'package:capstone/screens/login/profile.dart';
import 'package:capstone/screens/post/feedbackpage.dart';
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
import 'package:capstone/screens/gScore/gscore_admin_editor.dart';
import 'package:capstone/screens/gScore/gscore_admin_list.dart';
import 'package:capstone/screens/subject/MSmain.dart';
import 'package:capstone/screens/subject/MSmain_ASS.dart';


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
  String? _accountPermission;

  void sendFeedback(String feedbackText) async {
    setState(() => _isLoading = true);

    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '토큰이 없습니다.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('정보를 받아올 수 없습니다. (로그인 만료)'), backgroundColor: Colors.red,),
        );
      });
      return;
    }

    final Map<String, dynamic> postData = {
      'board_id': 90, // 게시판 ID를 적절히 설정하세요.
      'post_title': feedbackText,
      'post_content': '',
    };

    final response = await http.post(
      Uri.parse('http://3.39.88.187:3000/post/write'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
      body: jsonEncode(postData),
    );

    if (response.statusCode == 201) {
      // Success
      Navigator.pop(context, true);
    } else {
      // Failure
      final responseData = jsonDecode(response.body);
      setState(() {
        _isLoading = false;
        _errorMessage = responseData['message'];
      });
    }
  }


  void _studentinfo() async {

    setState(() => _isLoading = true);

    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '토큰이 없습니다.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('정보를 받아올 수 없습니다. (로그인 만료)'), backgroundColor: Colors.red,));
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
        _accountPermission = responseData[0]['permission'].toString();
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
    var a = 0;
    final String fileName = _accountName! + '.png';
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    a++;
                    print(a);
                    if(a == 1){
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('어라?..'),
                            content: Text('계속 누르면 뭔가 있을거 같지 않아?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text('닫기'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                    if (a == 5) { // a 값이 1인 경우에만 AlertDialog 반환
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('거의 다 와가'),
                            content: Text('더 눌러봐'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text('닫기'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                    if (a == 21) { // a 값이 1인 경우에만 AlertDialog 반환
                      a = 0;
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('주모'),
                            content: Text('서버 좀 켜줘'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text('닫기'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: UserAccountsDrawerHeader(
                    decoration: BoxDecoration(
                      color: Color(0xffC1D3FF),
                    ),
                    currentAccountPicture: ClipOval(
                      child: Image.network(
                        'http://3.39.88.187:3000/user/loding?image=$fileName',
                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          } else {
                            return CircularProgressIndicator();
                          }
                        },
                        errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                          return Image.asset(
                            'assets/profile.png',
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    accountName: Text(_accountName ?? ''),
                    accountEmail: Text(_accountEmail ?? ''),
                  ),

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
                ExpansionTile(
                  title: Text('게시판'),
                  leading: Icon(Icons.article, color: Colors.grey[800]),
                  children: <Widget>[
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
                  ],
                ),
                //이수현황 - 나의 이수현황, 이수과목선택
                ExpansionTile(
                  title: Text('이수현황'),
                  leading: Icon(
                      Icons.add_task_rounded, color: Colors.grey[800]),
                  children: <Widget>[
                    ListTile(
                        leading: Icon(
                            Icons.add_task_rounded, color: Colors.grey[800]),
                        title: Text('나의 이수현황'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>
                                CompletionStatusPage()),
                          );
                        }
                    ),
                    ListTile(
                      title: Text('이수과목 선택'),
                      leading: Icon(
                          Icons.assignment_turned_in_outlined,
                          color: Colors.grey[800]
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) =>
                              CompletedSubjectSelectPage(),
                        ));
                      },
                    )
                  ],),

                ExpansionTile(
                    title: Text('졸업인증'),
                    leading: Icon(Icons.school, color: Colors.grey[800]),
                    children: <Widget>[
                      ListTile(
                        leading: Icon(Icons.list, color: Colors.grey[800]),
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
                    ]),

                ExpansionTile(
                    title: Text('과목정보'),
                    leading: Icon(Icons.menu_book_rounded, color: Colors.grey[800]),
                    children: <Widget>[
                      ListTile(
                        leading: Icon(Icons.search, color: Colors.grey[800]),
                        title: Text('전공과목 정보'),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MSmain()),
                          );
                        },
                      ),
                    ]),

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

                _accountPermission == "2" || _accountPermission == "3" ?
                ExpansionTile(
                    title: Text('관리자 페이지'),
                    leading: Icon(Icons.subdirectory_arrow_left, color: Colors.grey[800]),
                    children: <Widget>[
                      ListTile(
                          leading: Icon(Icons.person_add, color: Colors.grey[800]),
                          title: Text('교수 계정 생성'),
                          onTap: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SignUpPage()),
                            );
                          }
                      ),
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
                      ListTile(
                          leading: Icon(Icons.note_alt, color: Colors.grey[800]),
                          title: Text('과목 정보 수정'),
                          onTap: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => MSmainASS()),
                            );
                          }
                      ),
                      ListTile(
                          leading: Icon(Icons.edit_note, color: Colors.grey[800]),
                          title: Text('졸업인증제 항목 관리'),
                          onTap: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => GScoreEditor()),
                            );
                          }
                      ),
                      ListTile(
                          leading: Icon(Icons.playlist_add_check, color: Colors.grey[800]),
                          title: Text('졸업인증제 일괄 승인'),
                          onTap: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AdminGScoreForm()),
                            );
                          }
                      ),
                      ListTile(
                        leading: Icon(Icons.search, color: Colors.grey[800]),
                        title: Text('졸업인증점수 검색'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AdminCheckPage()),
                          );
                        },
                      ),
                      ListTile(
                          leading: Icon(Icons.dynamic_feed, color: Colors.grey[800]),
                          title: Text('피드백 확인'),
                          onTap: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => FeedBackScreen()),
                            );
                          }
                      ),
                    ])
                    : Container(),
              ],
            ),

          ),
          ListTile(
            leading: Icon(Icons.feedback, color: Colors.grey[800]),
            title: Text('피드백'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  String feedbackText = ''; // 피드백 텍스트를 저장할 변수

                  return AlertDialog(
                    title: Text('피드백 보내기'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: '피드백 작성',
                          ),
                          textInputAction: TextInputAction.newline, // 엔터를 눌렀을 때 다음 줄로 이동
                          maxLines: null,
                          onChanged: (value) {
                            feedbackText = value; // 텍스트 필드 값이 변경될 때마다 변수에 저장
                          },
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        child: Text('취소'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: Text('보내기'),
                        onPressed: () {
                          // 피드백 보내기 로직을 여기에 구현하세요.
                          // feedbackText 변수에 텍스트 필드의 값이 저장되어 있습니다.
                          // 예를 들어, sendFeedback 함수를 호출하여 피드백을 처리한다면:
                          sendFeedback(feedbackText);

                          Navigator.of(context).pop(); // 팝업 창 닫기

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '피드백이 성공적으로 전송되었습니다.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                ),
                              ),
                              backgroundColor: Colors.green, // 배경색 설정
                              duration: Duration(seconds: 3), // 표시 시간 설정

                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
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
