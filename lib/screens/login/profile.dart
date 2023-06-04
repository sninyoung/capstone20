import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import 'mypost.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String _errorMessage = '';
  bool _isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _studentinfo();
  }

  String? _accountId;
  String? _accountName;
  String? _accountEmail;
  String? _accountIntroduction;
  String? _accountGrade;
  void _studentinfo() async {
    setState(() => _isLoading = true);

    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '토큰이 없습니다.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('게시글 작성에 실패했습니다. (로그인 만료)')));
      });
      return;
    }

    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/user/student'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
    );

    if (response.statusCode == 201) {
      // Success

      final responseData = jsonDecode(response.body);
      setState(() {
        _accountId = responseData[0]['student_id'].toString();
        _accountName = responseData[0]['name'];
        _accountEmail = responseData[0]['email'];
        _accountIntroduction = responseData[0]['introduction'];
        _accountGrade = responseData[0]['grade'].toString();
      });
    } else {
      // Failure
      setState(() {
        final responseData = jsonDecode(response.body);

        _isLoading = false;
        _errorMessage = responseData['message'];
      });
    }
  }
  void gradeupdate(int grade) async {

    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('토큰이 없습니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }



    // Send grade update request
    final response = await http.post(
      Uri.parse('http://203.247.42.144:443/user/grade'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token
      },
      body: jsonEncode(<String, int>{
        'grade': grade,
      }),
    );

    if (response.statusCode == 201) {
      // Grade update success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('학년이 변경되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      // Grade update failed
      final responseData = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseData['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editIntroduction(String introduction) async {
    final url = Uri.parse('http://203.247.42.144:443/post/introduction');
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      setState(() {
        _errorMessage = '토큰이 없습니다.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('자기소개 수정에 실패했습니다. (로그인 만료)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
      body: jsonEncode({
        'introduction': introduction,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _accountIntroduction = introduction;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('정보가 수정되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (response.statusCode == 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('수정 권한이 없습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('정보 수정에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String introductionText = '';
    TextEditingController _controller = TextEditingController();
    _controller.text = _accountIntroduction ?? '';

    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Color(0xffC1D3FF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          const Expanded(flex: 1, child: _TopPortion()),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  if (_accountName != null)
                    Text(
                      _accountName!,
                      style: Theme.of(context)
                          .textTheme
                          .headline6
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  if(_accountGrade != null)
                    Text(
                      _accountGrade! + "학년",
                      style: Theme.of(context).textTheme.headline6?.copyWith(
                        fontSize: 15, // 폰트 크기 변경
                        color: Colors.grey, // 글꼴 색상 변경
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 110),
                          child: FloatingActionButton.extended(
                            onPressed: () {
                              showMenu(
                                context: context,
                                position: RelativeRect.fromLTRB(
                                  MediaQuery.of(context).size.width / 2 - 100,
                                  MediaQuery.of(context).size.height / 1.8 - 100,
                                  MediaQuery.of(context).size.width / 2 - 100,
                                  MediaQuery.of(context).size.height / 1.8 - 100,
                                ),
                                items: [
                                  PopupMenuItem<String>(
                                    value: 'changePassword',
                                    child: ListTile(
                                      leading: Icon(Icons.lock),
                                      title: Text('비밀번호 변경'),
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'changeGrade',
                                    child: ListTile(
                                      leading: Icon(Icons.lock),
                                      title: Text('학년 수정'),
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'editIntroduction',
                                    child: ListTile(
                                      leading: Icon(Icons.edit),
                                      title: Text('자기소개 수정'),
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'myPosts',
                                    child: ListTile(
                                      leading: Icon(Icons.article),
                                      title: Text('내가 쓴 글'),
                                    ),
                                  ),
                                ],
                              ).then((selectedValue) {
                                if (selectedValue == 'changePassword') {
                                  // 비밀번호 변경 동작
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return ChangePasswordDialog();
                                    },
                                  );
                                }
                                else if (selectedValue == 'changeGrade') {
                                  String selectedGrade = '1학년'; // 선택된 학년을 저장할 변수
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return StatefulBuilder(
                                        builder: (BuildContext context, StateSetter setState) {
                                          return AlertDialog(
                                            title: Text("학년 변경"),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text("학년을 선택하세요"),
                                                DropdownButton<String>(
                                                  value: selectedGrade,
                                                  onChanged: (String? newValue) {
                                                    setState(() {
                                                      selectedGrade = newValue!;
                                                    });
                                                  },
                                                  // 드롭다운 버튼의 학년 목록
                                                  items: <String>['1학년', '2학년', '3학년', '4학년'].map<DropdownMenuItem<String>>((String value) {
                                                    return DropdownMenuItem<String>(
                                                      value: value,
                                                      child: Text(value),
                                                    );
                                                  }).toList(),
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  int grade;
                                                  if (selectedGrade == '1학년') {
                                                    grade = 1;
                                                  } else if (selectedGrade == '2학년') {
                                                    grade = 2;
                                                  } else if (selectedGrade == '3학년') {
                                                    grade = 3;
                                                  } else if (selectedGrade == '4학년'){
                                                    grade = 4;
                                                  }
                                                  else {
                                                    // 예외 처리
                                                    return;
                                                  }
                                                  gradeupdate(grade); // 선택한 학년 값으로 수정하여 호출
                                                },
                                                child: Text("확인"),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  );

                                }
                                else if (selectedValue ==
                                    'editIntroduction') {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      String? introductionText;

                                      TextEditingController _introductionController = TextEditingController();
                                      if (_accountIntroduction != null) {
                                        introductionText = _accountIntroduction;
                                        _introductionController.text = _accountIntroduction!;
                                      } else {
                                        introductionText = '연락처\n-\n\n선호언어\n-\n\n개발기술\n-\n\n개인 홈페이지 링크(깃허브, 블로그 등)\n-\n\n한줄 소개\n-\n\n';
                                        _introductionController.text = introductionText;
                                      }

                                      return AlertDialog(
                                        title: Text("정보 수정"),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextFormField(
                                              controller: _introductionController,
                                              onChanged: (value) {
                                                introductionText = value;
                                              },
                                              decoration: InputDecoration(
                                                labelText: "자기소개",
                                                hintText: "자기소개를 입력해주세요",
                                              ),
                                              maxLines: 15,
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text("취소"),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              _editIntroduction(introductionText!);
                                              Navigator.pop(context);
                                            },
                                            child: Text("저장"),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                } else if (selectedValue == 'myPosts') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => MyPost()),
                                  );
                                }
                              });
                            },
                            heroTag: 'changePassword',
                            tooltip: '메뉴',
                            elevation: 0,
                            label: const Text("메뉴"),
                            icon: const Icon(Icons.menu),
                            backgroundColor: Colors.lightBlueAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '자기소개',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _accountIntroduction ?? '',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopPortion extends StatefulWidget {
  const _TopPortion({Key? key}) : super(key: key);

  @override
  _TopPortionState createState() => _TopPortionState();
}

class _TopPortionState extends State<_TopPortion> {
  String _errorMessage = '';
  bool _isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _studentinfo();
  }

  String? _accountId;

  void _studentinfo() async {
    setState(() => _isLoading = true);

    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '토큰이 없습니다.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('게시글 작성에 실패했습니다. (로그인 만료)')));
      });
      return;
    }

    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/user/student'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
    );

    if (response.statusCode == 201) {
      // Success

      final responseData = jsonDecode(response.body);
      setState(() {
        _accountId = responseData[0]['student_id'].toString();
      });
    } else {
      // Failure
      setState(() {
        final responseData = jsonDecode(response.body);

        _isLoading = false;
        _errorMessage = responseData['message'];
      });
    }
  }


  void _selectAndUploadImage(BuildContext context) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    }

    final String fileName = _accountId != null ? _accountId! + '.png' : '';

    // 이미지 압축
    final filePath = image.path;
    final Uint8List? compressedBytes = await FlutterImageCompress.compressWithFile(
      filePath,
      minWidth: 600,
      minHeight: 600,
      quality: 10,
    );

    // If the compression was successful, convert Uint8List to List<int>
    final List<int> bytes = compressedBytes != null ? List<int>.from(compressedBytes) : [];

    final request = http.MultipartRequest(
        'POST', Uri.parse('http://203.247.42.144:443/user/upload'));
    request.files
        .add(http.MultipartFile.fromBytes('image', bytes, filename: fileName));
    final response = await request.send();

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 업로드가 완료되었습니다. 앱 재실행 시 적용됩니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 업로드가 실패하였습니다.')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    if (_accountId == null) {
      return Center(child: CircularProgressIndicator());
    }
    final String fileName = _accountId! + '.png';
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 50),
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xffC1D3FF), Color(0xffC1D3FF)]),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              )),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.transparent,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipOval(
                  child: Image.network(
                    'http://203.247.42.144:443/user/loding?image=$fileName',
                    fit: BoxFit.cover,
                    errorBuilder: (BuildContext context, Object exception,
                        StackTrace? stackTrace) {
                      return Image.asset(
                        'assets/profile.png',
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: () {
                        _selectAndUploadImage(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}

class ChangePasswordDialog extends StatefulWidget {
  @override
  _ChangePasswordDialogState createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  String _errorMessage = '';
  bool _isLoading = false;
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _studentinfo();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  String? _accountPassword;

  void _studentinfo() async {
    setState(() => _isLoading = true);

    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '토큰이 없습니다.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('비밀번호 변경에 실패했습니다. (로그인 만료)'),
          backgroundColor: Colors.red,
        ));
      });
      return;
    }

    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/user/student'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
    );

    if (response.statusCode == 201) {
      // Success

      final responseData = jsonDecode(response.body);
      setState(() {
        _accountPassword = responseData[0]['password'];
      });
    } else {
      // Failure
      setState(() {
        final responseData = jsonDecode(response.body);

        _isLoading = false;
        _errorMessage = responseData['message'];
      });
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('비밀번호 변경'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '새로운 비밀번호',
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return "비밀번호를 입력 해 주세요";
                } else if (value.length < 8) {
                  return "비밀번호는 8자 이상이어야 합니다";
                } else if (!RegExp(
                    r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#$%^&*(),.?":{}|<>]).{8,}$')
                    .hasMatch(value) ||
                    value.contains('?')) {
                  return "비밀번호는 대문자, 소문자, 숫자, 특수문자를\n포함하며 '?' 문자를 사용할 수 없습니다";
                }
                return null;
              },
            ),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '새로운 비밀번호 확인',
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return '새로운 비밀번호를 다시 입력하세요.';
                }
                if (value != _newPasswordController.text) {
                  return '새로운 비밀번호와 일치하지 않습니다.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('취소'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final storage = FlutterSecureStorage();
              final token = await storage.read(key: 'token');
              if (token == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('토큰이 없습니다.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Send password change request
              final response = await http.put(
                Uri.parse('http://203.247.42.144:443/user/password'),
                headers: <String, String>{
                  'Content-Type': 'application/json; charset=UTF-8',
                  'Authorization': token
                },
                body: jsonEncode(<String, String>{
                  'password': _newPasswordController.text,
                }),
              );

              if (response.statusCode == 201) {
                // Password change success
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('비밀번호가 변경되었습니다.'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pop();
              } else {
                // Password change failed
                final responseData = jsonDecode(response.body);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(responseData['message']),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: Text('변경'),
        ),
      ],
    );
  }
}
