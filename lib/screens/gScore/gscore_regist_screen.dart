import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/screens/gScore/gscore_list_screen.dart';
import 'dart:io';
//import 'package:http_parser/http_parser.dart';
//import 'package:path_provider/path_provider.dart';
//import 'package:open_file/open_file.dart';

//신청창
void main() {
  runApp(MaterialApp(
    title: '졸업점수 신청',
    home: GScoreApc(),
  ));
}

class GScoreApc extends StatefulWidget {
  const GScoreApc({Key? key}) : super(key: key);

  @override
  _GScoreApcState createState() => _GScoreApcState();
}

class _GScoreApcState extends State<GScoreApc> {
  void initState() {
    super.initState();
    _fetchLists();
  }

  Future<void> _fetchLists() async {
    if (activityTypes.isEmpty) {
      final typeResponse =
      await http.get(Uri.parse('http://3.39.88.187:3000/gScore/getType'));
      if (typeResponse.statusCode == 200) {
        final typeResult = jsonDecode(typeResponse.body);
        for (var typeItem in typeResult) {
          String gsinfoType = typeItem['gsinfo_type'];
          if (gsinfoType != '관리자승인' && !activityTypes.contains(gsinfoType)) {
            activityTypes.add(gsinfoType);
          }
        }
        setState(() {
          activityTypes;
        });
      } else {
        throw Exception('Failed to load types');
      }
    }
  }
  Future<void> _fetchNamesAndScores(String selectedType) async {
    if (!activityNames.containsKey(selectedType)) {
      final encodedType = Uri.encodeComponent(selectedType);
      final infoResponse = await http.get(Uri.parse('http://3.39.88.187:3000/gScore/getInfoByType/$encodedType'));
      if (infoResponse.statusCode == 200) {
        final infoResult = jsonDecode(infoResponse.body);
        activityNames[selectedType] = {};
        for (var infoItem in infoResult) {
          String gsinfoName = infoItem['gsinfo_name'];
          int gsinfoScore = infoItem['gsinfo_score'];
          activityNames[selectedType]![gsinfoName] = gsinfoScore;
        }
        setState(() {
          activityNames;
        });
      } else {
        throw Exception('Failed to load names and scores');
      }
    }
  }


