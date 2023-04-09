import 'package:flutter/material.dart';
import 'package:capstone/screens/gScore/gscore_modify_screen.dart';
import 'package:capstone/screens/gScore/gscore_regist_screen.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

//신청글 목록 창
final client = HttpClient();


void main() {
  runApp(MaterialApp(
    title: '졸업점수 신청 목록',
    home: GScoreForm(),
  ));
}


class GScoreForm extends StatefulWidget {
  @override
  _GScoreForm createState() => _GScoreForm();
}

class _GScoreForm extends State<GScoreForm> {
  //late Future<List<dynamic>> _posts;
  late Future<dynamic> _posts;
  @override
  void initState() {
    super.initState();
    checkUserLoginStatus();
    _posts = _fetchPosts();

  }


  void checkUserLoginStatus() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      Navigator.pop(context);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('알림'),
            content: Text('해당 기능은 로그인 후 이용이 가능합니다.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('확인'),
              ),
            ],
          );
        },
      );

    }

  }


  /* //권한따라 다른 게시글 불러오기
  Future<List<dynamic>> _fetchAllPosts() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    print(token);
    if (token != null) {
      final response = await http.get(
        Uri.parse('http://3.39.88.187:3000/gScore/testapi'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token', //
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load posts');
      }
    } else {
      throw Exception('Token is null');
    }
  }
  */

  //일단은 전체게시글
  Future<List<dynamic>> _fetchPosts() async {
    final response = await http
        .get(Uri.parse('http://3.39.88.187:3000/gScore/'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Widget _buildPostItem(BuildContext context, dynamic post) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GScoreApcCt(post: post),
          ),
        );
        setState(() {
          //final _posts = _fetchPosts();
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          width: 200.0,
          height: 100.0,
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            color: Colors.white,
            border: Border.all(
              width: 2,
              color: Colors.grey.withOpacity(0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: MediaQuery.of(context).size.width * 0.08,
                alignment: Alignment.center,
                child: Text(post['gspost_id'].toString(),
                  style: TextStyle(
                    fontSize: 14.0,
                  ),
                ),
              ),
              Container(width: MediaQuery.of(context).size.width * 0.16,
                alignment: Alignment.center,
                child: Text(

                  DateTime.parse(post['gspost_post_date']).toLocal().toString().substring(2, 10),
                  style: TextStyle(
                    fontSize: 14.0,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(width: MediaQuery.of(context).size.width * 0.30,
                alignment: Alignment.center,
                child: Text(
                  post['gspost_category'].toString(),
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey,
                  ),
                ),
              ),
              Container(width: MediaQuery.of(context).size.width * 0.13,
                alignment: Alignment.center,
                child: Text(
                  post['gspost_score'].toString(),
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey,
                  ),
                ),
              ),
              Container(width: 18,),
              Container(width: MediaQuery.of(context).size.width * 0.1,
                alignment: Alignment.center,
                child: Text(
                  post['gspost_pass'].toString(),
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Container(
            color: Color(0xffC1D3FF),
            child: Text(
              '  졸업인증점수 신청/관리  ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ),
          centerTitle: true,
        ),
        body:Column(children: [
          Container(height: MediaQuery.of(context).size.height * 0.01),
          Container(
              padding: EdgeInsets.all(16.0), // 상하좌우 16.0씩 padding 적용
              width: MediaQuery.of(context).size.width * 0.97,
              height: MediaQuery.of(context).size.height * 0.2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.black,
                  width: 2,
                ),
              ),
              child: Row(
                  children:[
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 13.0, color: Colors.black),
                        children: <TextSpan>[
                          TextSpan(text: '1. 각 항목별 점수를 확인해주세요.\n'),
                          TextSpan(text: '2. TOPCIT 점수는 수기 입력을 통해 계산됩니다. \n', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: '3. 인턴쉽, 해외연수 50일 이상의 점수는\n    캘린더의 시작일, 종료일로 계산됩니다.'),
                        ],
                      ),
                    )

                  ]
              )

          ),
          Container(
              height: MediaQuery.of(context).size.height * 0.01
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.60,
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GScoreApc()),
                  );
                },
                child: Text(
                  '신청',
                  style: TextStyle(fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xffC1D3FF),
                  fixedSize: Size(width * 0.08, height * 0.055),
                ),
              ),
              Container(
                  width: MediaQuery.of(context).size.width * 0.05
              )
            ],
          ),
          Container(
              height: MediaQuery.of(context).size.height * 0.01
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.97,
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16.0), // 상하좌우 16.0씩 padding 적용
                  width: double.infinity,
                  height: 50,
                  child: Row(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.1,
                        alignment: Alignment.center,
                        child: Text(
                          "No.",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(width: 10,),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.14,
                        alignment: Alignment.center,
                        child: Text(
                          "신청일",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.3,
                        alignment: Alignment.center,
                        child: Text(
                          "활동종류",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.16,
                        alignment: Alignment.center,
                        child: Text(
                          "점수",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.13,
                        alignment: Alignment.center,
                        child: Text(
                          "신청상태",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(10.0), // 상하좌우 10.0씩 padding 적용
                    child: FutureBuilder<dynamic>(
                      future: _posts,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final posts = snapshot.data!;
                          return ListView.builder(
                            itemCount: posts.length,
                            itemBuilder: (context, index) {
                              return _buildPostItem(context, posts[index]);
                            },
                          );
                        } else if (snapshot.hasError) {
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
                ),
              ],
            ),
          ),

        ],
        )
    );
  }
}