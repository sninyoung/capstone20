import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';



class searchScorePage extends StatefulWidget {

  final String student_id;

  searchScorePage({required this.student_id});

  @override
  State<searchScorePage> createState() => _searchScorePage();
}

class _searchScorePage extends State<searchScorePage> with TickerProviderStateMixin {
  final FlutterSecureStorage storage = FlutterSecureStorage();
  int sumScore = 0;
  String leftScore = '';
  int totalScore = 0;
  int a = 0;
  int i = 0;
  List<Map<String, dynamic>> maxScores = [];
  Map<String, int> Maxscore = {};
  String studentid = '';
  Map<String, dynamic> allScore = {};
  int? score = 0;
  Map<String, Map<String, int>>? details;
  bool capstone = true;
  String? username = "";


  Future<List<Map<String, dynamic>>> _getMaxScores() async {
    final response = await http.get(
        Uri.parse('http://localhost:443/gScore/maxScore'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      data.forEach((item) {
        final maxCategory = item['max_category'] as String;
        final maxScore = item['max_score'] as int;
        maxScores.add({
          maxCategory: maxScore,
        });
        Maxscore[maxCategory] = maxScore;
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
    for (var scoreMap in maxScores) {
      if (scoreMap.containsKey('총점')) {
        totalScore = scoreMap['총점'];
        break;
      }
    }
    final response = await http.get(
      Uri.parse(
          'http://localhost:443/gScore/getselUserInfo?student_id=${widget
              .student_id}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      final user = jsonDecode(response.body);
      final allScoreTemp = user['graduation_score'];
      final decodedAllScore = jsonDecode(allScoreTemp);
      studentid = widget.student_id;
      setState(() {
        username = user['name'];
      });
      allScore.clear(); // 이전 값들을 제거하고 새로운 값을 저장
      allScore.addAll(decodedAllScore);
      allScore.forEach((key, value) {
        if (maxScores.any((score) => score.containsKey(key))) {
          final maxScore = maxScores.firstWhere((score) =>
              score.containsKey(key))[key] as int;
          if (value > maxScore) {
            allScore[key] = maxScore;
          }
        }
      });
      print(allScore);
      allScore.forEach((key, value) {
        sumScore += value as int;
      });
      _getdetails();
    }
    a = (Maxscore ["총점"] ?? 0) - sumScore;

    if (a < 0) {
      leftScore = '졸업인증점수 완료';
    } else {
      leftScore = '${a}점 남았어요 화이팅';
    }


    setState(() {
      sumScore;
      leftScore;
      studentid;
    });
  }

  Future<void> _getdetails() async {
    details = null;
    final token = await storage.read(key: 'token');

    if (token == null) {
      return;
    }

    if (details == null) {
      final postData = {
        'userId': int.parse(studentid),
      };

      print(postData);
      final detailsResponse = await http.post(
        Uri.parse('http://localhost:443/gScore/detail'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': token,
        },
        body: jsonEncode(postData),
      );

      if (detailsResponse.statusCode == 200) {
        final detailsList = jsonDecode(detailsResponse.body);
        details = {};
        for (final detail in detailsList) {
          final category = detail['gspost_category'];
          final item = detail['gspost_item'];
          final score = detail['gspost_score'];

          if (details![category] == null) {
            details![category] = {};
          }

          details![category]![item] = score;
        }
      }
    }
    capstone = isCapstoneDesignExists();

    if (mounted) {
      setState(() {
        details;
        capstone;
      });
    }
  }

  bool isCapstoneDesignExists() {
    if (details != null) {
      for (final category in details!.keys) {
        final items = details![category];
        if (items != null &&
            (items.containsKey("캡스톤디자인") || items.containsKey("캡스톤 필수 이수"))) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _getUserInfo();
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
            '졸업인증점수',
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
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start, // 좌측 정렬
                  children: [
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('학번: $studentid'),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('이름: $username'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Container(
                  constraints: BoxConstraints(maxWidth: 370),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0),
                    color: Colors.white,
                    border: Border.all(
                      width: 2,
                      color: Colors.black.withOpacity(1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(1),
                        child: Column(
                          children: [
                            SizedBox(height: 10,),
                            Text(
                              "나의 졸업인증점수",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 3,),
                            Text(
                              "${sumScore} / ${totalScore}",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 10,),
                            if (capstone)
                              Text(
                                leftScore,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            if (capstone)
                              Text(
                                "캡스톤 이수: O",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            if (!capstone)
                              Text(
                                leftScore,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            if (!capstone)
                              Text(
                                "캡스톤 이수: X",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                          ],
                        ),
                      ),

                      Column(
                        children: [
                          for (int i = 0; i < maxScores.length; i += 3)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (int j = i; j < i + 3 &&
                                    j < maxScores.length; j++)
                                  if (maxScores[j].keys.first != '총점' &&
                                      maxScores[j].keys.first != '캡스톤디자인')
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.all(8),
                                        child: gScore_check(
                                          name: maxScores[j].keys.first,
                                          maxScore: maxScores[j].values.first,
                                          studentid: widget.student_id,
                                          allScore: allScore,
                                          score: score,
                                          details: details,
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "항목별 터치하여 자세히보기",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 5), // 텍스트와 아이콘 사이의 간격
                          Icon(
                            Icons.touch_app, // 터치 앱 아이콘
                            color: Colors.grey[600], // 짙은 회색
                            size: 18, // 아이콘 크기 조정
                          ),
                        ],
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
  const gScore_check({
    Key? key,
    required this.name,
    required this.maxScore,
    required this.studentid,
    required this.allScore,
    required this.score,
    required this.details,
  }) : super(key: key);

  final dynamic name;
  final dynamic maxScore;
  final String studentid;
  final Map<String, dynamic> allScore;
  final int? score;
  final Map<String, Map<String, int>>? details;

  @override
  _gScoreCheckState createState() => _gScoreCheckState();
}

class _gScoreCheckState extends State<gScore_check> {
  final FlutterSecureStorage storage = FlutterSecureStorage();

  dynamic myscore;
  dynamic maxscore;
  @override
  void initState() {
    super.initState();
    myscore = widget.allScore[widget.name];
    maxscore = widget.maxScore;
  }


  void _showScoreDetails() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 0.0,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '졸업점수 상세보기',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.maxFinite,
                  height: 130,
                  child: Scrollbar(
                    child: ListView.builder(
                      itemCount: 1,
                      itemBuilder: (BuildContext context, int index) {
                        final category = widget.details!.keys.firstWhere(
                              (key) => key == widget.name,
                          orElse: () => '',
                        );
                        final items = widget.details![category] ?? {};

                        if (category.isNotEmpty && items.isNotEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '카테고리: $category',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              for (final item in items.keys)
                                if (items[item] != null)
                                  Text(
                                    '$item: ${items[item]}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                            ],
                          );
                        } else {
                          return Center(
                            child: Text(
                              '해당하는 졸업점수가 없습니다.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  child: Text(
                    '닫기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1E90FF), // #1E90FF (Dodger Blue) 색상
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showScoreDetails,
      child: Container(
        padding: const EdgeInsets.all(8),
        width: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
          color: Colors.white, // 단색 배경
          border: Border.all(
            color: Colors.grey.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              child: Text(
                widget.name,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              color: Colors.transparent,
              child: Text(
                '$myscore / $maxscore',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}