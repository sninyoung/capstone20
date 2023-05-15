import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


void main() {
  runApp(MaterialApp(
    title: '졸업점수 셀프 계산기',
    home: SelfCalcScreen(),
  ));
}

class SelfCalcScreen extends StatefulWidget {
  const SelfCalcScreen({Key? key}) : super(key: key);

  @override
  SelfCalcScreenState createState() => SelfCalcScreenState();
}

class SelfCalcScreenState extends State<SelfCalcScreen> {
  @override
  void initState(){
    super.initState();
    _fetchPosts();
  }
  String? _activityType;

  String? _selectType;

  String? _activityName;

  int? _score;

  final List<Map<String, dynamic>> _save = [];

  Map<String, dynamic> MaxScore = {"S/W공모전":600,"상담실적":150, "외국어능력":500, "인턴십":300, "자격증":600,
    "졸업작품입상":100, "총점":1000, "취업훈련":150, "취업/대학원진학":850, "캡스톤디자인":0,"학과행사":150,"해외연수":200};

  Map<String?,int> eachMaxTotal = {"S/W공모전":0,"상담실적":0, "외국어능력":0, "인턴쉽":0, "자격증":0,
    "졸업작품입상":0, "총점":0, "취업훈련":0, "취업/대학원진학":0, "캡스톤디자인":0,"학과행사":0,"해외연수":0};

  Map<String?,int> eachTotal = {"S/W공모전":0,"상담실적":0, "외국어능력":0, "인턴쉽":0, "자격증":0,
    "졸업작품입상":0, "총점":0, "취업훈련":0, "취업/대학원진학":0, "캡스톤디자인":0,"학과행사":0,"해외연수":0};

  int _total = 0;

  int _remainingScore = 800;

  List<String> activityTypes = [];

  Map<String, Map<String,int>> activityNames = {
    '상담실적': {'1':10,'2':20,'3':30,'4':40,'5':50,'6':60,'7':70,'8':80,'9':90,'10':100,'11':110,'12':120,'13':130,'14':140,'15':150},
    '해외연수': {'참여 일수':0},
    '인턴십': {'참여 일수':0},
  };

  Future<void> _fetchPosts() async {
    final response = await http
        .get(Uri.parse('http://3.39.88.187:3000/gScore/info'));

    if (response.statusCode == 200) {
      final funcResult =  jsonDecode(response.body);
      for (var item in funcResult) {
        String gsinfoType = item['gsinfo_type'];
        if (!activityTypes.contains(gsinfoType)) {
          activityTypes.add(gsinfoType);
          if(!['상담실적', '해외연수', '인턴십'].contains(gsinfoType)){
            activityNames[gsinfoType] = {};
          }

          setState(() {
            activityTypes;
            activityNames;
          });
        }

        String gsinfoName = item['gsinfo_name'];
        int gsinfoScore = item['gsinfo_score'];

        if (!['상담실적', '해외연수', '인턴십'].contains(gsinfoType) &&activityNames.containsKey(gsinfoType)) {
          activityNames[gsinfoType]![gsinfoName] = gsinfoScore;
        }

      }
    } else {
      throw Exception('Failed to load posts');
    }
  }



  void setMaxscore() async{
    int sum = 0;
    _total = 0;
    for(final item in _save){
      if(item['Type'] == _selectType){
        sum += int.parse(item['score'].toString());
      }
    }
    eachTotal[_selectType] = sum;
    if(MaxScore[_selectType] != null && sum >= MaxScore[_selectType]!){
      sum = MaxScore[_selectType];
    }
    eachMaxTotal[_selectType] = sum;
    eachMaxTotal.forEach((key, value) {
      _total += value;
    });
  }

  void _addScore(){
    if (_activityName == '참여 일수' || _activityName == 'TOPCIT' && _activityType != null) {
      setState(() {
        _save.add({
          'Type': _activityType!,
          'Name': _activityName!,
          'score': _score
        });
        setMaxscore();
        if (_remainingScore > 0) {
          _remainingScore = 800 - _total;
          if (_remainingScore < 0) {
            _remainingScore = 0;
          }
        }
        _activityType = null;
        _activityName = null;

      });
    }
    else if (_activityName != null && _activityType != null) {
      setState(() {
        _save.add({
          'Type': _activityType!,
          'Name': _activityName!,
          'score': activityNames[_activityType]?[_activityName]
        });
        setMaxscore();

        if (_remainingScore > 0) {
          _remainingScore = 800 - _total;
          if (_remainingScore < 0) {
            _remainingScore = 0;
          }
        }
        _activityType = null;
        _activityName = null;

      });
    }
  }

