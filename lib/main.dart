import 'package:capstone/screens/completion/completed_subject_provider.dart';
import 'package:capstone/screens/post/notice.dart';
import 'package:flutter/material.dart';
import 'package:capstone/screens/login/login_form.dart';
import 'package:capstone/screens/login/profile.dart';
import 'package:capstone/drawer.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/screens/gScore/gscore_myscore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'dart:math';
import 'package:capstone/screens/post/notice_1st.dart' as Notice1st;
import 'package:capstone/screens/post/notice_2nd.dart' as Notice2nd;
import 'package:capstone/screens/post/notice_3rd.dart' as Notice3rd;
import 'package:capstone/screens/post/notice_4th.dart' as Notice4th;
import 'package:capstone/screens/post/notice_all.dart' as NoticeAll;
import 'package:capstone/screens/subject/MSmain.dart';
import 'package:capstone/screens/post/party_board.dart' as PartyBoard;
import 'package:capstone/screens/post/free_board.dart' as FreeBoard;
import 'package:capstone/screens/post/QnA_board.dart' as QABoard;
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
}



void main() async {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  WidgetsFlutterBinding.ensureInitialized();


  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  //======↓IOS용 권한 허용 코드↓=========
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  print('User granted permission: ${settings.authorizationStatus}');
  //======↑IOS용 권한 허용 코드↑=========
  runApp(MyApp());

}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Capstone',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
    );
  }
}


class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin{
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _errorMessage = '';
  bool _isLoading = false;

  final FlutterSecureStorage storage = FlutterSecureStorage();
  double percentage = 0.0;
  double newPercentage = 0.0;
  int sumScore = 0;
  double chartScore = 0;
  int i =0;

  late AnimationController percentageAnimationController;

  Future<List<Map<String, dynamic>>> _getMaxScores() async {
    final response = await http.get(Uri.parse('http://3.39.88.187:3000/gScore/maxScore'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      List<Map<String, dynamic>> maxScores = [];
      data.forEach((item) {
        final maxCategory = item['max_category'] as String;
        final maxScore = item['max_score'] as int;
        maxScores.add({
          maxCategory: maxScore,
        });
      });
      return maxScores;
    } else {
      throw Exception('Failed to load max scores');
    }
  }

  Future<void> _getUserInfo() async {
    final token = await storage.read(key: 'token');
    sumScore = 0;

    if (token == null) {
      return;
    }

    final maxScores = await _getMaxScores();
    final response = await http.get(
      Uri.parse('http://3.39.88.187:3000/gScore/user'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      final user = jsonDecode(response.body);
      final allScoreTemp = user['graduation_score'];
      final allScore = jsonDecode(allScoreTemp);

      allScore.forEach((key, value) {
        if (maxScores.any((score) => score.containsKey(key))) {
          final maxScore = maxScores.firstWhere((score) => score.containsKey(key))[key] as int;
          if (value > maxScore) {
            allScore[key] = maxScore;
          }
        }
      });
      allScore.forEach((key, value){
        sumScore += value as int;
      });
      chartScore = (sumScore / 1000) as double;
    }
    setState(() {
      sumScore;
    });
    percentage = newPercentage;
    newPercentage= chartScore;
    percentageAnimationController.forward();
  }

  @override
  void initState() {
    super.initState();
    _getUserInfo();

    percentageAnimationController =  AnimationController(
        vsync: this,
        duration: new Duration(milliseconds: 2000)
    )
      ..addListener((){
        setState(() {
          percentage=lerpDouble(percentage,newPercentage,percentageAnimationController.value)!;
        });
      });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('메인페이지'),
          backgroundColor: Color(0xffC1D3FF),
          actions: [
            IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Profile()),
                );
              },
            ),
          ],
        ),
        drawer: MyDrawer(),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() async {
              await _getUserInfo();
            });},
          child:
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Divider( // 추가: 실선
                    color: Colors.grey,
                    thickness: 1,
                  ),
                  NoticeWidget(), // NoticeWidget 추가
                  Divider( // 추가: 실선
                    color: Colors.grey,
                    thickness: 1,
                  ),
                  SubWidget(),
                  Divider( // 추가: 실선
                    color: Colors.grey,
                    thickness: 1,
                  ),
                  PostWidget(),
                  Divider( // 추가: 실선
                    color: Colors.grey,
                    thickness: 1,
                  ),
                  PercentDonut(percent: percentage, color: Color(0xffC1D3FF)),
                  Divider( // 추가: 실선
                    color: Colors.grey,
                    thickness: 1,
                  ),
                ],
              ),
            ),
          ),
        )
    );
  }
}

