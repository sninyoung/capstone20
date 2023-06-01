import 'package:flutter/material.dart';

void main() {
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
}

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

  final List<IconData> icons = <IconData>[
    Icons.music_note,
    Icons.music_video,
    Icons.library_music,
    Icons.videocam,
    Icons.video_library
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
                leading: Icon(
                  icons[index],
                  color: Colors.redAccent,
                ),
                title: Text('${comments[index]}'),
              ),
              ButtonBar(
                children: <Widget>[
                  TextButton(
                    style: TextButton.styleFrom(
                      primary: Colors.black87,
                    ),
                    child: Text('보러가기'),
                    onPressed: () {},
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

class MyDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Drawer Header',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            title: Text('Item 1'),
            onTap: () {},
          ),
          ListTile(
            title: Text('Item 2'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