  void _selectFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedFile = result.files.first;
        fileCheck = 1;

      });
    }
  }

  Future<void> _writePostAndFile() async {
    setState(() => _isLoading = true);
    if (_activityType == null || _activityName == null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('알림'),
            content: Text('활동 종류와 활동명은 필수 선택 항목입니다.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // 경고창 닫기
                },
                child: Text('확인'),
              ),
            ],
          );
        },
      );
      return; // 함수 종료
    }


    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      setState(() {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('실패: 로그인 정보 없음')));
      });
      return;
    }

    final Map<String, dynamic> postData = {
      'gspost_category': _activityType,
      'gspost_item': _activityName,
      'gspost_score': int.tryParse(_activityScore),
      'gspost_content': _contentController.text,
      'gspost_pass': _applicationStatus,
      'gspost_reason': _rejectionReason,
      'gspost_start_date': _startDate?.toIso8601String(),
      'gspost_end_date': _endDate?.toIso8601String(),

      'gspost_file': fileCheck,

    };


    final response = await http.post(
      Uri.parse('http://3.39.88.187:3000/gScore/write'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
      body: jsonEncode(postData),
    );

    print(response.statusCode);
    setState(() => _isLoading = false);

    if (response.statusCode == 201) {
      postUploadCheck = 1;
      if(fileCheck==1) {
        var jsonResponse = jsonDecode(response.body);
        postId = jsonResponse['postId'];
        //uploadFile();
      }
    }else{
      print(response.statusCode);
      print('에러');
    }
  }

  Future<void> uploadFile() async {
    print(postId.toString());

    if (selectedFile != null) {
      final String fileName = selectedFile!.name;
      final bytes = File(selectedFile!.path!).readAsBytesSync();

      final maxRetries = 3; // 최대 재시도 횟수
      var retryCount = 0; // 현재 재시도 횟수

      while (retryCount < maxRetries) {
        try {
          final request = http.MultipartRequest(
            'POST',
            Uri.parse('http://3.39.88.187:3000/gScore/upload'),
          );

          request.files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: fileName),
          );

          request.fields['gspostid'] = postId.toString();

          final response = await request.send();
          print(response.statusCode);

          if (response.statusCode == 201) {
            print("파일 등록 성공");

            var responseData = await response.stream.bytesToString();
            var decodedData = json.decode(responseData);
            var file = decodedData['file'];

            fileInfo = {
              'post_id': postId,
              'file_name': file['filename'],
              'file_original_name': file['originalname'],
              'file_size': file['size'],
              'file_path': file['path'],
            };
            fileUploadCheck = 1;

            print(fileInfo);
            return; // 성공적으로 요청을 보냈으면 메서드를 종료
          } else {
            print(response.statusCode);
            print("파일 등록 실패");
          }
        } catch (error) {
          print('등록 네트워크 연결 오류: $error');
        }

        retryCount++;
        await Future.delayed(Duration(seconds: 1)); // 1초 후에 재시도
      }

      print('재시도 횟수 초과');
    }
  }

  Future<void> _uploadfileToDB() async {
    final maxRetries = 3; // 최대 재시도 횟수
    var retryCount = 0; // 현재 재시도 횟수

    while (retryCount < maxRetries) {
      try {
        final response = await http.post(
          Uri.parse('http://3.39.88.187:3000/gScore/fileToDB'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(fileInfo),
        );

        if (response.statusCode == 201) {
          print('DB저장 완료');
          return; // 성공적으로 요청을 보냈으면 메서드를 종료
        } else {
          print(response.statusCode);
          print('에러');
        }
      } catch (error) {
        print('DB 네트워크 연결 오류: $error');
      }

      retryCount++;
      await Future.delayed(Duration(seconds: 1)); // 1초 후에 재시도
    }

    print('재시도 횟수 초과'); // 최대 재시도 횟수를 초과하면 에러 메시지 출력
  }


  bool isEditable = false;

  bool _isLoading = false;
  // 활동 종류에 대한 드롭다운형식의 콤보박스에서 선택된 값
  String? _activityType;

  // 활동명에 대한 드롭다운형식의 콤보박스에서 선택된 값
  String? _activityName;

  //점수값
  String _activityScore = '';

  // 시작 날짜 선택박스에서 선택된 값
  DateTime? _startDate;

  // 종료 날짜 선택박스에서 선택된 값
  DateTime? _endDate;

  // 점수를 입력할 수 있는 박스에서 입력된 값
  int? _subscore;

  // 신청 상태에 대한 드롭다운형식의 콤보박스에서 선택된 값
  String _applicationStatus = '대기';

  //비고란
  TextEditingController _contentController = TextEditingController();

  // 반려 사유를 입력할 수 있는 텍스트 입력박스에서 입력된 값
  String? _rejectionReason;

  //파일이 저장값
  PlatformFile? selectedFile;

  int fileCheck = 0;



  //작성된 게시글 번호
  int postId= 0;

  //게시글이 정상적으로 업로드 되었는지 체크
  int postUploadCheck = 0;

  //파일이 정상적으로 서버에 업로드 되었는지 체크
  int fileUploadCheck = 0;

  //업로드한 파일의 정보
  Map<String, dynamic> fileInfo={};


  //활동종류 리스트
  List<String> activityTypes = [];

  //활동명 리스트
  Map<String, Map<String, int>> activityNames = {};

  final TextEditingController _scoreController = TextEditingController();

  //활동종류 드롭박스 눌렀을시 활동명을 초기화 해줘야 충돌이 안남
  void _onActivityTypeChanged(String? newValue) {
    setState(() {
      _activityType = newValue;
      _activityName = null;
      _scoreController.text = '';
      _activityScore = '';
    });

    if (newValue != null) {
      _fetchNamesAndScores(newValue);
    }
  }

  final _formKey = GlobalKey<FormState>();

  void _onActivityNameChanged(String? newValue) {
    setState(() {
      _activityName = newValue;
      _scoreController.text =
          activityNames[_activityType]?[_activityName]?.toString() ?? '';
      if(_activityName != '50일 이상' || _activityName !='TOPCIT') {
        _activityScore =
            activityNames[_activityType]?[_activityName]?.toString() ?? '';
      }
      else{
        _activityScore = _subscore.toString();
      }
    });
  }
  void _subscore_function(String value){
    if (value.isNotEmpty &&
        _activityName == 'TOPCIT' ||
        _activityName == '50일 이상') {
      _subscore = int.parse(value) * 2;
      if (_activityName == 'TOPCIT' &&
          (_subscore ?? 0) > 1000) {
        _subscore = 1000;
      }
      else if (_activityType == '인턴쉽' &&
          (_subscore ?? 0) > 300) {
        _subscore = 300;
      }
      else if (_activityType == '해외 연수' &&
          (_subscore ?? 0) > 200) {
        _subscore = 200;
      }
      _activityScore = _subscore.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '졸업점수 신청',
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
                    value: _activityType,
                    validator: (value) => (value!.isEmpty) ? "asd" : null,
                    onChanged: _onActivityTypeChanged,
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
                  // 활동 종류에 대한 드롭다운형식의 콤보박스
                  child: DropdownButtonFormField<String>(
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
                        .toList(), // null일 경우에 대한 처리
                  ),
                ), //padding2
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: '시작 날짜',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.date_range),
                          ),
                          onTap: () async {
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
                    SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: '종료 날짜',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.date_range),
                          ),
                          onTap: () async {
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
                ),
                // 점수 출력박스와 입력박스
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          readOnly: _activityName == 'TOPCIT' ||
                              _activityName == '50일 이상'
                              ? false
                              : true,
                          decoration: const InputDecoration(
                            labelText: '점수',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: _subscore_function,
                          controller: TextEditingController(
                              text: _activityName == 'TOPCIT' && _subscore != null ? _subscore.toString()
                                  : _activityName == '50일 이상' && _subscore != null ? _subscore.toString()
                                  : activityNames[_activityType]?[_activityName]?.toString() ?? ''
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: '승인 점수',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                //비고란
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: '비고',
                      border: OutlineInputBorder(),
                    ),
                    controller: _contentController,

                  ),
                ),

                // 신청 상태에 대한 드롭다운형식의 콤보박스
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: '신청 상태',
                      border: OutlineInputBorder(),
                    ),
                    value: _applicationStatus,
                    items: const [
                      DropdownMenuItem(value: '대기', child: Text('대기')),
                      DropdownMenuItem(value: '승인', child: Text('승인')),
                      DropdownMenuItem(value: '반려', child: Text('반려')),
                    ],
                    onChanged: isEditable
                        ? (value) {
                      setState(() {
                        _applicationStatus = value ?? '';
                      });
                    }
                        : null,
                  ),
                ),

                // 반려 사유 입력박스
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  // 활동 종류에 대한 드롭다운형식의 콤보박스
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: '반려 사유',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _rejectionReason = value;
                      });
                    },
                  ),
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
                      onPressed: () {
                        _selectFile(); // 파일 선택 수행
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



                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      labelText: '첨부 파일',
                      labelStyle: TextStyle(
                        fontSize: 16.0,
                      ),
                      suffix: selectedFile != null
                          ? IconButton(
                        onPressed: () {
                          setState(() {
                            selectedFile = null;
                            fileCheck = 0;
                          });
                          // 버튼이 눌렸을 때 수행할 동작
                        },
                        icon: Icon(
                          Icons.delete,
                          color: Colors.grey,
                        ),
                      )
                          : null,
                    ),
                    readOnly: true,
                    controller: TextEditingController(text: '${selectedFile?.name ?? ''}',),
                  ),
                ),
                const SizedBox(height: 8),

                // 저장 버튼
                Padding(
                  //세번째 padding
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Material(
                    elevation: 5.0, //그림자효과
                    borderRadius: BorderRadius.circular(30.0), //둥근효과
                    color: const Color(0xffC1D3FF),
                    child: MaterialButton(
                      onPressed: (!_isLoading) ? () async{
                        await _writePostAndFile();
                        if(postUploadCheck ==1 && fileCheck ==1){
                          setState(() => _isLoading = true);
                          await uploadFile();
                          setState(() => _isLoading = false);
                        }
                        if(fileUploadCheck == 1){
                          setState(() => _isLoading = true);
                          await _uploadfileToDB();
                          setState(() => _isLoading = false);
                        }
                        if(postUploadCheck ==1){
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => GScoreForm()))
                              .then((value) {
                            setState(() {});
                          });

                        }else{
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('게시글 작성 실패: 서버 오류')));
                        }

                      } : null,
                      child: _isLoading ? CircularProgressIndicator() : Text(
                        "신청하기",
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
          ),
        ),
      ),
    );
  }
}
