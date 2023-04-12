import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


void main() {
  runApp(MaterialApp(
    title: '신청글 조회/수정',
  ));
}

class GScoreApcCt extends StatefulWidget {
  final dynamic post;

  GScoreApcCt({required this.post});

  @override
  _GScoreApcCtState createState() => _GScoreApcCtState();
}

class _GScoreApcCtState extends State<GScoreApcCt> {
  String? _selectedActivityType;

  int _permissionValue = 0;
  @override
  void initState() {
    super.initState();
    _fetchGsInfo();
    _fetchContent();
    _getUserInfo();

  }

  Future<void> _fetchGsInfo() async {
    final response = await http
        .get(Uri.parse('http://3.39.88.187:3000/gScore/info'));

    if (response.statusCode == 200) {
      final funcResult =  jsonDecode(response.body);
      for (var item in funcResult) {
        String gsinfoType = item['gsinfo_type'];
        if (!activityTypes.contains(gsinfoType)) {
          activityTypes.add(gsinfoType);
          activityNames[gsinfoType] = {};

          setState(() {
            activityTypes;
            activityNames;
          });
        }

        String gsinfoName = item['gsinfo_name'];
        int gsinfoScore = item['gsinfo_score'];

        if (activityNames.containsKey(gsinfoType)) {
          activityNames[gsinfoType]![gsinfoName] = gsinfoScore;
        }

      }
    } else {
      throw Exception('Failed to load posts');
    }
  }




  void _fetchContent(){
    setState(() {
      _activityType = widget.post['gspost_category'];

      _activityName = widget.post['gspost_item'];

      if(widget.post['gspost_start_date']!=null) {
        _startDate = DateTime.parse(widget.post['gspost_start_date']);}

      if(widget.post['gspost_end_date']!=null) {
        _endDate = DateTime.parse(widget.post['gspost_end_date']);}

      _activityScore = widget.post['gspost_score'].toString();

      _applicationStatus = widget.post['gspost_pass'].toString();

      if(widget.post['gspost_content']!=null) {
        _content = widget.post['gspost_content'].toString();}

      if(widget.post['gspost_reason']!=null) {
        _rejectionReason = widget.post['gspost_reason'].toString();
      }
    });
  }


