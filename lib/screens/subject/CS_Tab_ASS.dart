import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:capstone/screens/subject/subjectinfo.dart';
import 'package:capstone/screens/subject/editsubject.dart';
import 'package:capstone/screens/subject/addsubject.dart';

// [전공기초 Tab]-조교

Future<List<List<Map<String, dynamic>>>> fetchSubjects() async {
  final response = await http.get(Uri.parse('http://203.247.42.144:443/subject/'));

  if (response.statusCode == 200) {
    final data = json.decode(response.body) as List<dynamic>;
    List<Map<String, dynamic>> subjects = List<Map<String, dynamic>>.from(data);

    List<Map<String, dynamic>> compulsorySubjects = [];
    List<Map<String, dynamic>> electiveSubjects = [];

    for (var subject in subjects) {
      if (subject['subject_division'] == 1) {
        compulsorySubjects.add(subject);
      } else if (subject['subject_division'] == 2) {
        electiveSubjects.add(subject);
      }
    }
    return [compulsorySubjects, electiveSubjects];
  } else {
    throw Exception('Failed to fetch subjects');
  }
}

class CStabASS extends StatefulWidget {
  @override
  _CStabASS createState() => _CStabASS();
}

class _CStabASS extends State<CStabASS> {
  final TextEditingController _filter = TextEditingController();
  Future<List<List<Map<String, dynamic>>>> subjectsFuture = fetchSubjects();
  FocusNode focusNode = FocusNode();
  String search = ''; // 검색어를 저장할 변수

  _CStabASS() {
    _filter.addListener(() {
      setState(() {
        search = _filter.text;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    subjectsFuture = fetchSubjects();
  }

  Future<void> refreshSubjects() async {
    setState(() {
      subjectsFuture = fetchSubjects();
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body:  RefreshIndicator(
        onRefresh: refreshSubjects,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(40, 30, 0, 1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment:  MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    child: Text(
                      "컴퓨터공학과 전공과목",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 25,
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                  //추가탭
                  SizedBox(
                    width: 110.0, // 원하는 너비로 설정
                    height: 30.0, // 원하는 높이로 설정
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 40, 0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AddSubjectPage()),
                          );
                        },
                        child: Text('과목 추가',
                          style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Colors.white,),),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo, // 배경 색상 변경
                          padding: EdgeInsets.symmetric(vertical: 6.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),

            Container(
              padding: EdgeInsets.fromLTRB(40, 5, 0, 1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    child: Text(
                      "major subject",
                      style: TextStyle(
                        color: Color(0xff848484),
                        fontSize: 14,
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 검색창 구현
            Container(
              padding: EdgeInsets.fromLTRB(40, 20, 40, 20),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 6,
                    child: TextField(
                      textAlign: TextAlign.left,
                      focusNode: focusNode,
                      style: TextStyle(
                        fontSize: 15,
                      ),
                      autofocus: false,
                      controller: _filter,
                      onChanged: (value) {
                        setState(() {
                          search = value;
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black12,
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.black54,
                          size: 20,
                        ),
                        hintText: '과목명을 입력하세요',
                        labelStyle: TextStyle(color: Colors.black),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                            borderRadius: BorderRadius.all(Radius.circular(10))),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                            borderRadius: BorderRadius.all(Radius.circular(10))),
                        border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                            borderRadius: BorderRadius.all(Radius.circular(10))),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: EdgeInsets.fromLTRB(40, 5, 0, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    child: Text(
                      "전공기초과목  ",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  SizedBox(
                    child: Text(
                      "compulsory subject",
                      style: TextStyle(
                        color: Color(0xff848484),
                        fontSize: 14,
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.fromLTRB(40, 10, 40, 30),
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child:
                FutureBuilder<List<List<Map<String, dynamic>>>>(
                  future: subjectsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      // 데이터를 가져오는 데 성공한 경우
                      List<Map<String, dynamic>> subjects = snapshot.data![0];
                      if (search.isNotEmpty) {
                        // 검색어가 있을 때 데이터를 필터링하여 표시
                        subjects = subjects.where((subject) =>
                            subject['subject_name'].toString().toLowerCase().contains(search.toLowerCase())).toList();
                      }
                      if (subjects.isEmpty) {
                        // 필터링된 결과가 없는 경우
                        return Center(child: Text('검색결과를 찾지 못했습니다'));
                      }
                      return Scrollbar(
                          child: ListView.builder(
                            itemCount: subjects.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '    학수번호',
                                        style: TextStyle(
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8.0),
                                      Text(
                                        '과목명',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8.0),
                                      Text(
                                        '학점    ',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              final subject = subjects[index - 1];

                              if (search.isNotEmpty && !subject['subject_name'].toString().toLowerCase().contains(search.toLowerCase())) {
                                // 검색어가 있고 현재 항목의 subject_name과 검색어와 일치하지 않으면 표시하지 않음
                                return Container();
                              }
                              return ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
                                title: GestureDetector(
                                  onTap: () {
                                    // 행을 누르면 과목 상세페이지로 이동
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditSubjectPage(
                                          subjectId: subject['subject_id'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12.0),
                                      color: Colors.white,
                                      border: Border.all(
                                        width: 2,
                                        color: Colors.grey.withOpacity(0.5),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          subject['subject_id'].toString(),
                                          style: TextStyle(
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8.0),
                                        Text(subject['subject_name'].toString(),
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8.0),
                                        Text(
                                          subject['credit'].toString(),
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ), // 추가적인 과목 정보 표시를 위한 코드 작성
                                ),
                              );
                            },
                          )
                      );
                    } else if (snapshot.hasError) {
                      // 데이터를 가져오는 데 실패한 경우
                      return Center(child: Text('Failed to fetch subjects'));
                    } else {
                      // 데이터를 가져오는 중인 경우
                      return Center(child: CircularProgressIndicator());
                    }
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