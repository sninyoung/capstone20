/*
import 'package:flutter/material.dart';
import 'dart:core';
import 'package:capstone/drawer.dart';

*/
/*void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Guide(),
    );
  }
}*//*


class Guide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '이수과목',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xffC1D3FF),
        centerTitle: true,
        elevation: 0.0,
      ),
      drawer: MyDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 졸업가이드 title
            Container(
              alignment: Alignment.centerLeft,
              height: 120,
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Color(0xffffffff),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '졸업가이드',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 26.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(
                    height: 8.0,
                  ),
                  const Text(
                    'completion guide',
                    style: TextStyle(
                      color: Color(0xff858585),
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            GuideHomePage(),
          ],
        ),
      ),
    );
  }
}

class GuideHomePage extends StatelessWidget {
  final List<String> comments = <String>[
    '19~22학번 전공기초과목',
    '19~22학번 전공선택과목',
    '23학번 융합과정',
    '23학번 전공기초과목',
    '23학번 전공선택과목',
  ];


  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        return Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text('${comments[index]}'),
              ),
              ButtonBar(
                children: <Widget>[
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black87,
                    ),
                    child: Text('상세정보'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('상세 정보'),
                            content: Text(comments[index]),
                            actions: [
                              TextButton(
                                child: Text('닫기'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }
}

*/
