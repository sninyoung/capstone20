import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProfessorPage extends StatefulWidget {
  final String professorId;

  EditProfessorPage({required this.professorId});

  @override
  _EditProfessorPageState createState() => _EditProfessorPageState();
}

class _EditProfessorPageState extends State<EditProfessorPage> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _phoneNumController = TextEditingController();
  TextEditingController _majorController = TextEditingController();

  Future<void> fetchProfessorInfo() async {
    final url = Uri.parse(
      'http://203.247.42.144:443/prof/info?pro_id=${widget.professorId}',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final professorInfoList = jsonDecode(response.body) as List<dynamic>;

      if (professorInfoList.isNotEmpty) {
        final professorInfo = professorInfoList[0];

        setState(() {
          _nameController.text = professorInfo['name'];
          _emailController.text = professorInfo['email'];
          _phoneNumController.text = professorInfo['phone_num'];
          _majorController.text = professorInfo['major'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('교수 정보 조회에 실패했습니다'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('교수 정보를 불러오는 데 실패했습니다'),
        ),
      );
    }
  }

  Future<void> modifyProfessorInfo() async {
    final url = Uri.parse('http://203.247.42.144:443/prof/modify');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'pro_id': widget.professorId,
        'name': _nameController.text,
        'email': _emailController.text,
        'phone_num': _phoneNumController.text,
        'major': _majorController.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('성공적으로 수정되었습니다'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('수정 Error'),
        ),
      );
    }
  }

  Future<void> deleteProfessorInfo() async {
    final url = Uri.parse('http://203.247.42.144:443/prof/delete');
    final response = await http.delete(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'pro_id': widget.professorId,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('성공적으로 삭제되었습니다'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('삭제 Error : 사용되고 있는 교수 정보입니다.'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProfessorInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '교수 정보 관리',
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
      body: SingleChildScrollView(
        child:Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '교수 사번: ${widget.professorId}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '이름',
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: '이메일',
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _phoneNumController,
                decoration: InputDecoration(
                  labelText: '전화번호',
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _majorController,
                decoration: InputDecoration(
                  labelText: '전공',
                ),
              ),
              SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // 수정 완료 버튼을 눌렀을 때의 동작 구현

                      modifyProfessorInfo();
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        Color(0xffC1D3FF),
                      ),
                    ),
                    child: Text('수정'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // 삭제 버튼을 눌렀을 때의 동작 구현
                      deleteProfessorInfo(); // 교수 정보 삭제 함수 호출
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        Color(0xffC1D3FF),
                      ),
                    ),
                    child: Text('삭제'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneNumController.dispose();
    _majorController.dispose();
    super.dispose();
  }
}