  void printApp(){
    print(_save);
    print(eachTotal);
    print(eachMaxTotal);
  }



  void _onActivityTypeChanged(String? newValue) {
    setState(() {
      _activityType = newValue;
      _selectType = _activityType;
      _activityName = null;
    });
  }

  void _onActivityNameChanged(String? newValue) {
    setState(() {
      _activityName = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '졸업점수 셀프 계산기',
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: '활동 종류',
                border: OutlineInputBorder(),
              ),
              value: _activityType,
              onChanged: _onActivityTypeChanged,
              items: activityTypes
                  .map<DropdownMenuItem<String>>(
                      (String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            // 활동명에 대한 드롭다운형식의 콤보박스
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: '활동명',
                border: OutlineInputBorder(),
              ),
              value: _activityName,
              onChanged: _onActivityNameChanged,
              items: activityNames[_activityType]
                  ?.entries
                  .map<DropdownMenuItem<String>>(
                      (MapEntry<String, int> entry) =>
                      DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.key),
                      ))
                  .toList() ??
                  [],
            ),
            const SizedBox(height: 16),

            TextFormField(
              readOnly: _activityName == 'TOPCIT' ||
                  _activityName == '참여 일수'
                  ? false : true,
              decoration: const InputDecoration(
                labelText: '점수',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _score= 0;
                if (value.isNotEmpty && int.parse(value)>0) {
                  int tempScore = int.parse(value);

                  if(_activityType == '인턴십' || _activityType == '해외연수'){
                    if(tempScore<30){ tempScore = 0;}
                    else if(tempScore>=30 && tempScore<40){ tempScore = 25;}
                    else if(tempScore>=40 && tempScore<50){ tempScore = 40;}
                  }
                  if(_activityName == 'TOPCIT' && tempScore>1000){ tempScore = 1000;}
                  if(_activityType == '인턴십' && tempScore>150){ tempScore = 150;}
                  if(_activityType == '해외연수' && tempScore>100){ tempScore = 100;}

                  _score = tempScore * 2;
                }
                else{
                  _score = 0;
                }

              },
              controller: TextEditingController(
                  text: activityNames[_activityType]?[_activityName]?.toString() ?? ''
              ),
            ),
            SizedBox(height: 16.0),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: '취득 점수',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: _total.toString()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: '남은 점수',
                      border: OutlineInputBorder(),
                    ),
                    controller:
                    TextEditingController(text: _remainingScore.toString()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Material(
                elevation: 5.0, //그림자효과
                borderRadius: BorderRadius.circular(30.0), //둥근효과
                color: const Color(0xffC1D3FF),
                child: MaterialButton(
                  onPressed: () {
                    _addScore();
                    printApp();
                  },
                  child: const Text(
                    "추가하기",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                ),
                child: ListView.builder(
                  itemCount: _save.length,
                  itemBuilder: (BuildContext context, int index) {
                    final activity = _save[index];
                    return Dismissible(
                      key: UniqueKey(),
                      onDismissed: (direction) {
                        setState(() {
                          _save.removeAt(index);
                          print(activity['Type']);
                          if (activity['score'] != null && eachTotal[activity['Type']] != null) {
                            eachTotal[activity['Type']] = (eachTotal[activity['Type']] ?? 0) - activity['score'] as int;
                          }
                          if (eachTotal[activity['Type']] != null && eachMaxTotal[activity['Type']] != null && eachTotal[activity['Type']]! < eachMaxTotal[activity['Type']]!) {
                            eachMaxTotal[activity['Type']] = eachTotal[activity['Type']]!;
                          }
                          _total = 0;
                          eachMaxTotal.forEach((key, value) {
                            _total += value;
                          });
                          if (_remainingScore >= 0) {
                            _remainingScore = 800 - _total;
                            if (_remainingScore <= 0) {
                              _remainingScore = 0;
                            }
                          }
                        });
                      },
                      background: Container(color: Colors.red),
                      child: ListTile(
                        title:
                        Text('${activity['Type']} - ${activity['Name']}'),
                        trailing: Text('${activity['score']}점'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
