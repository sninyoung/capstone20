import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/screens/post/EditPostScreen.dart';

class PostScreen extends StatefulWidget {
  final dynamic post;

  PostScreen({required this.post});

  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  late Future<List<dynamic>> comments;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _errorMessage = '';
  bool _isLoading = false;
  TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    comments = fetchComments();
  }

  //댓글 가져오기
  Future<List<dynamic>> fetchComments() async {
    final response = await http.get(Uri.parse(
        'http://3.39.88.187:3000/post/comment:?post_id=${widget.post['post_id']}'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load posts');
    }
  }

  //댓글 입력
  Future<void> postComment(int postId, String content) async {
    final url = Uri.parse('http://3.39.88.187:3000/post/commentwrite/${widget.post['post_id']}');
    setState(() => _isLoading = true);
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '토큰이 없습니다.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글 입력에 실패했습니다.(로그인 만료)')));
      });
      return;
    }
    final response = await http.post(
      url,
      headers: <String, String>{ //헤더파일 추가
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
      body: jsonEncode( {
        'comment_content': content,
      }),
    );
    if (response.statusCode == 201) {
      // 입력 성공 처리
      // 예시:
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글이 성공적으로 입력되었습니다.')));
      _commentController.clear(); // 댓글 입력 완료 후, TextField를 초기화합니다.
      setState(() {
        comments = fetchComments(); // 댓글 리스트를 다시 불러옵니다.
      });
    } else {
      // 실패 처리
      // 예시:
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글 입력에 실패했습니다.')));
    }
  }

  //댓글 삭제
  Future<void> _deleteComment(int commentId) async {
    final url = Uri.parse('http://3.39.88.187:3000/post/deletecomment/$commentId');
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    print(token);
    if (token == null) {
      setState(() {
        _errorMessage = '토큰이 없습니다.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글 삭제에 실패했습니다.(로그인 만료)')));
      });
      return;
    }
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글이 삭제되었습니다.')));
      setState(() {
        comments = fetchComments();
      });
    }
    else if (response.statusCode == 300){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제 권한이 없습니다.')));
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글 삭제에 실패했습니다.')));
    }
  }


  void _navigateToEditPostScreen() async{
    setState(() => _isLoading = true);
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '토큰이 없습니다.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('게시글 수정에 실패 했습니다.(로그인 만료)')));
      });
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPostScreen(
          post: widget.post,
        ),
      ),
    ).then((value) {
      // Refresh post data after editing
      setState(() {
        widget.post['post_title'] = value['post_title'];
        widget.post['post_content'] = value['post_content'];
      });
    });
  }
  Future<void> deletePost() async {

    setState(() => _isLoading = true);
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    print(token);
    if (token == null) { //토쿤
      setState(() {
        _isLoading = false;
        _errorMessage = '토큰이 없습니다.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('게시글 삭제에 실패했습니다. (로그인 만료)')));
      });
      return;
    }

    final response = await http.post(
      Uri.parse('http://3.39.88.187:3000/post/deletepost/${widget.post['post_id']}'),
      headers: <String, String>{ //헤더파일 추가
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
    );
    if (response.statusCode == 200) {
      print('게시물 삭제 완료');
    } else {
      throw Exception('Failed to delete post');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.post['post_title'],
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xffC1D3FF),
        centerTitle: true,
        elevation: 0.0,
        actions: [
          IconButton(
            onPressed: _navigateToEditPostScreen,
            icon: Icon(Icons.edit),
          ),
          IconButton(
            onPressed: () async {
              await deletePost();
              Navigator.pop(context);
            },
            icon: Icon(Icons.delete),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.0),
            Text(
              widget.post['post_content'],
              style: TextStyle(
                fontSize: 16.0,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                widget.post['board_id'] == 1 ?
                Text(
                  widget.post['student_id'].toString().substring(2, 4) + '학번',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey,
                  ),
                ) :
                Text(
                  widget.post['student_id'].toString(),
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm:ss')
                      .format(DateTime.parse(widget.post['post_date'])),
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.0),
            Divider(
              height: 1.0,
              thickness: 1.0,
              color: Colors.grey[400],
              indent: 0.0,
              endIndent: 0.0,
            ),
            SizedBox(height: 16.0),
            FutureBuilder<List<dynamic>>(
              future: comments,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        '등록된 댓글이 없습니다.',
                        style: TextStyle(
                          fontSize: 16.0,
                        ),
                      ),
                    );
                  } else {
                    return Expanded(
                      child: ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                widget.post['board_id'] == 1 ?
                                Text(
                                  snapshot.data![index]['student_id']
                                      .toString()
                                      .substring(2, 4) +
                                      '학번',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ) :
                                Text(
                                  snapshot.data![index]['student_id']
                                      .toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        snapshot.data![index]['comment_content'].toString(),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.cancel_outlined),
                                      iconSize: 18,
                                      color: Colors.grey,
                                      onPressed: () => _deleteComment(snapshot.data![index]['comment_id']),
                                    ),
                                  ],
                                ),
                                Text(
                                  DateFormat('yyyy-MM-dd HH:mm:ss').format(
                                      DateTime.parse(snapshot.data![index]
                                      ['comment_date'])),
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.grey,
                                  ),
                                ),
                                Divider(),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  }
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '댓글을 불러오는 중 오류가 발생했습니다. ${snapshot.error}',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.red,
                      ),
                    ),
                  );
                }
                return Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 64.0,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: '댓글을 입력해주세요.',
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  if (_commentController.text.isNotEmpty) {
                    final content = _commentController.text;
                    final postId = widget.post['post_id'];
                    postComment(postId, content);
                  }
                },
                icon: Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
