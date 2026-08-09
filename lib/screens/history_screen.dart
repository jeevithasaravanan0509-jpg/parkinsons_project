import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/symptom_model.dart';
import '../services/symptom_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<SymptomModel> symptomHistory =
        SymptomService.instance.getAllAssessments();

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FE),
        foregroundColor: const Color(0xFF25324A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Assessment History',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: user == null
          ? _buildNoUser(context, symptomHistory)
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('motor_assessments')
                  .orderBy(
                    'createdAt',
                    descending: true,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return _buildLoadingScreen();
                }

                final motorResults =
                    snapshot.data?.docs ?? [];

                final hasSymptomHistory =
                    symptomHistory.isNotEmpty;

                final hasMotorHistory =
                    motorResults.isNotEmpty;

                if (!hasSymptomHistory &&
                    !hasMotorHistory) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await Future.delayed(
                      const Duration(milliseconds: 400),
                    );
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      30,
                    ),
                    children: [
                      _buildHeader(
                        symptomCount:
                            symptomHistory.length,
                        motorCount:
                            motorResults.length,
                      ),

                      const SizedBox(height: 22),

                      if (hasMotorHistory) ...[
                        _buildSectionTitle(
                          'Motor Assessments',
                          'Movement tests completed in the app',
                          Icons.psychology_alt_rounded,
                        ),
                        const SizedBox(height: 12),
                        ...motorResults.map(
                          (doc) => _buildMotorCard(
                            context,
                            doc,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      if (hasSymptomHistory) ...[
                        _buildSectionTitle(
                          'Symptom Assessments',
                          'Your recorded daily symptoms',
                          Icons.monitor_heart_outlined,
                        ),
                        const SizedBox(height: 12),
                        ...symptomHistory.reversed.map(
                          (item) =>
                              _buildSymptomCard(item),
                        ),
                      ],

                      const SizedBox(height: 20),

                      _buildDisclaimer(),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader({
    required int symptomCount,
    required int motorCount,
  }) {
    return Container(
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
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.history_rounded,
            size: 36,
            color: Color(0xFF6C63FF),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your Progress',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: Color(0xFF25324A),
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Review your previous symptom and movement '
            'assessments in one place.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: Color(0xFF68758A),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildCountCard(
                  'Symptoms',
                  symptomCount,
                  Icons.monitor_heart_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCountCard(
                  'Motor Tests',
                  motorCount,
                  Icons.touch_app_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountCard(
    String title,
    int count,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF6C63FF),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF303C52),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF7A8499),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SECTION TITLE
  // =========================================================

  Widget _buildSectionTitle(
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color:
                const Color(0xFF6C63FF)
                    .withValues(alpha: 0.10),
            borderRadius:
                BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF6C63FF),
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF25324A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7A8499),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // MOTOR ASSESSMENT CARD
  // =========================================================

  Widget _buildMotorCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final testType =
        data['testType']?.toString() ??
            'motor_assessment';

    final score =
        _toDouble(data['score']);

    final tapCount =
        _toInt(data['tapCount']);

    final tapRate =
        _toDouble(data['tapRatePerSecond']);

    final consistency =
        _toDouble(data['tappingConsistency']);

    final createdAt =
        data['createdAt'] as Timestamp?;

    final date =
        createdAt?.toDate();

    final testName =
        _formatTestName(testType);

    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xFFE4E9F2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF8B78D9)
                          .withValues(alpha: 0.10),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  color: Color(0xFF8B78D9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      testName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(0xFF303C52),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      date == null
                          ? 'Date unavailable'
                          : _formatDate(date),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color:
                            Color(0xFF7A8499),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (score != null)
            _buildMetricRow(
              'Movement Score',
              score.toStringAsFixed(1),
              Icons.analytics_outlined,
            ),

          if (tapCount != null)
            _buildMetricRow(
              'Tap Count',
              '$tapCount',
              Icons.touch_app_rounded,
            ),

          if (tapRate != null)
            _buildMetricRow(
              'Tap Rate',
              '${tapRate.toStringAsFixed(2)} /s',
              Icons.speed_rounded,
            ),

          if (consistency != null)
            _buildMetricRow(
              'Tapping Consistency',
              '${(consistency * 100).toStringAsFixed(1)}%',
              Icons.waves_rounded,
            ),
        ],
      ),
    );
  }

  // =========================================================
  // SYMPTOM CARD
  // =========================================================

  Widget _buildSymptomCard(
    SymptomModel item,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xFFE4E9F2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF4D8EDC)
                          .withValues(alpha: 0.10),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.monitor_heart_outlined,
                  color: Color(0xFF4D8EDC),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Symptom Assessment',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(0xFF303C52),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDate(item.date),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color:
                            Color(0xFF7A8499),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFEAF7F1),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Text(
                  '${item.healthScore.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xFF4C9A78),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildMetricRow(
            'Tremor',
            item.tremor.toStringAsFixed(1),
            Icons.vibration_rounded,
          ),

          _buildMetricRow(
            'Walking Difficulty',
            item.walkingDifficulty
                .toStringAsFixed(1),
            Icons.directions_walk_rounded,
          ),

          _buildMetricRow(
            'Speech Difficulty',
            item.speechDifficulty
                .toStringAsFixed(1),
            Icons.record_voice_over_outlined,
          ),

          _buildMetricRow(
            'Balance',
            item.balanceProblem
                .toStringAsFixed(1),
            Icons.accessibility_new_rounded,
          ),

          _buildMetricRow(
            'Sleep Quality',
            item.sleepQuality
                .toStringAsFixed(1),
            Icons.bedtime_outlined,
          ),

          _buildMetricRow(
            'Mood',
            item.mood.toStringAsFixed(1),
            Icons.sentiment_satisfied_alt_outlined,
          ),

          const SizedBox(height: 8),

          Text(
            'Medication: '
            '${item.medicationTaken ? "Taken" : "Not Taken"}',
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF68758A),
            ),
          ),

          if (item.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Notes: ${item.notes}',
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF68758A),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // METRIC ROW
  // =========================================================

  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF8B78D9),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF68758A),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF303C52),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const SizedBox(height: 70),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color:
                    const Color(0xFF6C63FF)
                        .withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 44,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Assessments Yet',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF25324A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete a symptom or motor assessment '
              'and your results will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF7A8499),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // LOADING
  // =========================================================

  Widget _buildLoadingScreen() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // =========================================================
  // NO USER
  // =========================================================

  Widget _buildNoUser(
    BuildContext context,
    List<SymptomModel> history,
  ) {
    if (history.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding:
          const EdgeInsets.all(20),
      children: [
        _buildHeader(
          symptomCount: history.length,
          motorCount: 0,
        ),
        const SizedBox(height: 22),
        _buildSectionTitle(
          'Symptom Assessments',
          'Your recorded daily symptoms',
          Icons.monitor_heart_outlined,
        ),
        const SizedBox(height: 12),
        ...history.reversed.map(
          _buildSymptomCard,
        ),
        const SizedBox(height: 20),
        _buildDisclaimer(),
      ],
    );
  }

  // =========================================================
  // DISCLAIMER
  // =========================================================

  Widget _buildDisclaimer() {
    return Container(
      padding:
          const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9ED),
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFF0DFB8),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFB58532),
            size: 20,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Assessment results are intended for '
              'screening and progress tracking and '
              'should not be treated as a standalone '
              'medical diagnosis.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.45,
                color: Color(0xFF806B43),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // HELPERS
  // =========================================================

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  String _formatTestName(String testType) {
    switch (testType) {
      case 'finger_tapping':
        return 'Finger Tapping';

      case 'spiral_trace':
        return 'Spiral Trace';

      case 'writing_test':
        return 'Writing Test';

      case 'line_tracing':
        return 'Line Tracing';

      default:
        return 'Motor Assessment';
    }
  }

  String _formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}