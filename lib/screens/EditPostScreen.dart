import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EditPostScreen extends StatefulWidget {
  final dynamic post;

  EditPostScreen({required this.post});

  @override
  _EditPostScreenState createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  TextEditingController _titleController = TextEditingController();
  TextEditingController _contentController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _errorMessage = '';
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    _titleController.text = widget.post['post_title'];
    _contentController.text = widget.post['post_content'];
  }

  Future<void> updatePost() async {

    print('updatePost button clicked'); // 로그 추가

    setState(() => _isLoading = true);

    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '토큰이 없습니다.';

      });
      return;
    }


    final Map<String, dynamic> postData = {
      'post_title': _titleController.text,
      'post_content': _contentController.text,

    };

    final response = await http.post(
      Uri.parse('http://3.39.88.187:3000/post/updatepost?post_id=${widget.post['post_id']}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
      body: jsonEncode(postData),
    );

    setState(() => _isLoading = false); // 버튼 활성화
    if (response.statusCode == 200) {
      // 글 수정이 성공했을 경우
      Navigator.pop(
        context,
        {
          'post_title': _titleController.text,
          'post_content': _contentController.text,
        },
      );
    } else {
      // 글 수정이 실패했을 경우
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('글 수정 실패'),
            content: Text('수정 권한이 없습니다.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('확인'),
              ),
            ],
          );
        },
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('글 수정'),
        backgroundColor: Color(0xffC1D3FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(hintText: '제목'),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(hintText: '내용'),
              maxLines: null,
            ),
            SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: _isLoading ? null : updatePost, // 버튼 활성화 여부 설정
              style: ElevatedButton.styleFrom(
                primary: Color(0xffC1D3FF), // 이 색상 코드를 변경하면 됩니다.
              ),
              child: _isLoading ? CircularProgressIndicator() : Text(
                  '저장'), // 로딩 중일 때는 로딩 아이콘을 보여줌
            ),
          ],
        ),
      ),
    );
  }

}