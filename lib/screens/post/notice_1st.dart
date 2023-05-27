import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:capstone/drawer.dart';

void main() {
  runApp(MaterialApp(
    title: '1학년 공지',
    home: NoticeTalkScreen_1(boardId: 3),
  ));
}

class ChatBubble extends CustomPainter {
  final Color color;
  final Alignment alignment;

  ChatBubble({
    required this.color,
    required this.alignment,
  });

  var _radius = 10.0;
  var _x = 10.0;
  var _y = 20.0;
  var _borderWidth = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    var path = Path();
    path.addRRect(
      RRect.fromLTRBAndCorners(
        _x,
        0,
        size.width,
        size.height,
        bottomRight: Radius.circular(_radius),
        bottomLeft: Radius.circular(_radius),
        topRight: Radius.circular(_radius),
        topLeft: Radius.circular(_radius),
      ),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = this.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _borderWidth,
    );
    var clipPath = Path();
    clipPath.moveTo(0, 0);//여기가 최좌단 꼭짓점
    clipPath.lineTo(_x, (size.height/10));
    clipPath.lineTo(_x, _y);//위쪽 꼭짓점
    canvas.clipPath(clipPath);
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        0,
        0.0,
        _x,
        size.height,
        topRight: Radius.circular(_radius),
      ),
      Paint()
        ..color = this.color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class NoticeTalkScreen_1 extends StatefulWidget {
  final int boardId;
  const NoticeTalkScreen_1({Key? key, required this.boardId}) : super(key: key);

  @override
  NoticeTalkScreenState createState() => NoticeTalkScreenState();
}



class NoticeTalkScreenState extends State<NoticeTalkScreen_1> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _titleController = TextEditingController();
  TextEditingController _noticeController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  late Future<List<dynamic>> notices;

  @override
  void dispose() {
    _titleController.dispose();
    _noticeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    studentinfo();
    notices = fetchNotices();
  }

  //권한받아오기
  int? _permission;
  void studentinfo() async {
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
        _permission = responseData[0]['permission'];
        _isLoading = false;//임의추가
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


  //글 작성
  void _submitForm() async {
    if (_formKey.currentState?.validate() == false) return;

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

    final Map<String, dynamic> postData = {
      'board_id': widget.boardId,
      'post_title': _titleController.text,
      'post_content': '',
      'post_file': 'null', // TODO: Implement file uploading
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => NoticeTalkScreen_1(boardId: widget.boardId)),
      );
    }
    else {
      // Failure
      final responseData = jsonDecode(response.body);
      setState(() {
        _isLoading = false;
        _errorMessage = responseData['message'];
      });
    }
  }


  //서버로부터 게시글 목록을 가져옴
  Future<List<dynamic>> fetchNotices() async {
    final response = await http
        .get(Uri.parse('http://3.39.88.187:3000/post/posts?board_id=5'));

    if (response.statusCode == 200) {
      final List<dynamic> notice = jsonDecode(response.body);

      return notice;
    }
    else {
      throw Exception('Failed to load notices');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            '1학년 공지',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white
            ),
          ),
          centerTitle: true,
          backgroundColor: Color(0xffC1D3FF),
        ),
        drawer: MyDrawer(),
        backgroundColor: Colors.white,//여기까진 고정

        body: Container(
          padding: EdgeInsets.only(top: 10), // 패딩 조정
          child: Column(
            children: [
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: notices,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final notices = snapshot.data!;
                      return ListView.builder(
                        reverse: true,
                        itemCount: notices.length,
                        itemBuilder: (BuildContext context, int index) {
                          dynamic notice = notices[index];
                          return buildNoticeItem(context, notice);//, token
                        },
                      );
                    }
                    else if (snapshot.hasError) {
                      return Center(
                        child: Text('${snapshot.error}'),
                      );
                    }
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                ),
              ),
              Container(
                child: buildTextComposer(),//메시지 입력창
              )
            ],
          ),
        )
    );
  }

  Widget buildNoticeItem(BuildContext context, dynamic post) {
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20.0),
          child: CustomPaint(
            painter: ChatBubble(
              color: Color(0xffC1D3FF),
              alignment: Alignment.topLeft,
            ),
            child: Container(
              padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0), // 패딩 조정
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post['post_title'],
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(post['post_date'])),
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.end, // 날짜 오른쪽 정렬
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextComposer() {
    if (_permission == 1) {
      return SizedBox.shrink();
    }
    else {
      return IconTheme(
        data: IconThemeData(color: Theme.of(context).accentColor),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.black12,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: <Widget>[
              Flexible(
                child: TextField(
                  maxLines: null,
                  controller: _titleController,//컨트롤러 연결
                  decoration: InputDecoration.collapsed(hintText: '메시지 보내기'),
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(
                          color: Colors.black12,
                          width: 0.5,
                        )
                    )
                ),
                child: IconButton(
                    icon: Icon(Icons.send),
                    onPressed: _isLoading ? null : () {
                      _submitForm();
                      _noticeController.clear();//입력한 텍스트 초기화
                    }
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}



