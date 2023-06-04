//과목 모델
class Subject {

  //과목의 동일성을 판단 -중복으로 추가되는 것 방지
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Subject && other.subjectId == subjectId;
  }

  @override
  int get hashCode => subjectId.hashCode;


  final int subjectId;
  final int proId;
  final String subjectName;
  final int credit;
  final int subjectDivision;
  final int? typeMd;
  final int? typeTr;

  Subject({
    required this.subjectId,
    required this.proId,
    required this.subjectName,
    required this.credit,
    required this.subjectDivision,
    this.typeMd,
    this.typeTr,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      subjectId: json['subject_id'],
      proId: json['pro_id'],
      subjectName: json['subject_name'],
      credit: json['credit'],
      subjectDivision: json['subject_division'],
      typeMd: json['type_md'],
      typeTr: json['type_tr'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject_id': subjectId,
      'pro_id': proId,
      'subject_name': subjectName,
      'credit': credit,
      'subject_division': subjectDivision,
      'type_md': typeMd,
      'type_tr': typeTr,
    };
  }

  @override
  String toString() {
    return 'Subject{subjectId: $subjectId, proId: $proId, subjectName: $subjectName, credit: $credit, subjectDivision: $subjectDivision, typeMd: $typeMd, typeTr: $typeTr}';
  }

}


