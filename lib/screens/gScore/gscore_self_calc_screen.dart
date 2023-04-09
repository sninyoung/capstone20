import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  String? _activityName;

  final List<Map<String, dynamic>> _save = [];

  int _total = 0;

  int _remainingScore = 800;

  List<String> activityTypes = [];

  Map<String, Map<String,int>> activityNames = {
    '상담 실적': {'1':10,'2':20,'3':30,'4':40,'5':50,'6':60,'7':70,'8':80,'9':90,'10':100,'11':110,'12':120,'13':130,'14':140,'15':150},
    '해외 연수': {'30~39일':50, '40~49일':80, '50일':100,'51일':102, '52일':104,'53일':106,'54일':108,'55일':110,'56일':112,'57일':124,'58일':126,
      '59일':128,'60일':120,'61일':122,'62일':124,'63일':126,'64일':128,'65일':130,'66일':132,'67일':134,'68일':136,'69일':138, '70일':140,'71일':142,
      '72일':144,'73일':146,'74일':148,'75일':150,'76일':152,'77일':154,'78일':156,'79일':158,'80일':160,'81일':162,'82일':164,'83일':166,'84일':168,
      '85일':170,'86일':172, '87일':174,'88일':176,'89일':178,'90일':180,'91일':182,'92일':184,'93일':186,'94일':188,'95일':190,'96일':192,'97일':194,
      '98일':196,'99일':198,'100일 이상':200
    },
    '인턴쉽': {'30~39일':50, '40~49일':80, '50일':100,'51일':102, '52일':104,'53일':106,'54일':108,'55일':110,'56일':112,'57일':124,'58일':126,
      '59일':128,'60일':120,'61일':122,'62일':124,'63일':126,'64일':128,'65일':130,'66일':132,'67일':134,'68일':136,'69일':138, '70일':140,'71일':142,
      '72일':144,'73일':146,'74일':148,'75일':150,'76일':152,'77일':154,'78일':156,'79일':158,'80일':160,'81일':162,'82일':164,'83일':166,'84일':168,
      '85일':170,'86일':172, '87일':174,'88일':176,'89일':178,'90일':180,'91일':182,'92일':184,'93일':186,'94일':188,'95일':190,'96일':192,'97일':194,
      '98일':196,'99일':198,'100일':200,'101일':202,'102일':204, '103일':206,'104일':208,'105일':210,'106일':212,'107일':214,'108일':216,'109일':218,
      '110일':220,'111일':222,'112일':224,'113일':226, '114일':228,'115일':230,'116일':232,'117일':234,'118일':236,'119일':238,'120일':240,'121일':242,
      '122일':244,'123일':246,'124일':248,'125일':250,'126일':252,'127일':254,'128일':256,'129일':258,'130일':260,'131일':262,'132일':264,'133일':266,
      '134일':268,'135일':270,'136일':272,'137일':274,'138일':276,'139일':278, '140일':280,'141일':282,'142일':284,'143일':286,'144일':288,'145일':290,
      '146일':292,'147일':294,'148일':296,'149일':298,'150일 이상':300
    },
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
          if(!['상담 실적', '해외 연수', '인턴쉽'].contains(gsinfoType)){
            activityNames[gsinfoType] = {};
          }

          setState(() {
            activityTypes;
            activityNames;
          });
        }

        String gsinfoName = item['gsinfo_name'];
        int gsinfoScore = item['gsinfo_score'];

        if (!['상담 실적', '해외 연수', '인턴쉽'].contains(gsinfoType) &&activityNames.containsKey(gsinfoType)) {
          activityNames[gsinfoType]![gsinfoName] = gsinfoScore;
        }

      }
    } else {
      throw Exception('Failed to load posts');
    }
  }



  void _onActivityTypeChanged(String? newValue) {
    setState(() {
      _activityType = newValue;
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
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: '점수',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(
                    text:
              activityNames[_activityType]?[_activityName]?.toString() ?? ''

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
                    if (_activityName != null && _activityType != null) {
                      setState(() {
                        _save.add({
                          'Type': _activityType!,
                          'Name': _activityName!,
                          'score': activityNames[_activityType]?[_activityName]
                        });
                        _total +=
                            activityNames[_activityType]?[_activityName] ?? 0;
                        if (_remainingScore > 0) {
                          _remainingScore = 800 - _total;
                          if (_remainingScore < 0) {
                            _remainingScore = 0;
                          }
                        }
                        _activityType = null;
                        _activityName = null;
                        print(_save);
                      });
                    }
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
                          _total -= activity['score'] as int;
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
