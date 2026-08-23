import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MotorProgressScreen extends StatefulWidget {
  const MotorProgressScreen({super.key});

  @override
  State<MotorProgressScreen> createState() => _MotorProgressScreenState();
}

class _MotorProgressScreenState extends State<MotorProgressScreen> {
  String _selectedTest = 'Finger Tapping';

  final List<String> _testNames = [
    'Finger Tapping',
    'Line Tracing',
    'Writing Test',
    'Spiral Trace',
  ];

  Color _testColor(String testName) {
    switch (testName) {
      case 'Finger Tapping':
        return const Color(0xFF7B61C9);
      case 'Line Tracing':
        return const Color(0xFF4D8EDC);
      case 'Writing Test':
        return const Color(0xFF4BAA8A);
      case 'Spiral Trace':
        return const Color(0xFFE28A55);
      default:
        return const Color(0xFF4D8EDC);
    }
  }

  IconData _testIcon(String testName) {
    switch (testName) {
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

  double? _readScore(Map<String, dynamic> data) {
    // Older assessments stored their result under a test-specific name.
    // Keep those records visible alongside newer records that use `score`.
    final value = data['score'] ??
        data['screeningScore'] ??
        data['variationScore'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }

  bool _matchesSelectedTest(String type) {
    final normalized = type.toLowerCase().trim();

    switch (_selectedTest) {
      case 'Finger Tapping':
        return normalized.contains('finger') || normalized.contains('tap');
      case 'Line Tracing':
        return normalized.contains('line');
      case 'Writing Test':
        return normalized.contains('writing') ||
            normalized.contains('handwriting');
      case 'Spiral Trace':
        return normalized.contains('spiral');
    }

    return false;
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return '--';
    }

    final date = timestamp.toDate();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month';
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
          'Motor Progress',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: user == null
          ? _buildNoUser()
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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

                final documents =
                    snapshot.data?.docs ?? [];

                return _buildContent(documents);
              },
            ),
    );
  }

  Widget _buildContent(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final records = documents.where((document) {
      final data = document.data();
      final type = data['testType']?.toString() ?? '';

      return _matchesSelectedTest(type);
    }).toList();

    records.sort((a, b) {
      final aTime = a.data()['createdAt'];
      final bTime = b.data()['createdAt'];

      if (aTime is Timestamp && bTime is Timestamp) {
        return aTime.compareTo(bTime);
      }

      return 0;
    });

    final validRecords = records.where((record) {
      return _readScore(record.data()) != null;
    }).toList();

    final scores = validRecords.map((record) {
      return _readScore(record.data())!;
    }).toList();

    final latestScore =
        scores.isNotEmpty ? scores.last : null;

    final previousScore =
        scores.length >= 2 ? scores[scores.length - 2] : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          const SizedBox(height: 20),

          _buildTestSelector(),

          const SizedBox(height: 20),

          _buildLatestScoreCard(
            latestScore,
            previousScore,
          ),

          const SizedBox(height: 20),

          _buildChartCard(
            validRecords,
            scores,
          ),

          const SizedBox(height: 20),

          _buildInterpretation(
            scores,
          ),

          const SizedBox(height: 20),

          _buildAssessmentCount(
            scores.length,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.show_chart_rounded,
            color: Color(0xFF4D8EDC),
            size: 36,
          ),
          SizedBox(height: 12),
          Text(
            'Motor Progress',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF25324A),
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Track how your assessment scores change '
            'over time.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: Color(0xFF68758A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E7F0),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTest,
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
          ),
          items: _testNames.map((test) {
            return DropdownMenuItem<String>(
              value: test,
              child: Row(
                children: [
                  Icon(
                    _testIcon(test),
                    size: 21,
                    color: _testColor(test),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    test,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF303C52),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _selectedTest = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildLatestScoreCard(
    double? latestScore,
    double? previousScore,
  ) {
    final color = _testColor(_selectedTest);

    String changeText = 'No previous result';

    if (latestScore != null && previousScore != null) {
      final difference = latestScore - previousScore;

      if (difference > 0) {
        changeText =
            '+${difference.toStringAsFixed(1)}% from previous';
      } else if (difference < 0) {
        changeText =
            '${difference.toStringAsFixed(1)}% from previous';
      } else {
        changeText = 'Same as previous assessment';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE2E7F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              _testIcon(_selectedTest),
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest $_selectedTest score',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7A8499),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  latestScore == null
                      ? '--'
                      : '${latestScore.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  changeText,
                  style: const TextStyle(
                    fontSize: 11.5,
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

  Widget _buildChartCard(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> records,
    List<double> scores,
  ) {
    final color = _testColor(_selectedTest);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        15,
        18,
        15,
        15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE2E7F0),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 5,
            ),
            child: Text(
              'Score Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF25324A),
              ),
            ),
          ),

          const SizedBox(height: 5),

          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 5,
            ),
            child: Text(
              'Your assessment scores over time',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF7A8499),
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (scores.length < 2)
            _buildNotEnoughData()
          else
            SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  minX: 0,
                  maxX: (scores.length - 1)
                      .toDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: 20,
                        getTitlesWidget:
                            (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(
                              fontSize: 9,
                              color:
                                  Color(0xFF8A94A5),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget:
                            (value, meta) {
                          final index =
                              value.toInt();

                          if (index < 0 ||
                              index >=
                                  records.length) {
                            return const SizedBox();
                          }

                          final timestamp =
                              records[index]
                                  .data()['createdAt'];

                          final date =
                              timestamp is Timestamp
                                  ? timestamp
                                  : null;

                          return Padding(
                            padding:
                                const EdgeInsets.only(
                              top: 8,
                            ),
                            child: Text(
                              _formatDate(date),
                              style:
                                  const TextStyle(
                                fontSize: 9,
                                color:
                                    Color(0xFF8A94A5),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData:
                        LineTouchTooltipData(
                      getTooltipItems:
                          (touchedSpots) {
                        return touchedSpots.map(
                          (spot) {
                            return LineTooltipItem(
                              '${spot.y.toStringAsFixed(1)}%',
                              const TextStyle(
                                fontWeight:
                                    FontWeight.w700,
                                color: Colors.white,
                              ),
                            );
                          },
                        ).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        scores.length,
                        (index) {
                          return FlSpot(
                            index.toDouble(),
                            scores[index]
                                .clamp(0, 100),
                          );
                        },
                      ),
                      isCurved: true,
                      barWidth: 3,
                      color: color,
                      dotData: FlDotData(
                        show: true,
                      ),
                      belowBarData:
                          BarAreaData(
                        show: true,
                        color:
                            color.withOpacity(0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotEnoughData() {
    return Container(
      height: 190,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(25),
      child: const Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insights_rounded,
            size: 42,
            color: Color(0xFFB5C0D0),
          ),
          SizedBox(height: 12),
          Text(
            'Not enough data yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4A566A),
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Complete at least two assessments '
            'to see your progress trend.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: Color(0xFF7A8499),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterpretation(
    List<double> scores,
  ) {
    String message;

    if (scores.isEmpty) {
      message =
          'No completed $_selectedTest assessments '
          'are available yet.';
    } else if (scores.length == 1) {
      message =
          'Your first $_selectedTest assessment has '
          'been recorded. Complete another assessment '
          'to begin tracking your progress over time.';
    } else {
      final latest = scores.last;
      final previous = scores[scores.length - 2];
      final difference = latest - previous;

      if (difference > 2) {
        message =
            'Your latest score is higher than your '
            'previous assessment by '
            '${difference.toStringAsFixed(1)}%.';
      } else if (difference < -2) {
        message =
            'Your latest score is lower than your '
            'previous assessment by '
            '${difference.abs().toStringAsFixed(1)}%. '
            'Consider repeating the assessment while '
            'following the instructions carefully.';
      } else {
        message =
            'Your latest score is relatively close to '
            'your previous assessment, indicating a '
            'similar recorded performance.';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF4D8EDC),
            size: 23,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progress insight',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF303C52),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
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

  Widget _buildAssessmentCount(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E7F0),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.history_rounded,
            color: Color(0xFF4D8EDC),
          ),
          const SizedBox(width: 11),
          Text(
            '$count ${_selectedTest} assessment'
            '${count == 1 ? '' : 's'} recorded',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4A566A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoUser() {
    return const Center(
      child: Text(
        'Please log in to view motor progress.',
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
              'Unable to load progress',
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
