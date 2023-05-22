import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:capstone/drawer.dart';

void main() {
  runApp(MaterialApp(
    title: '2학년 공지',
    home: NoticeTalkScreen_2(boardId: 6),
  ));
}

class NoticeTalkScreen_2 extends StatefulWidget {
  final int boardId;
  const NoticeTalkScreen_2({Key? key, required this.boardId}) : super(key: key);

  @override
  NoticeTalkScreenState createState() => NoticeTalkScreenState();
}



class NoticeTalkScreenState extends State<NoticeTalkScreen_2> {
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
        MaterialPageRoute(builder: (context) => NoticeTalkScreen_2(boardId: widget.boardId)),
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
        .get(Uri.parse('http://3.39.88.187:3000/post/posts?board_id=6'));

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
            '컴퓨터공학과 2학년 공지',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black,),
          ),
          centerTitle: true,
          backgroundColor: Color(0xffC1D3FF),
        ),
        drawer: MyDrawer(),
        backgroundColor: Colors.white,//여기까진 고정

        body: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: notices,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final notices = snapshot.data!;
                    return ListView.builder(
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
        )
    );
  }

  Widget buildNoticeItem(BuildContext context, dynamic post) {
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            color: Colors.white,
            border: Border.all(
              width: 2,
              color: Colors.grey.withOpacity(0.5),
            ),
          ),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('yyyy-MM-dd HH:mm:ss')
                        .format(DateTime.parse(post['post_date'])),
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
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
          margin: EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: <Widget>[
              Flexible(
                child: TextField(
                  controller: _titleController,//컨트롤러 연결
                  decoration: InputDecoration.collapsed(hintText: '메시지 보내기'),
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.0),
                child:
                IconButton(
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
