import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import 'package:capstone/screens/gScore/gscore_list_screen.dart';
import 'package:capstone/screens/gScore/gscore_self_calc_screen.dart';

void main() {
  runApp(MaterialApp(
    title: '나의 졸업인증 점수',
    home: MyScorePage(),
  ));
}

class MyScorePage extends StatefulWidget {
  @override
  State<MyScorePage> createState() => _MyScorePage();
}

class _MyScorePage extends State<MyScorePage> with TickerProviderStateMixin {
  final FlutterSecureStorage storage = FlutterSecureStorage();
  int sumScore = 0;
  String leftScore = '';
  int a = 0;
  int i =0;

  Future<List<Map<String, dynamic>>> _getMaxScores() async {
    final response = await http.get(Uri.parse('http://3.39.88.187:3000/gScore/maxScore'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      List<Map<String, dynamic>> maxScores = [];
      data.forEach((item) {
        final maxCategory = item['max_category'] as String;
        final maxScore = item['max_score'] as int;
        maxScores.add({
          maxCategory: maxScore,
        });
      });
      return maxScores;
    } else {
      throw Exception('Failed to load max scores');
    }
  }


  Future<void> _getUserInfo() async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      return;
    }

    final maxScores = await _getMaxScores(); // _getMaxScores 호출하여 결과를 maxScores 변수에 할당
    print(maxScores);
    final response = await http.get(
      Uri.parse('http://3.39.88.187:3000/gScore/user'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      final user = jsonDecode(response.body);
      final allScoreTemp = user['graduation_score'];
      final allScore = jsonDecode(allScoreTemp);

      allScore.forEach((key, value) {
        if (maxScores.any((score) => score.containsKey(key))) {
          final maxScore = maxScores.firstWhere((score) => score.containsKey(key))[key] as int;
          if (value > maxScore) {
            allScore[key] = maxScore;
          }
        }
      });
      allScore.forEach((key, value){
        sumScore += value as int;
      });
    }
    a = 1000 - sumScore;
    if(a < 0){
      leftScore = '졸업이 가능해요 축하해요';
    }else{
      leftScore = '${a}점 남았어요 화이팅';
    }
    setState(() {
      sumScore;
      leftScore;
    });
  }



  @override
  void initState() {
    super.initState();
    _getUserInfo();
    _getMaxScores();
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 23),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            '내 졸업인증점수',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Color(0xffC1D3FF),
        ),
        body: SingleChildScrollView(
         child: Center(
            child: Column(
              children: [
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.013,
                  right: MediaQuery.of(context).size.width * 0.035,
                  bottom: MediaQuery.of(context).size.height * 0.01,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SelfCalcScreen()),
                        );
                      },
                      child: Text(
                        '셀프 계산기',
                        style: TextStyle(fontSize: 20),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        backgroundColor: Color(0xffC1D3FF),
                      ),
                    ),
                    SizedBox(width: 10), // Add a space between the two buttons
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => GScoreForm()),
                        );
                      },
                      child: Text(
                        '신청 목록',
                        style: TextStyle(fontSize: 20),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        backgroundColor: Color(0xffC1D3FF),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                constraints: BoxConstraints(maxWidth: 370, maxHeight: 550),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  color: Colors.white,
                  border: Border.all(
                    width: 2,
                    color: Colors.black.withOpacity(1),
                  ),
                ),
                child: Column(children: [
                  Text(
                    "총점수",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10,),
                  Text(
                    "${sumScore} / 1000",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // 가운데 정렬
                    children: [
                      gScore_check(name: "자격증", maxScore: 600),
                      SizedBox(width: 5),
                      gScore_check(name: "외국어능력", maxScore: 500),
                      SizedBox(width: 5),
                      gScore_check(name: "상담실적", maxScore: 150),
                    ],
                  ),
                  SizedBox(height: 10,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // 가운데 정렬
                    children: [
                      gScore_check(name: "학과행사", maxScore: 150),
                      SizedBox(width: 5),
                      gScore_check(name: "취업훈련", maxScore: 150),
                      SizedBox(width: 5),
                      gScore_check(name: "해외연수", maxScore: 200),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // 가운데 정렬
                    children: [
                      gScore_check(name: "졸업작품입상", maxScore: 100),
                      SizedBox(width: 5),
                      gScore_check(name: "인턴십", maxScore: 300),
                      SizedBox(width: 5),
                      gScore_check(name: "S/W공모전", maxScore: 600),

                    ],
                  ),
                  Text(
                    "${leftScore}",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
//floating border
class gScore_check extends StatefulWidget {
  const gScore_check({Key? key, required this.name, required this.maxScore})
      : super(key: key);

  final dynamic name;
  final dynamic maxScore;

  @override
  _gScoreCheckState createState() => _gScoreCheckState();
}

class _gScoreCheckState extends State<gScore_check> {
  final FlutterSecureStorage storage = FlutterSecureStorage();
  int? score;

  Future<void> _getUserInfo() async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      return;
    }

    final response = await http.get(
      Uri.parse('http://3.39.88.187:3000/gScore/user'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      final user = jsonDecode(response.body);

      final allScoreTemp = user['graduation_score'];
      final allScore = jsonDecode(allScoreTemp);
      score = allScore[widget.name];


      if (score! > widget.maxScore) {
        score = widget.maxScore;
      }
      setState(() {
        score;
      });
    } else {
      throw Exception('예외 발생');
    }
  }

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      height: 110,
      width: 105,
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            child: Text(
              widget.name,
              style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            color: Colors.white,
            child: Text(
              '${score} / ${widget.maxScore}',
              style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          )
        ],
      ),
    );
  }
}

