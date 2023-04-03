import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MaterialApp(
    title: '전체 공지방',
    home: Notice_Talk(),
  ));
}

class Notice_Talk extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notice_talk',
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

Future<List<dynamic>> fetchTalks() async {
  final response = await http.get(Uri.parse('http://3.39.88.187:3000/notice_talk/write'));
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load notice');
  }
}


class _ChatScreenState extends State<ChatScreen> {
  late Future<List<dynamic>> _talks;  //???

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '컴퓨터공학과 전체 공지',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black,),
        ),
        centerTitle: true,
        backgroundColor: Color(0xffC1D3FF),
      ),
      backgroundColor: Colors.white,//여기까진 고정


      body: Column(
        children: <Widget>[
          Flexible(
            child: ListView.builder(
              //itemCount: _talks.length,
              reverse: true,  //최근글이 아래쪽으로 오도록
              itemBuilder: (BuildContext context, int index) {
                final Message message = _talks[index];
                final bool isMe = message.sender == currentUser;

                return _buildMessage(message, isMe);
              },
            ),
          ),
          Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).accentColor),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            Flexible(
              child: TextField(
                controller: _textController, // _textController 할당
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration.collapsed(hintText: '메시지 보내기'),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: Icon(Icons.send),
                onPressed: () {
                  _handleSubmitted(_textController.text); // clear() 함수 호출 추가
                  _textController.clear(); // TextField의 글자 지우기
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _handleSubmitted(String text) {
    _textController.clear(); // TextField 내용 지우기
    setState(() {
      final message = Message(
        text: text,
        sender: currentUser,
        time: DateFormat('yyyy-MM-dd kk:mm:ss').format(DateTime.now()),
        isLiked: false,
        unread: true,
      );
      _messages.insert(0, message);
    });
  }


  Widget _buildMessage(Message message, bool isMe) {
    final Container msg = Container(
        margin: isMe
        ? EdgeInsets.only(
        top: 8.0,
        bottom: 8.0,
        left: 80.0,
        )
        : EdgeInsets.only(
        top: 8.0,
        bottom: 8.0,
        ),
        padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
        decoration: BoxDecoration(
        color: isMe ? Colors.blue[100] : Colors.grey[200],
        borderRadius: isMe
        ? BorderRadius.only(
        topLeft: Radius.circular(15.0),
        bottomLeft: Radius.circular(15.0),
        )
        : BorderRadius.only(
        topRight: Radius.circular(15.0),
        bottomRight: Radius.circular(15.0),
        ),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
        Text(
          message.sender,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.0),
        Text(
          message.text,
          style: TextStyle(
          color: Colors.grey[800],
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
          ),
        ),
        SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              message.time,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.0,
                fontWeight: FontWeight.normal,
              ),
            ),
          message.isLiked
              ? Icon(
            Icons.favorite,
            color: Colors.red,
            size: 16.0,
            )
              : SizedBox.shrink(),
          ],
        ),
    ],
    ));

    if (isMe) {
      return msg;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            child: Text(
              message.sender[0],
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.blue,
          ),
        ),
        msg,
      ],
    );
  }

  final TextEditingController _textController = TextEditingController();
  final String currentUser = notice_talk['name'];
}

class Message {
  final String text;
  final String sender;
  final String time;
  final bool isLiked;
  final bool unread;

  Message({
    required this.text,
    required this.sender,
    required this.time,
    required this.isLiked,
    required this.unread,
  });

  factory Message.fromJson
}