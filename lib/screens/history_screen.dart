import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _testName(String type) {
    final value = type.toLowerCase().trim();

    if (value.contains('finger') || value.contains('tap')) {
      return 'Finger Tapping';
    }

    if (value.contains('line')) {
      return 'Line Tracing';
    }

    if (value.contains('writing') || value.contains('handwriting')) {
      return 'Writing Test';
    }

    if (value.contains('spiral') || value.contains('motor')) {
      return 'Spiral Trace';
    }

    return 'Motor Assessment';
  }

  IconData _testIcon(String type) {
    switch (_testName(type)) {
      case 'Finger Tapping':
        return Icons.touch_app_rounded;

      case 'Line Tracing':
        return Icons.timeline_rounded;

      case 'Writing Test':
        return Icons.edit_rounded;

      case 'Spiral Trace':
        return Icons.gesture_rounded;

      default:
        return Icons.analytics_rounded;
    }
  }

  Color _testColor(String type) {
    switch (_testName(type)) {
      case 'Finger Tapping':
        return const Color(0xFF7B61C9);

      case 'Line Tracing':
        return const Color(0xFF4D8EDC);

      case 'Writing Test':
        return const Color(0xFF4BAA8A);

      case 'Spiral Trace':
        return const Color(0xFFE28A55);

      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Date unavailable';
    }

    final date = timestamp.toDate();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year • $hour:$minute $period';
  }

  double? _numericValue(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  double? _recordScore(Map<String, dynamic> data) {
    return _numericValue(
      data['score'] ?? data['screeningScore'] ?? data['variationScore'],
    );
  }

  String _formatRecordScore(Map<String, dynamic> data) {
    final score = _recordScore(data);
    return score == null ? '--' : '${score.toStringAsFixed(1)}%';
  }

  double? _percentage(dynamic value) {
    final number = _numericValue(value);

    if (number == null) {
      return null;
    }

    if (number <= 1) {
      return number * 100;
    }

    return number;
  }

  String _extraInformation(Map<String, dynamic> data) {
    final parts = <String>[];

    final duration = _numericValue(data['durationSeconds']);

    if (duration != null) {
      parts.add('${duration.toStringAsFixed(1)} s');
    }

    final smoothness = _percentage(data['smoothness']);

    if (smoothness != null) {
      parts.add(
        'Smoothness ${smoothness.toStringAsFixed(1)}%',
      );
    }

    final taps =
        data['tapCount'] ?? data['taps'] ?? data['totalTaps'];

    if (taps != null) {
      parts.add('Taps $taps');
    }

    final strokes = data['strokeCount'];

    if (strokes != null) {
      parts.add('Strokes $strokes');
    }

    final points = data['pointsRecorded'];

    if (points != null) {
      parts.add('Points $points');
    }

    return parts.join(' • ');
  }

  String _summaryText(
    String testName,
    Map<String, dynamic> data,
  ) {
    final score = _recordScore(data);

    final scoreText =
        score != null ? '${score.toStringAsFixed(1)}%' : 'the recorded score';

    switch (testName) {
      case 'Writing Test':
        final smoothness = _percentage(data['smoothness']);

        if (smoothness != null) {
          return 'Your writing movement showed a smoothness measure of '
              '${smoothness.toStringAsFixed(1)}%. '
              'The $scoreText score is based on the movement smoothness '
              'calculated from the recorded writing path.';
        }

        return 'Your writing movement was recorded during the assessment. '
            'The $scoreText score is based on the movement characteristics '
            'captured while completing the writing task.';

      case 'Line Tracing':
        final smoothness = _percentage(data['smoothness']);

        if (smoothness != null) {
          return 'Your movement while tracing the target line was recorded '
              'with a smoothness measure of '
              '${smoothness.toStringAsFixed(1)}%. '
              'The $scoreText score reflects the movement characteristics '
              'measured during the tracing task.';
        }

        return 'Your tracing movement was recorded while following the '
            'target path. The $scoreText score represents the movement '
            'performance measured during this assessment.';

      case 'Finger Tapping':
        final taps =
            data['tapCount'] ?? data['taps'] ?? data['totalTaps'];

        final duration = _numericValue(data['durationSeconds']);

        if (taps != null && duration != null) {
          return 'You completed $taps recorded taps in '
              '${duration.toStringAsFixed(1)} seconds. '
              'The $scoreText score reflects the tapping performance '
              'measured during this assessment.';
        }

        if (taps != null) {
          return 'The assessment recorded $taps taps during the task. '
              'The $scoreText score reflects the tapping performance '
              'measured from the recorded activity.';
        }

        return 'Your finger tapping activity was recorded during the task. '
            'The $scoreText score represents the tapping performance '
            'measured during this assessment.';

      case 'Spiral Trace':
        final smoothness = _percentage(data['smoothness']);

        if (smoothness != null) {
          return 'Your spiral movement was recorded with a smoothness '
              'measure of ${smoothness.toStringAsFixed(1)}%. '
              'The $scoreText score reflects the movement characteristics '
              'measured while tracing the spiral.';
        }

        return 'Your movement while following the spiral was recorded '
            'during the assessment. The $scoreText score represents the '
            'movement performance measured during the tracing task.';

      default:
        return 'Your motor movement was recorded during this assessment. '
            'The $scoreText score represents the movement performance '
            'calculated from the measurements collected during the test.';
    }
  }

  String _scoreBasis(
    String testName,
    Map<String, dynamic> data,
  ) {
    switch (testName) {
      case 'Writing Test':
        return 'The current Writing Test score is calculated primarily '
            'from the smoothness of the recorded writing movement.';

      case 'Line Tracing':
        return 'The Line Tracing score is intended to represent the '
            'movement performance recorded while following the target line.';

      case 'Finger Tapping':
        return 'The Finger Tapping score is based on the tapping '
            'performance recorded during the assessment.';

      case 'Spiral Trace':
        return 'The Spiral Trace score is based on movement '
            'characteristics recorded while following the spiral path.';

      default:
        return 'The score is calculated from movement measurements '
            'recorded during this motor assessment.';
    }
  }

  void _showAssessmentSummary(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final type = data['testType']?.toString() ?? '';

    final testName = _testName(type);
    final color = _testColor(type);
    final icon = _testIcon(type);

    final score = _recordScore(data);

    final scoreText = score != null
        ? '${score.toStringAsFixed(1)}%'
        : '--';

    final summary = _summaryText(
      testName,
      data,
    );

    final basis = _scoreBasis(
      testName,
      data,
    );

    final duration = _numericValue(
      data['durationSeconds'],
    );

    final smoothness = _percentage(
      data['smoothness'],
    );

    final taps =
        data['tapCount'] ??
        data['taps'] ??
        data['totalTaps'];

    final strokes = data['strokeCount'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              maxHeight: 650,
            ),
            padding: const EdgeInsets.fromLTRB(
              22,
              12,
              22,
              24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6DCE7),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: 27,
                        ),
                      ),

                      const SizedBox(width: 13),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              testName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color:
                                    Color(0xFF25324A),
                              ),
                            ),

                            const SizedBox(height: 3),

                            const Text(
                              'Assessment summary',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Color(0xFF8A94A5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FE),
                      borderRadius:
                          BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recorded score',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Color(0xFF7A8499),
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                scoreText,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight:
                                      FontWeight.w900,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (score != null)
                          SizedBox(
                            width: 62,
                            height: 62,
                            child: Stack(
                              alignment:
                                  Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value:
                                      (score / 100)
                                          .clamp(
                                    0.0,
                                    1.0,
                                  ),
                                  strokeWidth: 7,
                                  backgroundColor:
                                      const Color(
                                    0xFFE2E7F0,
                                  ),
                                  valueColor:
                                      AlwaysStoppedAnimation<
                                          Color>(
                                    color,
                                  ),
                                ),
                                Text(
                                  score.toStringAsFixed(0),
                                  style:
                                      const TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.w800,
                                    color:
                                        Color(0xFF303C52),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'What happened?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF25324A),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    summary,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.55,
                      color: Color(0xFF68758A),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'How is the score calculated?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF25324A),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    basis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.55,
                      color: Color(0xFF68758A),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Recorded measurements',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF25324A),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (duration != null)
                        _metricChip(
                          icon: Icons.timer_outlined,
                          label: 'Duration',
                          value:
                              '${duration.toStringAsFixed(1)} s',
                        ),

                      if (smoothness != null)
                        _metricChip(
                          icon: Icons.waves_rounded,
                          label: 'Smoothness',
                          value:
                              '${smoothness.toStringAsFixed(1)}%',
                        ),

                      if (taps != null)
                        _metricChip(
                          icon: Icons.touch_app_rounded,
                          label: 'Taps',
                          value: taps.toString(),
                        ),

                      if (strokes != null)
                        _metricChip(
                          icon: Icons.gesture_rounded,
                          label: 'Strokes',
                          value: strokes.toString(),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8EA),
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                    child: const Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: Color(0xFFB47B21),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This score describes movement performance '
                            'recorded during this assessment. It is '
                            'intended for progress tracking and is not '
                            'a standalone medical diagnosis.',
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.45,
                              color: Color(0xFF7D653C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Got it',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _metricChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FE),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFE2E7F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.circle,
            size: 5,
            color: Color(0xFF4D8EDC),
          ),

          const SizedBox(width: 7),

          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF7A8499),
            ),
          ),

          Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF303C52),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          ? _buildNoUser()
          : StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>
            >(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('motor_assessments')
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return _buildError(
                    snapshot.error.toString(),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final records =
                    snapshot.data!.docs.toList();

                records.sort((a, b) {
                  final aTime =
                      a.data()['createdAt'];

                  final bTime =
                      b.data()['createdAt'];

                  if (aTime is Timestamp &&
                      bTime is Timestamp) {
                    return bTime.compareTo(aTime);
                  }

                  if (aTime is Timestamp) {
                    return -1;
                  }

                  if (bTime is Timestamp) {
                    return 1;
                  }

                  return 0;
                });

                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    30,
                  ),
                  children: [
                    _buildSummaryCard(records),

                    const SizedBox(height: 20),

                    const Text(
                      'Your assessments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF25324A),
                      ),
                    ),

                    const SizedBox(height: 12),

                    ...records.map(
                      (document) {
                        return Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: _buildHistoryCard(
                            context,
                            document.data(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSummaryCard(
    List<QueryDocumentSnapshot<Map<String, dynamic>>>
        records,
  ) {
    final testTypes = <String>{};

    for (final record in records) {
      final type =
          record.data()['testType']?.toString() ?? '';

      testTypes.add(_testName(type));
    }

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Color(0xFF4D8EDC),
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Motor Assessment Progress',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF25324A),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '${records.length} assessment'
                  '${records.length == 1 ? '' : 's'} recorded',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF68758A),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '${testTypes.length} test type'
                  '${testTypes.length == 1 ? '' : 's'} completed',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF68758A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final type =
        data['testType']?.toString() ?? '';

    final name = _testName(type);

    final icon = _testIcon(type);

    final color = _testColor(type);

    final score = _formatRecordScore(data);

    final createdAt =
        data['createdAt'] is Timestamp
            ? data['createdAt'] as Timestamp
            : null;

    final extra =
        _extraInformation(data);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E7F0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 25,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF303C52),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _formatDate(createdAt),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF8A94A5),
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Score',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF8A94A5),
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    score,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (extra.isNotEmpty) ...[
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FE),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Text(
                extra,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF69758A),
                ),
              ),
            ),
          ],

          const SizedBox(height: 13),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () {
                _showAssessmentSummary(
                  context,
                  data,
                );
              },
              icon: Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: color,
              ),
              label: Text(
                'View Summary',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: color.withValues(alpha: 0.45),
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius:
                    BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 45,
                color: Color(0xFF4D8EDC),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'No assessments yet',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF25324A),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Complete a motor assessment and '
              'your results will appear here.',
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

  Widget _buildNoUser() {
    return const Center(
      child: Text(
        'Please log in to view assessment history.',
        style: TextStyle(
          color: Color(0xFF68758A),
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: Colors.redAccent,
            ),

            const SizedBox(height: 15),

            const Text(
              'Unable to load assessment history',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
