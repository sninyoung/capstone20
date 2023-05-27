import 'package:capstone/screens/post/notice_all.dart';
import 'package:capstone/screens/post/notice_1st.dart';
import 'package:capstone/screens/post/notice_2nd.dart';
import 'package:capstone/screens/post/notice_3rd.dart';
import 'package:capstone/screens/post/notice_4th.dart';
import "package:flutter/material.dart";
import 'package:capstone/drawer.dart';

void main() {
  runApp(MaterialApp(
    title: '공지 알림톡',
    home: Notice(),
  ));
}

class Notice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOTICE_HOME',
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            '컴퓨터공학과',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Color(0xffC1D3FF),
        ),
        drawer: MyDrawer(),
        backgroundColor: Colors.white,

        body: Column(
          children: [
            SizedBox(height: 10),
            // Container(
            //   height: 90.0,
            //   child: Center(
            //     child: Text(
            //       '공 지 사 항',
            //       style: TextStyle(
            //         fontSize: 30.0,
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //   ),
            //   margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
            //   padding: EdgeInsets.all(20.0),
            //   decoration: BoxDecoration(
            //     color: Colors.white,
            //     borderRadius: BorderRadius.circular(10.0),
            //     border: Border.all(color: Colors.black, width: 1.0),
            //   ),
            // ),
            //여기까지 공지사항 윗박스

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NoticeTalkScreen(boardId: 3)),//boardId: 3
                      );
                    },
                    child: Text(
                      '전체공지',
                      style: TextStyle(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      backgroundColor: Color(0xffC1D3FF),
                    ),
                  ),
                  SizedBox(height: 20.0),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NoticeTalkScreen_1(boardId: 5)),//여기수정
                      );
                    },
                    child: Text(
                      '1학년 공지',
                      style: TextStyle(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      backgroundColor: Color(0xffC1D3FF),
                    ),
                  ),
                  SizedBox(height: 20.0),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NoticeTalkScreen_2(boardId: 6)),//여기수정
                      );
                    },
                    child: Text(
                      '2학년 공지',
                      style: TextStyle(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      backgroundColor: Color(0xffC1D3FF),
                    ),
                  ),
                  SizedBox(height: 20.0),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NoticeTalkScreen_3(boardId: 7)),//여기수정
                      );
                    },
                    child: Text(
                      '3학년 공지',
                      style: TextStyle(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      backgroundColor: Color(0xffC1D3FF),
                    ),
                  ),
                  SizedBox(height: 20.0),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NoticeTalkScreen_4(boardId: 8)),//여기수정
                      );
                    },
                    child: Text(
                      '4학년 공지',
                      style: TextStyle(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      backgroundColor: Color(0xffC1D3FF),
                    ),
                  ),
                  SizedBox(height: 20.0),
                ],
              ),
            ),

            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}