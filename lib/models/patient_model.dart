class PatientModel {

  final String name;
  final int age;
  final String gender;
  final String diagnosisDate;
  final String emergencyContact;


  PatientModel({

    required this.name,

    required this.age,

    required this.gender,

    required this.diagnosisDate,

    required this.emergencyContact,

  });


  // Convert patient object into JSON format
  Map<String, dynamic> toJson() {

    return {

      "name": name,

      "age": age,

      "gender": gender,

      "diagnosisDate": diagnosisDate,

      "emergencyContact": emergencyContact,

    };

  }


  // Create patient object from JSON data
  factory PatientModel.fromJson(
      Map<String, dynamic> json) {

    return PatientModel(

      name: json["name"],

      age: json["age"],

      gender: json["gender"],

      diagnosisDate: json["diagnosisDate"],

      emergencyContact: json["emergencyContact"],

    );

  }

}