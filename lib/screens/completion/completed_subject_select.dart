import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:capstone/main.dart';
import 'package:capstone/screens/completion/completion_status.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

//이수과목 선택 페이지

void main() {
  runApp(MaterialApp(
    title: '나의 이수현황',
    home: CompletionSelect(),
  ));
}

class CompletionSelect extends StatefulWidget {
  @override
  _CompletionSelectState createState() => _CompletionSelectState();
}

class _CompletionSelectState extends State<CompletionSelect> {
  final List<String> _compulsorySubjects = [];
  final List<String> _electiveSubjects = [];
  final List<String> _selectedCompulsorySubjects = [];
  final List<String> _selectedElectiveSubjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    try {
      final dio = Dio();
      final response = await dio.get('http://3.39.88.187:3000/subject/');

      if (response.statusCode == 200) {
        var jsonData = response.data;
        setState(() {
          for (var item in jsonData) {
            if (item["subject_division"] == 1) {
              _compulsorySubjects.add(item["subject_name"]);
            } else if (item["subject_division"] == 2) {
              _electiveSubjects.add(item["subject_name"]);
            }
          }
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load subjects');
      }
    } catch (error) {
      throw Exception('Failed to fetch subjects: $error');
    }
  }

  // 서버에 선택한 과목 저장
  Future<void> _saveSubjects() async {
    try {
      final dio = Dio();
      final response =
      await dio.post('http://3.39.88.187:3000/user/required/add', data: {
        'compulsory_subjects': _selectedCompulsorySubjects,
        'elective_subjects': _selectedElectiveSubjects,
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to save subjects');
      }
    } catch (error) {
      throw Exception('Failed to save subjects: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이수과목 선택'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.all(20),
              child: MultiSelectChipField<String>(
                items: _compulsorySubjects
                    .map((s) => MultiSelectItem<String>(s, s))
                    .toList(),
                initialValue: _selectedCompulsorySubjects,
                title: Text("전공기초과목"),
                headerColor: Colors.blue,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                ),
                selectedChipColor: Colors.blue,
                selectedTextStyle: TextStyle(color: Colors.white),
                onTap: (values) {
                  setState(() {
                    _selectedCompulsorySubjects.clear();
                    if(values != null) {
                      _selectedCompulsorySubjects.addAll(values.whereType<String>());
                    }
                  });
                },

              ),
            ),
            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.all(20),
              child: MultiSelectChipField<String>(
                items: _electiveSubjects
                    .map((s) => MultiSelectItem<String>(s, s))
                    .toList(),
                initialValue: _selectedElectiveSubjects,
                title: Text("전공선택과목"),
                headerColor: Colors.blue,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                ),
                selectedChipColor: Colors.blue,
                selectedTextStyle: TextStyle(color: Colors.white),
                onTap: (values) {
                  setState(() {
                    _selectedElectiveSubjects.clear();
                    if(values != null) {
                      _selectedElectiveSubjects.addAll(values.whereType<String>());
                    }
                  });
                },

              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveSubjects,
        child: Icon(Icons.save),
        tooltip: '저장',
      ),
    );
  }
}
