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
import 'package:capstone/screens/post/free_board.dart' as FreeNotice;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Scrollbar(
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
                PercentDonut(percent: percentage, color: Color(0xffC1D3FF)),
                Divider( // 추가: 실선
                  color: Colors.grey,
                  thickness: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NoticeWidget extends StatefulWidget {
  @override
  _NoticeWidgetState createState() => _NoticeWidgetState();
}
class _NoticeWidgetState extends State<NoticeWidget> {
  List<String> noticeTitles = [];

  @override
  void initState() {
    super.initState();
    _fetchNotices(); // 위젯 초기화시 공지사항 가져오기
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

    await Future.delayed(Duration(seconds: 2));

    // 각 리스트에서 최근 공지사항이 존재할 경우, 제목을 저장 (최대 10글자까지만 저장)
    if (fetchedNotices1st.isNotEmpty) {
      String title = fetchedNotices1st[0]['post_title'].toString();
      noticeTitle1st = title.length > 10 ? '${title.substring(0, 10)}...' : title;
      noticeTitles.add(noticeTitle1st);
    }
    if (fetchedNotices2nd.isNotEmpty) {
      String title = fetchedNotices2nd[0]['post_title'].toString();
      noticeTitle2nd = title.length > 10 ? '${title.substring(0, 10)}...' : title;
      noticeTitles.add(noticeTitle2nd);
    }
    if (fetchedNotices3rd.isNotEmpty) {
      String title = fetchedNotices3rd[0]['post_title'].toString();
      noticeTitle3rd = title.length > 10 ? '${title.substring(0, 10)}...' : title;
      noticeTitles.add(noticeTitle3rd);
    }
    if (fetchedNotices4th.isNotEmpty) {
      String title = fetchedNotices4th[0]['post_title'].toString();
      noticeTitle4th = title.length > 10 ? '${title.substring(0, 10)}...' : title;
      noticeTitles.add(noticeTitle4th);
    }
    if (fetchedNoticesAll.isNotEmpty) {
      String title = fetchedNoticesAll[0]['post_title'].toString();
      noticeTitleAll = title.length > 10 ? '${title.substring(0, 10)}...' : title;
      noticeTitles.add(noticeTitleAll);
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

    // initState()를 다시 호출하여 build() 메서드가 다시 실행되도록 합니다.
    initState();
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
          height: 150,
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


class PercentDonut extends StatelessWidget {
  const PercentDonut({Key? key, required this.percent, required this.color})
      : super(key: key);
  final percent;
  final color;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              child: CustomPaint(
                painter: PercentDonutPaint(
                  percentage: percent,
                  activeColor: color, //색
                ),
              ),
            )

          ],
        ),
      ),
    );
  }
}

class PercentDonutPaint extends CustomPainter {
  double percentage;
  double textScaleFactor = 1.0; // 파이 차트에 들어갈 텍스트 크기를 정합니다.
  Color activeColor;
  PercentDonutPaint({required this.percentage, required this.activeColor});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint() // 화면에 그릴 때 쓸 Paint를 정의합니다.
      ..color = Color(0xfff3f3f3)
      ..strokeWidth = 15.0 // 선의 길이를 정합니다.
      ..style =
          PaintingStyle.stroke // 선의 스타일을 정합니다. stroke면 외곽선만 그리고, fill이면 다 채웁니다.
      ..strokeCap =
          StrokeCap.round; // stroke의 스타일을 정합니다. round를 고르면 stroke의 끝이 둥글게 됩니다.
    double radius = min(
        size.width / 2 - paint.strokeWidth / 2,
        size.height / 2 -
            paint.strokeWidth / 2); // 원의 반지름을 구함. 선의 굵기에 영향을 받지 않게 보정함.
    Offset center =
    Offset(size.width / 2, size.height / 2); // 원이 위젯의 가운데에 그려지게 좌표를 정함.
    canvas.drawCircle(center, radius, paint); // 원을 그림.
    double arcAngle = 2 * pi * percentage; // 호(arc)의 각도를 정함. 정해진 각도만큼만 그리도록 함.
    paint.color = activeColor; // 호를 그릴 때는 색을 바꿔줌.
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),-pi / 2,
        arcAngle, false, paint); // 호(arc)를 그림.

    drawText(canvas, size, "${(percentage*1000).round()} / 1000"); // 텍스트를 화면에 표시함.
  }

  // 원의 중앙에 텍스트를 적음.
  void drawText(Canvas canvas, Size size, String text) {
    double fontSize = getFontSize(size, text);

    TextSpan sp = TextSpan(
        style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.black),
        text: text); // TextSpan은 Text위젯과 거의 동일하다.
    TextPainter tp = TextPainter(text: sp, textDirection: TextDirection.ltr);

    tp.layout(); // 필수! 텍스트 페인터에 그려질 텍스트의 크기와 방향를 정함.
    double dx = size.width / 2 - tp.width / 2;
    double dy = size.height / 2 - tp.height / 2;

    Offset offset = Offset(dx, dy);
    tp.paint(canvas, offset);
  }

  // 화면 크기에 비례하도록 텍스트 폰트 크기를 정함.
  double getFontSize(Size size, String text) {
    return size.width / text.length * textScaleFactor;
  }

  @override
  bool shouldRepaint(PercentDonutPaint oldDelegate) {
    return true;
  }
}
