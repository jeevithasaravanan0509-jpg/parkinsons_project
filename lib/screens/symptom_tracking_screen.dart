import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/symptom_model.dart';
import '../services/symptom_service.dart';
import 'motor_assessment_home_screen.dart';

class SymptomTrackingScreen extends StatefulWidget {
  const SymptomTrackingScreen({super.key});

  @override
  State<SymptomTrackingScreen> createState() =>
      _SymptomTrackingScreenState();
}

class _SymptomTrackingScreenState extends State<SymptomTrackingScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double tremor = 0;
  double walking = 0;
  double balance = 0;
  double speech = 0;
  double stiffness = 0;
  double sleep = 0;
  double mood = 0;

  final TextEditingController _notesController = TextEditingController();

  bool _isSaving = false;

  // ------------------------------------------------------------
  // OVERALL SCORE
  // ------------------------------------------------------------

  double get overallScore {
    final total =
        tremor +
        walking +
        balance +
        speech +
        stiffness +
        sleep +
        mood;

    return total / 7;
  }

  // ------------------------------------------------------------
  // SEVERITY
  // ------------------------------------------------------------

  String get severity {
    final average = overallScore;

    if (average <= 1) {
      return 'Low';
    } else if (average <= 2) {
      return 'Moderate';
    } else if (average <= 3) {
      return 'High';
    } else {
      return 'Very High';
    }
  }

  Color get severityColor {
    switch (severity) {
      case 'Low':
        return const Color(0xFF55A88A);
      case 'Moderate':
        return const Color(0xFFE1A34F);
      case 'High':
        return const Color(0xFFE17B61);
      default:
        return const Color(0xFFD45C70);
    }
  }

  String _severityForValue(double value) {
    if (value <= 1) {
      return 'Mild';
    } else if (value <= 2) {
      return 'Moderate';
    } else if (value <= 3) {
      return 'Severe';
    } else {
      return 'Very severe';
    }
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // SAVE ASSESSMENT
  // ------------------------------------------------------------

  Future<void> _saveAssessment() async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMessage('Please log in before saving an assessment.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Create the application model.
      final symptom = SymptomModel(
        tremor: tremor,
        walkingDifficulty: walking,
        balanceProblem: balance,
        speechDifficulty: speech,
        stiffness: stiffness,
        sleepQuality: sleep,
        mood: mood,
        medicationTaken: false,
        notes: _notesController.text.trim(),
        date: DateTime.now(),
      );

      // Save locally through SymptomService.
      SymptomService.instance.saveAssessment(symptom);

      // Save to Firebase.
      final assessment = {
        'userId': user.uid,
        'tremor': tremor,
        'walking': walking,
        'balance': balance,
        'speech': speech,
        'stiffness': stiffness,
        'sleep': sleep,
        'mood': mood,
        'averageScore': overallScore,
        'healthScore': symptom.healthScore,
        'severity': severity,
        'medicationTaken': false,
        'notes': _notesController.text.trim(),
        'source': 'manual_assessment',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('symptom_assessments')
          .add(assessment);

      if (!mounted) return;

      _showMessage('Assessment saved successfully.');

      _resetAssessment();
    } on FirebaseException catch (e) {
      _showMessage(
        e.message ?? 'Unable to save your assessment.',
      );
    } catch (e) {
      _showMessage(
        'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // RESET
  // ------------------------------------------------------------

  void _resetAssessment() {
    setState(() {
      tremor = 0;
      walking = 0;
      balance = 0;
      speech = 0;
      stiffness = 0;
      sleep = 0;
      mood = 0;

      _notesController.clear();
    });
  }

  // ------------------------------------------------------------
  // MESSAGE
  // ------------------------------------------------------------

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // OPEN MOTOR ASSESSMENT
  // ------------------------------------------------------------

  void _openMotorAssessment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MotorAssessmentHomeScreen(),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FE),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F9FE),
        foregroundColor: const Color(0xFF25324A),
        centerTitle: true,
        title: const Text(
          'Symptom Tracker',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // HEADER
            // --------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFEAF2FF),
                    Color(0xFFF1EEFF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.monitor_heart_rounded,
                    color: Color(0xFF6385E5),
                    size: 32,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'How are you feeling today?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF25324A),
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Record your symptoms and use guided movement tests to help monitor changes over time.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF68758A),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // --------------------------------------------------
            // GUIDED MOTOR ASSESSMENT
            // --------------------------------------------------

            _buildGuidedAssessmentCard(),

            const SizedBox(height: 25),

            // --------------------------------------------------
            // DAILY ASSESSMENT
            // --------------------------------------------------

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE3E9F4),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    color: Color(0xFF6385E5),
                    size: 26,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Assessment',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF303C52),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Patient-reported symptoms',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF8993A6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF67B99A),
                    size: 22,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // --------------------------------------------------
            // SYMPTOMS
            // --------------------------------------------------

            const Text(
              'Symptoms',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF25324A),
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Rate each symptom from 0 to 4.',
              style: TextStyle(
                fontSize: 13.5,
                color: Color(0xFF7A8499),
              ),
            ),

            const SizedBox(height: 15),

            _symptomSlider(
              title: 'Tremor',
              value: tremor,
              icon: Icons.vibration_rounded,
              onChanged: (value) {
                setState(() {
                  tremor = value;
                });
              },
            ),

            _symptomSlider(
              title: 'Walking Difficulty',
              value: walking,
              icon: Icons.directions_walk_rounded,
              onChanged: (value) {
                setState(() {
                  walking = value;
                });
              },
            ),

            _symptomSlider(
              title: 'Balance',
              value: balance,
              icon: Icons.accessibility_new_rounded,
              onChanged: (value) {
                setState(() {
                  balance = value;
                });
              },
            ),

            _symptomSlider(
              title: 'Speech Difficulty',
              value: speech,
              icon: Icons.record_voice_over_rounded,
              onChanged: (value) {
                setState(() {
                  speech = value;
                });
              },
            ),

            _symptomSlider(
              title: 'Stiffness',
              value: stiffness,
              icon: Icons.accessibility_rounded,
              onChanged: (value) {
                setState(() {
                  stiffness = value;
                });
              },
            ),

            _symptomSlider(
              title: 'Sleep Quality',
              value: sleep,
              icon: Icons.bedtime_rounded,
              onChanged: (value) {
                setState(() {
                  sleep = value;
                });
              },
            ),

            _symptomSlider(
              title: 'Mood',
              value: mood,
              icon: Icons.mood_rounded,
              onChanged: (value) {
                setState(() {
                  mood = value;
                });
              },
            ),

            const SizedBox(height: 12),

            // --------------------------------------------------
            // CURRENT ASSESSMENT
            // --------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(21),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(23),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Assessment',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF25324A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _summaryItem(
                          'Average Score',
                          overallScore.toStringAsFixed(1),
                          Icons.analytics_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryItem(
                          'Severity',
                          severity,
                          Icons.insights_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: overallScore / 4,
                      minHeight: 9,
                      backgroundColor: const Color(0xFFE9EDF5),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        severityColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // --------------------------------------------------
            // NOTES
            // --------------------------------------------------

            const Text(
              'Additional Notes',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF25324A),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe anything you noticed today...',
                hintStyle: const TextStyle(
                  color: Color(0xFFA1A9B8),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: Color(0xFFE3E8F2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: Color(0xFF6385E5),
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // --------------------------------------------------
            // SAVE
            // --------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveAssessment,
                icon: _isSaving
                    ? const SizedBox(
                        height: 21,
                        width: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.cloud_upload_outlined,
                      ),
                label: Text(
                  _isSaving
                      ? 'Saving Assessment...'
                      : 'Save Assessment',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6385E5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            const Center(
              child: Text(
                'Your assessment is securely associated with your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF929BAD),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // GUIDED ASSESSMENT CARD
  // ------------------------------------------------------------

  Widget _buildGuidedAssessmentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEDEBFF),
            Color(0xFFF8F6FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2DEFF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.gesture_rounded,
                  color: Color(0xFF6C63FF),
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guided Motor Assessment',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF303052),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Let the app analyze your movement',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF777795),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          const Text(
            'Not sure how to rate your symptoms?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF34345A),
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Follow simple patterns on the screen. Your movement is analyzed automatically, so you do not have to guess a symptom score.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Color(0xFF777795),
            ),
          ),

          const SizedBox(height: 17),

          Row(
            children: [
              _assessmentFeature(
                Icons.gesture,
                'Trace',
              ),
              const SizedBox(width: 8),
              _assessmentFeature(
                Icons.analytics_outlined,
                'Analyze',
              ),
              const SizedBox(width: 8),
              _assessmentFeature(
                Icons.insights_rounded,
                'Result',
              ),
            ],
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _openMotorAssessment,
              icon: const Icon(
                Icons.play_arrow_rounded,
              ),
              label: const Text(
                'Start Guided Assessment',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Center(
            child: Text(
              'Software-based assessment • Hardware optional',
              style: TextStyle(
                fontSize: 10.5,
                color: Color(0xFF9292AE),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ASSESSMENT FEATURE
  // ------------------------------------------------------------

  Widget _assessmentFeature(
    IconData icon,
    String label,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 19,
              color: const Color(0xFF6C63FF),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666680),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SYMPTOM SLIDER
  // ------------------------------------------------------------

  Widget _symptomSlider({
    required String title,
    required double value,
    required IconData icon,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE9EDF5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF6385E5),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF303C52),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${value.toInt()} / 4',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6385E5),
                  ),
                ),
              ),
            ],
          ),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF6385E5),
              inactiveTrackColor: const Color(0xFFE4E9F3),
              thumbColor: const Color(0xFF6385E5),
              overlayColor: const Color(0x226385E5),
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 8,
              ),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 4,
              divisions: 4,
              label: value.toInt().toString(),
              onChanged: onChanged,
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'None',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9AA3B3),
                ),
              ),
              Text(
                _severityForValue(value),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: severityColor,
                ),
              ),
              const Text(
                'Very severe',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9AA3B3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SUMMARY ITEM
  // ------------------------------------------------------------

  Widget _summaryItem(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF6385E5),
            size: 22,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF8993A6),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF303C52),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}