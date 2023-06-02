
class Subject {
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


