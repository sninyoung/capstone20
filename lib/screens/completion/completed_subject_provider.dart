import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:core';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/screens/completion/mycompletion.dart';
import 'package:capstone/screens/completion/completed_subject_select.dart';


//이수과목과 전공학점 - Provider을 이용한 상태 관리


//총 전공학점
class TotalCredit extends ChangeNotifier {
  int _totalCredit = 0;

  int get totalCredit => _totalCredit;

  void setTotalCredit(int value) {
    _totalCredit = value;
    notifyListeners();  // 학점이 변경되었으므로 관련된 위젯들에게 알립니다.
  }
}



//추후에 23학번 이수유형별 전공학점 관리



