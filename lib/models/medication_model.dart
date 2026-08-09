class MedicationModel {

  final String medicineName;
  final String dosage;
  final String reminderTime;


  MedicationModel({

    required this.medicineName,

    required this.dosage,

    required this.reminderTime,

  });



  Map<String, dynamic> toJson() {

    return {

      "medicineName": medicineName,

      "dosage": dosage,

      "reminderTime": reminderTime,

    };

  }



  factory MedicationModel.fromJson(
      Map<String, dynamic> json) {

    return MedicationModel(

      medicineName:
          json["medicineName"],

      dosage:
          json["dosage"],

      reminderTime:
          json["reminderTime"],

    );

  }

}