  Future<void> _getUserInfo() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if(token == null){
      return ;
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
      userId = user['student_id'];
      userPermission = user['permission'];

    } else {
      throw Exception('예외 발생');
    }
  }

  int userId = 0;
  int userPermission = 0;

  // 활동 종류에 대한 드롭다운형식의 콤보박스에서 선택된 값
  String? _activityType;

  // 활동명에 대한 드롭다운형식의 콤보박스에서 선택된 값
  String? _activityName;

  // 시작 날짜 선택박스에서 선택된 값
  DateTime? _startDate;

  // 종료 날짜 선택박스에서 선택된 값
  DateTime? _endDate;

  //점수값
  String _activityScore='';

  // 점수를 입력할 수 있는 박스에서 입력된 값
  int? _score;

  // 신청 상태에 대한 드롭다운형식의 콤보박스에서 선택된 값
  String? _applicationStatus;

  String? _content;

  // 반려 사유를 입력할 수 있는 텍스트 입력박스에서 입력된 값
  String? _rejectionReason;

  //파일이 저장값
  List<PlatformFile?> _attachmentFile = [];

  //파일명
  final Map<String?, String?> _Filenames = {};

  List<String> activityTypes = []; //활동 종류(카테고리)

  Map<String, Map<String, int>> activityNames = {}; //카테고리:{활동명:점수,}

  void _onActivityTypeChanged(String? newValue) {
    setState(() {
      _activityType = newValue;
      _activityName = null;
    });
  }

  final _formKey = GlobalKey<FormState>();

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
          '신청글 조회/수정',
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
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Center(
            child: ListView(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  // 활동 종류에 대한 드롭다운형식의 콤보박스
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: '활동 종류',
                      border: OutlineInputBorder(),
                    ),
                    value: _applicationStatus == '승인' || _applicationStatus == '반려' ? _activityType : _selectedActivityType ?? _activityType,
                    onChanged: _applicationStatus == '승인' || _applicationStatus == '반려' ? null : _onActivityTypeChanged,
                    items: activityTypes
                        .map<DropdownMenuItem<String>>(
                            (String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ))
                        .toList(),
                  ),
                ), //padding1
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  // 활동명에 대한 드롭다운형식의 콤보박스
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: '활동명',
                      border: OutlineInputBorder(),
                    ),
                    value: _activityName,
                    onChanged: _applicationStatus == '승인' || _applicationStatus == '반려' ? null : _onActivityNameChanged,
                    items: _applicationStatus == '승인' || _applicationStatus == '반려' ? null : activityNames[_activityType]
                        ?.entries
                        .map<DropdownMenuItem<String>>((MapEntry<String, int> entry) => DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.key),
                    ))
                        .toList(), // null일 경우에 대한 처리
                    disabledHint: Text(_activityName ?? ''), // 비활성화 된 상태에서 선택된 값을 보여줌
                  ),
                ), //padding2

                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          readOnly: _applicationStatus == '승인' || _applicationStatus == '반려',
                          decoration: const InputDecoration(
                            labelText: '시작 날짜',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.date_range),
                          ),
                          onTap: _applicationStatus == '승인' || _applicationStatus == '반려'
                              ? null
                              : () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            setState(() {
                              _startDate = selectedDate;
                            });
                          },
                          controller: TextEditingController(
                            text: _startDate != null
                                ? '${_startDate!.year}-${_startDate!.month}-${_startDate!.day}'
                                : null,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          readOnly: _applicationStatus == '승인' || _applicationStatus == '반려',
                          decoration: const InputDecoration(
                            labelText: '종료 날짜',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.date_range),
                          ),
                          onTap: _applicationStatus == '승인' || _applicationStatus == '반려'
                              ? null
                              : () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            setState(() {
                              _endDate = selectedDate;
                            });
                          },
                          controller: TextEditingController(
                            text: _endDate != null
                                ? '${_endDate!.year}-${_endDate!.month}-${_endDate!.day}'
                                : null,
                          ),
                        ),
                      ),
                    ),

                  ],
                ), //padding3
                // 점수 출력박스와 입력박스
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: '점수',
                            border: OutlineInputBorder(),
                          ),
                          controller: TextEditingController(
                              text: activityNames[_activityType]?[_activityName]
                                  ?.toString() ??
                                  ''),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          readOnly: _applicationStatus == '승인' || _applicationStatus == '반려',
                          decoration: const InputDecoration(
                            labelText: '점수 입력',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _score = int.tryParse(value);
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                    padding: const EdgeInsets.all(8.0),
                    // 활동 종류에 대한 드롭다운형식의 콤보박스
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: '신청 상태',
                        border: OutlineInputBorder(),
                      ),
                      value: _applicationStatus,
                      onChanged: (_permissionValue == 2)
                          ? (value) {
                        setState(() {
                          _applicationStatus = value ?? '';
                        });
                      }
                          : null,
                      items: (_permissionValue == 2)
                          ? [
                        DropdownMenuItem(value: '대기', child: Text('대기')),
                        DropdownMenuItem(value: '승인', child: Text('승인')),
                        DropdownMenuItem(value: '반려', child: Text('반려')),
                      ]
                          : [
                        DropdownMenuItem(value: '대기', child: Text('대기')),
                        DropdownMenuItem(value: '승인', child: Text('승인', style: TextStyle(color: Colors.grey))),
                        DropdownMenuItem(value: '반려', child: Text('반려', style: TextStyle(color: Colors.grey))),
                      ],
                    )
                ),

                //비고란
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    readOnly: _applicationStatus == '승인' || _applicationStatus == '반려',
                    decoration: const InputDecoration(
                      labelText: '비고',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(
                        text: _content),
                    onChanged: (value) {
                      setState(() {
                        _content = value;
                      });
                    },
                  ),
                ),

                // 신청 상태에 대한 드롭다운형식의 콤보박스

                // 반려 사유 입력박스
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    // 활동 종류에 대한 드롭다운형식의 콤보박스
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: '반려 사유',
                        border: OutlineInputBorder(),
                      ),
                      enabled: _permissionValue == 2,
                      onChanged: (value) {
                        setState(() {
                          _rejectionReason = value;
                        });
                      },
                    )
                ),
                SizedBox(height: 8.0),
                // 첨부파일 업로드박스
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Material(
                    elevation: 5.0, //그림자효과
                    borderRadius: BorderRadius.circular(30.0), //둥근효과
                    color: const Color(0xffC1D3FF),
                    child: MaterialButton(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles();
                        if (result != null) {
                          setState(() {
                            _attachmentFile.add(result.files.single);
                            _Filenames.addAll(
                                {'파일명': result.files.single.name});
                          });
                        }
                      },
                      child: const Text(
                        "첨부파일 업로드",
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

                // 활동 종류에 대한 드롭다운형식의 콤보박스
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          width: 2.0,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        borderRadius:
                        const BorderRadius.all(Radius.circular(4.0)),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _attachmentFile.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Dismissible(
                            key: UniqueKey(),
                            onDismissed: (direction) {
                              setState(() {
                                _attachmentFile.removeAt(index);
                                _Filenames.removeWhere((key, value) => false);
                              });
                            },
                            background: Container(color: Colors.red),
                            child: ListTile(
                              title: Text('$_Filenames'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8.0),

                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Material(
                          elevation: 5.0, //그림자효과
                          borderRadius: BorderRadius.circular(30.0), //둥근효과
                          color: const Color(0xffC1D3FF),
                          child: MaterialButton(
                            onPressed: _applicationStatus == '승인' || _applicationStatus == '반려' ? null : () {
                              // 버튼 클릭 시 동작
                              print('저장 버튼이 클릭되었습니다.');
                              print('활동 종류: $_activityType');
                              print('활동명: $_activityName');
                              print('시작 날짜: $_startDate');
                              print('종료 날짜: $_endDate');
                              print('점수: $_score');
                              print('신청 상태: $_applicationStatus');
                              print('반려 사유: $_rejectionReason');
                              print('첨부 파일: $_attachmentFile');
                            },
                            child: const Text(
                              "삭제하기",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )

                      ),
                    ),Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Material(
                        elevation: 5.0, //그림자효과
                        borderRadius: BorderRadius.circular(30.0), //둥근효과
                        color: const Color(0xffC1D3FF),
                        child: MaterialButton(
                          onPressed: _applicationStatus == '승인' || _applicationStatus == '반려'
                              ? null
                              : () {
                            // 여기에 저장 버튼 클릭 시 수행할 동작을 작성합니다.
                            print('저장 버튼이 클릭되었습니다.');
                            print('활동 종류: $_activityType');
                            print('활동명: $_activityName');
                            print('시작 날짜: $_startDate');
                            print('종료 날짜: $_endDate');
                            print('점수: $_score');
                            print('신청 상태: $_applicationStatus');
                            print('반려 사유: $_rejectionReason');
                            print('첨부 파일: $_attachmentFile');
                          },
                          child: const Text(
                            "수정하기",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child:  Material(
                        elevation: 5.0, //그림자효과
                        borderRadius: BorderRadius.circular(30.0), //둥근효과
                        color: const Color(0xffC1D3FF),
                        child: MaterialButton(
                          onPressed: () {
                            // 여기에 저장 버튼 클릭 시 수행할 동작을 작성합니다.
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "목록으로",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}