class SubWidget extends StatelessWidget {
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '전공과목',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Major Subject',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
              Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MSmain()),
                  );
                },
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.black45,
                  size: 16,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}




class PostWidget extends StatefulWidget {
  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  List<String> postTitles = [];
  Timer? _timer;
  bool hasFetchedData = false;

  @override
  void initState() {
    super.initState();
    _fetchPosts(); // 위젯 초기화시 게시물 가져오기

    _timer = Timer.periodic(Duration(minutes: 15), (_) {
      _fetchPosts();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // 타이머 중지
    super.dispose();
  }
  Future<void> _fetchPosts() async {
    // 게시물을 가져오는 코드를 작성합니다.
    String PartyTitlePost = '';
    String FreeTitlePost = '';
    String QATitlePost = '';

    List<dynamic> fetchedPostParty = await PartyBoard.FreeBoardScreenState()
        .fetchPosts();
    List<dynamic> fetchedPostFree = await FreeBoard.FreeBoardScreenState()
        .fetchPosts();
    List<dynamic> fetchedPostQA = await QABoard.QnABoardScreenState()
        .fetchPosts();

    // 각 리스트에서 최근 게시물이 존재할 경우, 제목을 저장 (최대 10글자까지만 저장)
    if (fetchedPostParty.isNotEmpty) {
      String title = fetchedPostParty[0]['post_title'].toString();
      PartyTitlePost =
      title.length > 10 ? '${title.substring(0, 10)}...' : title;
    }
    if (fetchedPostFree.isNotEmpty) {
      String title = fetchedPostFree[0]['post_title'].toString();
      FreeTitlePost =
      title.length > 10 ? '${title.substring(0, 10)}...' : title;
    }
    if (fetchedPostQA.isNotEmpty) {
      String title = fetchedPostQA[0]['post_title'].toString();
      QATitlePost = title.length > 10 ? '${title.substring(0, 10)}...' : title;
    }

    setState(() {
      // postTitles 리스트에 저장된 최근 게시물들을 할당
      postTitles = [
        '$PartyTitlePost',
        '$FreeTitlePost',
        '$QATitlePost',
      ];
      hasFetchedData = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '게시물',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'post',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
          ],
        ),
        Container(
          height: 120,
          width: 350,
          margin: EdgeInsets.only(left: 19, top: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Color(0xFF515151),
            ),
          ),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: postTitles.length,
            itemBuilder: (context, index) {
              String grade = '';

              if (index == 0) {
                grade = '구인구직 게시판   ';
              } else if (index == 1) {
                grade = '자유 게시판      ';
              } else if (index == 2) {
                grade = 'Q&A 게시판      ';
              }

              return InkWell(
                onTap: () {
                  if (index == 0) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>
                          PartyBoard.PartyBoardScreen()), // 'JobBoardPage'로 이동
                    );
                  } else if (index == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>
                          FreeBoard.FreeBoardScreen()), // 'FreeBoardPage'로 이동
                    );
                  } else if (index == 2) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>
                          QABoard.QnABoardScreen()), // 'QaBoardPage'로 이동
                    );
                  }
                },
                child: Container(
                  margin: EdgeInsets.only(
                      left: 16, right: 16, top: index == 0 ? 8 : 0, bottom: 8),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: grade,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: postTitles[index],
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF616161),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}



