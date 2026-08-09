class SymptomModel {
  final double tremor;
  final double walkingDifficulty;
  final double speechDifficulty;
  final double balanceProblem;
  final double stiffness;
  final double sleepQuality;
  final double mood;
  final bool medicationTaken;
  final String notes;
  final DateTime date;

  SymptomModel({
    required this.tremor,
    required this.walkingDifficulty,
    required this.speechDifficulty,
    required this.balanceProblem,
    required this.stiffness,
    required this.sleepQuality,
    required this.mood,
    required this.medicationTaken,
    required this.notes,
    required this.date,
  });

  /// Calculates the health score (0–100)
  double get healthScore {
    final average = (
      tremor +
      walkingDifficulty +
      speechDifficulty +
      balanceProblem +
      stiffness +
      sleepQuality +
      mood
    ) / 7;

    double score = 100 - (average * 10);

    if (medicationTaken) {
      score += 5;
    }

    if (score > 100) {
      score = 100;
    }

    if (score < 0) {
      score = 0;
    }

    return score;
  }

  Map<String, dynamic> toMap() {
    return {
      'tremor': tremor,
      'walkingDifficulty': walkingDifficulty,
      'speechDifficulty': speechDifficulty,
      'balanceProblem': balanceProblem,
      'stiffness': stiffness,
      'sleepQuality': sleepQuality,
      'mood': mood,
      'medicationTaken': medicationTaken,
      'notes': notes,
      'date': date.toIso8601String(),
    };
  }

  factory SymptomModel.fromMap(Map<String, dynamic> map) {
    return SymptomModel(
      tremor: (map['tremor'] ?? 0).toDouble(),
      walkingDifficulty:
          (map['walkingDifficulty'] ?? 0).toDouble(),
      speechDifficulty:
          (map['speechDifficulty'] ?? 0).toDouble(),
      balanceProblem:
          (map['balanceProblem'] ?? 0).toDouble(),
      stiffness:
          (map['stiffness'] ?? 0).toDouble(),
      sleepQuality:
          (map['sleepQuality'] ?? 0).toDouble(),
      mood:
          (map['mood'] ?? 0).toDouble(),
      medicationTaken:
          map['medicationTaken'] ?? false,
      notes:
          map['notes'] ?? '',
      date:
          DateTime.parse(map['date']),
    );
  }
}