import "package:flutter/material.dart";

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
            '한남대학교 컴퓨터공학과',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black,),
          ),
          centerTitle: true,
          backgroundColor: Color(0xffC1D3FF),
        ),
        backgroundColor: Colors.white,

        body: Column(
          children: [
            SizedBox(height: 10),
            Container(
              height: 90.0,
              child: Center(
                child: Text(
                  '공지사항',
                  style: TextStyle(
                    fontSize: 30.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              padding: EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: Colors.black, width: 0.3),
              ),
            ),

            Expanded(
              child: Container(
                child: Center(
                  child: Expanded(
                    child: Column(
                      children: [
                        Container(
                          //color: Colors.lightBlue,
                          height: 70,
                          width: double.infinity,
                          margin: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xffE6E6E6)
                              )
                            )
                          ),
                          child: Text(
                            '전체 공지',
                            style: TextStyle(
                              fontSize: 30,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          //color: Colors.lightBlue,
                          height: 70,
                          width: double.infinity,
                          margin: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: Color(0xffE6E6E6)
                                  )
                              )
                          ),
                          child: Text(
                            '1학년 공지',
                            style: TextStyle(
                              fontSize: 30,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          //color: Colors.lightBlue,
                          height: 70,
                          width: double.infinity,
                          margin: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: Color(0xffE6E6E6)
                                  )
                              )
                          ),
                          child: Text(
                            '2학년 공지',
                            style: TextStyle(
                              fontSize: 30,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          //color: Colors.lightBlue,
                          height: 70,
                          width: double.infinity,
                          margin: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: Color(0xffE6E6E6)
                                  )
                              )
                          ),
                          child: Text(
                            '3학년 공지',
                            style: TextStyle(
                              fontSize: 30,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),Container(
                          //color: Colors.lightBlue,
                          height: 70,
                          width: double.infinity,
                          margin: EdgeInsets.all(10.0),
                          child: Text(
                            '4학년 공지',
                            style: TextStyle(
                              fontSize: 30,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                padding: EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.black, width: 0.3),
                ),
              ),
            ),

            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}