class NoticeWidget extends StatefulWidget {
  @override
  _NoticeWidgetState createState() => _NoticeWidgetState();
}
class _NoticeWidgetState extends State<NoticeWidget> {
  List<String> noticeTitles = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchNotices(); // 위젯 초기화 시 공지사항 가져오기

    _startFetchingNotices();
  }

  void _startFetchingNotices() {
    _timer = Timer.periodic(Duration(minutes: 15), (timer) {
      _fetchNotices(); // 공지사항 가져오기
    });
  }

  Future<void> _fetchNotices() async {
    // 공지사항을 가져오는 코드를 작성합니다.
    String noticeTitle1st = '';
    String noticeTitle2nd = '';
    String noticeTitle3rd = '';
    String noticeTitle4th = '';
    String noticeTitleAll = '';

    // 각 파일에서 최근 공지사항 가져오기
    List<dynamic> fetchedNotices1st = await Notice1st.NoticeTalkScreenState().fetchNotices();
    List<dynamic> fetchedNotices2nd = await Notice2nd.NoticeTalkScreenState().fetchNotices();
    List<dynamic> fetchedNotices3rd = await Notice3rd.NoticeTalkScreenState().fetchNotices();
    List<dynamic> fetchedNotices4th = await Notice4th.NoticeTalkScreenState().fetchNotices();
    List<dynamic> fetchedNoticesAll = await NoticeAll.NoticeTalkScreenState().fetchNotices();

    // 각 리스트에서 최근 공지사항이 존재할 경우, 제목을 저장 (최대 10글자까지만 저장)
    if (fetchedNotices1st.isNotEmpty) {
      String title = fetchedNotices1st[0]['post_title'].toString();
      noticeTitle1st = title.length > 10 ? '${title.substring(0, 10)}...' : title;
    }
    if (fetchedNotices2nd.isNotEmpty) {
      String title = fetchedNotices2nd[0]['post_title'].toString();
      noticeTitle2nd = title.length > 10 ? '${title.substring(0, 10)}...' : title;
    }
    if (fetchedNotices3rd.isNotEmpty) {
      String title = fetchedNotices3rd[0]['post_title'].toString();
      noticeTitle3rd = title.length > 10 ? '${title.substring(0, 10)}...' : title;
    }
    if (fetchedNotices4th.isNotEmpty) {
      String title = fetchedNotices4th[0]['post_title'].toString();
      noticeTitle4th = title.length > 10 ? '${title.substring(0, 10)}...' : title;
    }
    if (fetchedNoticesAll.isNotEmpty) {
      String title = fetchedNoticesAll[0]['post_title'].toString();
      noticeTitleAll = title.length > 10 ? '${title.substring(0, 10)}...' : title;
    }

    setState(() {
      // noticeTitles 리스트에 저장된 최근 공지사항들을 할당
      noticeTitles = [
        '$noticeTitle1st',
        '$noticeTitle2nd',
        '$noticeTitle3rd',
        '$noticeTitle4th',
        '$noticeTitleAll',
      ];
    });
  }
  @override
  void dispose() {
    _timer?.cancel(); // 위젯이 dispose될 때 타이머를 취소합니다.
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0), // 왼쪽에 여백 추가
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '공지',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'notice',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Notice()),
                );
              },
              child: Icon(
                Icons.arrow_forward_ios,
                color: Colors.black45,
                size: 16,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
            ),
          ],
        ),
        Container(
          height: 190,
          width: 350,
          margin: EdgeInsets.only(left: 19, top: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Color(0xFF515151), // 테두리 색
            ),
          ),
          child: ListView.builder(
            padding: EdgeInsets.zero, // ListView 내부의 패딩 제거
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: noticeTitles.length,
            itemBuilder: (context, index) {
              String grade = '';

              if (index == 0) {
                grade = '1학년 공지    ';
              } else if (index == 1) {
                grade = '2학년 공지    ';
              } else if (index == 2) {
                grade = '3학년 공지    ';
              } else if (index == 3) {
                grade = '4학년 공지    ';
              } else if (index == 4) {
                grade = '전체 공지     ';
              }

              return Container(
                margin: EdgeInsets.only(left: 16, right: 16, top: index == 0 ? 8 : 0, bottom: 8),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: grade,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: noticeTitles[index],
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF616161),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 16), // 원하는 크기로 설정하세요
      ],
    );
  }
}


