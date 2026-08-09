import '../models/symptom_model.dart';

class SymptomService {
  SymptomService._();

  static final SymptomService instance = SymptomService._();

  final List<SymptomModel> _assessments = [];

  // Save an assessment locally
  void saveAssessment(SymptomModel symptom) {
    _assessments.add(symptom);
  }

  // Get all assessments
  List<SymptomModel> getAllAssessments() {
    return List.unmodifiable(_assessments);
  }

  // Get the most recent assessment
  SymptomModel? getLatestAssessment() {
    if (_assessments.isEmpty) {
      return null;
    }

    return _assessments.last;
  }

  // Remove all local assessments
  void clearAll() {
    _assessments.clear();
  }

  // Calculate average health score
  double getAverageHealthScore() {
    if (_assessments.isEmpty) {
      return 0;
    }

    double total = 0;

    for (final assessment in _assessments) {
      total += assessment.healthScore;
    }

    return total / _assessments.length;
  }

  // Total number of assessments
  int get totalAssessments => _assessments.length;
}