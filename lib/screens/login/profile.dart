import 'package:capstone/screens/login/mypost.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
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
      Uri.parse('http://3.39.88.187:3000/user/student'),
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

  Future<void> _editIntroduction(String introduction) async {
    final url = Uri.parse('http://3.39.88.187:3000/post/introduction');
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      setState(() {
        _errorMessage = '토큰이 없습니다.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('자기소개 수정에 실패했습니다.(로그인 만료)')));
      });
      return;
    }
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
      body: jsonEncode( {
        'introduction': introduction,
      }),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('자기소개 수정이 수정되었습니다.')));
      setState(() {
        _accountIntroduction = introduction;
      });
    }
    else if (response.statusCode == 300){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('수정 권한이 없습니다.')));
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('자기소개 수정에 실패했습니다.')));
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
                      style: Theme.of(context).textTheme.headline6?.copyWith(fontWeight: FontWeight.bold),
                    ),


                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: FloatingActionButton.extended(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return ChangePasswordDialog();
                              },
                            );
                          },
                          heroTag: 'changePassword',
                          tooltip: '비밀번호 변경',
                          elevation: 0,
                          label: const Text("비밀번호 변경", style: TextStyle(fontSize: 12),),
                          icon: const Icon(Icons.lock, size: 15,),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: FloatingActionButton.extended(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => MyPost()),
                            );
                          },
                          heroTag: 'mesage',
                          elevation: 0,
                          backgroundColor: Colors.red,
                          label: const Text("내가 쓴 글", style: TextStyle(fontSize: 12),),
                          icon: const Icon(Icons.message_rounded, size: 15, ),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: FloatingActionButton.extended(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text("자기소개 수정"),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: _controller,
                                        onChanged: (value) {
                                          introductionText = value; // 텍스트 필드의 값을 변수에 저장
                                        },
                                        decoration: InputDecoration(
                                          labelText: "자기소개",
                                          hintText: "자기소개를 입력해주세요",
                                        ),
                                        textInputAction: TextInputAction.newline, // 엔터를 눌렀을 때 다음 줄로 이동
                                        maxLines: null, // 텍스트 필드의 크기를 자동으로 조정하여 여러 줄 입력 가능
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context); // 팝업 창 닫기
                                      },
                                      child: Text("취소"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        // 수정 로직을 추가하세요.
                                        // introductionText 변수에 저장된 자기소개 내용을 사용하여 처리
                                        _editIntroduction(introductionText); // 자기소개 수정 API 호출
                                        Navigator.pop(context); // 팝업 창 닫기
                                      },
                                      child: Text("저장"),
                                    ),

                                  ],
                                );
                              },
                            );
                          },
                          heroTag: 'Introduction',
                          elevation: 0,
                          backgroundColor: Colors.lightGreen,
                          label: const Text("자기소개 수정", style: TextStyle(fontSize: 12),),
                          icon: const Icon(Icons.edit, size: 15,),
                        ),
                      ),

                    ],
                  ),

                  const SizedBox(height: 20),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
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
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
      Uri.parse('http://3.39.88.187:3000/user/student'),
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
    final bytes = await image.readAsBytes();

    final request =
    http.MultipartRequest('POST', Uri.parse('http://3.39.88.187:3000/user/upload'));
    request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: fileName));
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
                    'http://3.39.88.187:3000/user/loding?image=$fileName',
                    fit: BoxFit.cover,
                    errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('비밀번호 변경에 실패했습니다. (로그인 만료)'), backgroundColor: Colors.red,));
      });
      return;
    }


    final response = await http.get(
      Uri.parse('http://3.39.88.187:3000/user/student'),
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
            // TextFormField(
            //   controller: _currentPasswordController,
            //   obscureText: true,
            //   decoration: InputDecoration(
            //     labelText: '현재 비밀번호',
            //   ),
            //   validator: (value) {
            //     if (value!.isEmpty) {
            //       return '현재 비밀번호를 입력하세요.';
            //     }
            //     if(value != _accountPassword){
            //       print(_accountPassword);
            //       return '비밀번호가 일치하지 않습니다';
            //     }
            //
            //   },
            // ),
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
                    .hasMatch(value) || value.contains('?')) {
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
                Uri.parse('http://3.39.88.187:3000/user/password'),
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
                  SnackBar(content: Text('비밀번호가 변경되었습니다.'), backgroundColor: Colors.green,),
                );
                Navigator.of(context).pop();
              } else {
                // Password change failed
                final responseData = jsonDecode(response.body);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(responseData['message']), backgroundColor: Colors.red,),
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