class PercentDonut extends StatefulWidget {
  const PercentDonut({Key? key, required this.percent, required this.color})
      : super(key: key);
  final percent;
  final color;

  @override
  _PercentDonutState createState() => _PercentDonutState();
}
class _PercentDonutState extends State<PercentDonut> {
  late Future<Map<String, dynamic>> _maxScoreFuture;

  @override
  void initState() {
    super.initState();
    _maxScoreFuture = _getMaxScore();
  }

  Future<Map<String, dynamic>> _getMaxScore() async {
    final response = await http.get(
      Uri.parse('http://3.39.88.187:3000/gScore/maxScore'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final maxScoreTemp = jsonDecode(response.body);
      Map<String, dynamic> maxScore = {};
      for (var item in maxScoreTemp) {
        String categoryName = item['max_category'];
        int categoryScore = item['max_score'];
        maxScore[categoryName] = categoryScore;
      }
      return maxScore;
    } else {
      throw Exception('예외 발생');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CompletedSubject(),
      child: Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(0)), // 직각 모서리 설정
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [ Padding(
                  padding: const EdgeInsets.only(left: 16.0), // 왼쪽에 여백 추가
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '졸업인증점수',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'graduation',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                  Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MyScorePage()),
                      );
                    },
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.black45,
                      size: 16,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 25),
              Container(
                width: 200,
                height: 200,
                color: Colors.white,
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _maxScoreFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      Map<String, dynamic> maxScore = snapshot.data!;

                      return CustomPaint(
                        painter: PercentDonutPaint(
                          percentage: widget.percent,
                          activeColor: widget.color,
                          maxScore: maxScore,
                        ),
                      );
                    }
                  },
                ), //색
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PercentDonutPaint extends CustomPainter {
  final double percentage;
  final double textScaleFactor;
  final Color activeColor;
  final Map<String, dynamic> maxScore;

  PercentDonutPaint({
    required this.percentage,
    required this.activeColor,
    required this.maxScore,
    this.textScaleFactor = 1.0,
  }) : super();

  @override
  void paint(Canvas canvas, Size size) {
    if (maxScore.isEmpty) {
      return;
    }

    Paint paint = Paint()
      ..color = Color(0xfff3f3f3)
      ..strokeWidth = 15.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double radius = min(
      size.width / 2 - paint.strokeWidth / 2,
      size.height / 2 - paint.strokeWidth / 2,
    );
    Offset center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, radius, paint);

    double arcAngle = 2 * pi * percentage;
    paint.color = activeColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      arcAngle,
      false,
      paint,
    );

    int maxScores = maxScore['총점'] ?? 0;
    drawText(
      canvas,
      size,
      "${(percentage * 1000).round()} / $maxScores",
    );
  }

  void drawText(Canvas canvas, Size size, String text) {
    double fontSize = getFontSize(size, text);

    TextSpan sp = TextSpan(
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      text: text,
    );
    TextPainter tp = TextPainter(text: sp, textDirection: TextDirection.ltr);

    tp.layout();
    double dx = size.width / 2 - tp.width / 2;
    double dy = size.height / 2 - tp.height / 2;

    Offset offset = Offset(dx, dy);
    tp.paint(canvas, offset);
  }

  double getFontSize(Size size, String text) {
    return size.width / text.length * textScaleFactor;
  }

  @override
  bool shouldRepaint(PercentDonutPaint oldDelegate) {
    return true;
  }
}