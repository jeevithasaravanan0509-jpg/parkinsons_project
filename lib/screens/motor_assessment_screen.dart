import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MotorAssessmentScreen extends StatefulWidget {
  const MotorAssessmentScreen({super.key});

  @override
  State<MotorAssessmentScreen> createState() =>
      _MotorAssessmentScreenState();
}

class _MotorAssessmentScreenState
    extends State<MotorAssessmentScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // =========================================================
  // DRAWING DATA
  // =========================================================

  final ValueNotifier<List<Offset>> _pointsNotifier =
      ValueNotifier<List<Offset>>(<Offset>[]);

  final List<Offset> _userPoints = [];

  bool _testStarted = false;
  bool _isDrawing = false;
  bool _hasCompleted = false;
  bool _isSaving = false;

  double? _deviationScore;
  double? _smoothnessScore;
  double? _screeningScore;

  String _resultTitle = '';
  String _resultDescription = '';

  // =========================================================
  // CONSTANTS
  // =========================================================

  static const double _spiralTurns = 3.2;

  static const double _minimumPointDistance = 1.5;

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _pointsNotifier.dispose();
    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

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
          'Motor Assessment',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: _testStarted && !_hasCompleted
            ? _buildActiveTestScreen()
            : _buildNormalScreen(),
      ),
    );
  }

  // =========================================================
  // NORMAL SCREEN
  // =========================================================

  Widget _buildNormalScreen() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        35,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          const SizedBox(height: 20),

          _buildInstructionCard(),

          const SizedBox(height: 20),

          _buildTracingCard(),

          if (_hasCompleted) ...[
            const SizedBox(height: 20),
            _buildResultCard(),
            const SizedBox(height: 18),
            _buildDisclaimer(),
            const SizedBox(height: 20),
            _buildSaveButton(),
            const SizedBox(height: 12),
            _buildRetestButton(),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // ACTIVE TEST SCREEN
  // =========================================================

  Widget _buildActiveTestScreen() {
    return PopScope(
      canPop: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          20,
        ),
        child: Column(
          children: [
            _buildActiveTestHeader(),

            const SizedBox(height: 12),

            Expanded(
              child: _buildFixedDrawingArea(),
            ),

            const SizedBox(height: 12),

            _buildActiveTestInstruction(),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ACTIVE TEST HEADER
  // =========================================================

  Widget _buildActiveTestHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE3E8F2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF0),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.circle,
              size: 12,
              color: Color(0xFFD86B78),
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Test in progress',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF25324A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Keep your finger on the spiral and trace slowly.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF7E899C),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF0),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: const Text(
              'RECORDING',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Color(0xFFD05D6B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ACTIVE TEST INSTRUCTION
  // =========================================================

  Widget _buildActiveTestInstruction() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.touch_app_rounded,
            size: 20,
            color: Color(0xFF6C63FF),
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Trace from the outer starting point toward the center. '
              'Lift your finger when you finish.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: Color(0xFF5F6D86),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader() {
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
        borderRadius:
            BorderRadius.circular(25),
      ),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.gesture_rounded,
            size: 34,
            color: Color(0xFF6C63FF),
          ),
          SizedBox(height: 14),
          Text(
            'Guided Motor Test',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: Color(0xFF25324A),
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Let the app study your hand movement '
            'instead of asking you to guess a symptom score.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF68758A),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // INSTRUCTIONS
  // =========================================================

  Widget _buildInstructionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE3E8F2),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.touch_app_rounded,
              color: Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'How to perform the test',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF303C52),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Press Start Test first. The screen will lock in place '
                  'so you can trace without accidentally scrolling. '
                  'Start from the marked point and slowly follow the spiral.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
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
  // TRACING CARD
  // =========================================================

  Widget _buildTracingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 4),

          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trace the spiral',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF25324A),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Start the test when you are ready',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8993A6),
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasCompleted)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF55A88A),
                  size: 25,
                ),
            ],
          ),

          const SizedBox(height: 14),

          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(20),
              child: Container(
                color: const Color(0xFFFAFBFF),
                child: _buildPreviewDrawingArea(),
              ),
            ),
          ),

          const SizedBox(height: 14),

          if (!_hasCompleted)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _startTest,
                icon: const Icon(
                  Icons.play_arrow_rounded,
                ),
                label: const Text(
                  'Start Test',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF6385E5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(17),
                  ),
                ),
              ),
            ),

          if (!_hasCompleted) ...[
            const SizedBox(height: 10),
            const Text(
              'The test will begin after you press Start Test.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF9AA3B3),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // PREVIEW DRAWING AREA
  // =========================================================

  Widget _buildPreviewDrawingArea() {
    return CustomPaint(
      painter: const _SpiralPainter(
        userPoints: <Offset>[],
      ),
      child: const SizedBox.expand(),
    );
  }

  // =========================================================
  // FIXED DRAWING AREA
  // =========================================================

  Widget _buildFixedDrawingArea() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE1E6F0),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(23),
        child: Container(
          color: const Color(0xFFFAFBFF),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,

            // -------------------------------------------------
            // START DRAWING
            // -------------------------------------------------

            onPanStart: (details) {
              if (!_testStarted ||
                  _hasCompleted) {
                return;
              }

              _userPoints.clear();

              final point =
                  details.localPosition;

              _userPoints.add(point);

              _pointsNotifier.value =
                  List<Offset>.from(
                _userPoints,
              );

              if (mounted) {
                setState(() {
                  _isDrawing = true;
                });
              }
            },

            // -------------------------------------------------
            // DRAWING UPDATE
            // -------------------------------------------------

            onPanUpdate: (details) {
              if (!_testStarted ||
                  _hasCompleted ||
                  !_isDrawing) {
                return;
              }

              final point =
                  details.localPosition;

              if (_userPoints.isNotEmpty) {
                final previous =
                    _userPoints.last;

                final distance =
                    (point - previous).distance;

                if (distance <
                    _minimumPointDistance) {
                  return;
                }
              }

              _userPoints.add(point);

              _pointsNotifier.value =
                  List<Offset>.from(
                _userPoints,
              );
            },

            // -------------------------------------------------
            // END DRAWING
            // -------------------------------------------------

            onPanEnd: (_) {
              if (!_testStarted ||
                  _hasCompleted ||
                  !_isDrawing) {
                return;
              }

              if (mounted) {
                setState(() {
                  _isDrawing = false;
                });
              }

              _analyzeDrawing();
            },

            // -------------------------------------------------
            // CANCEL
            // -------------------------------------------------

            onPanCancel: () {
              if (!_testStarted ||
                  _hasCompleted ||
                  !_isDrawing) {
                return;
              }

              if (mounted) {
                setState(() {
                  _isDrawing = false;
                });
              }

              if (_userPoints.length >= 20) {
                _analyzeDrawing();
              }
            },

            child:
                ValueListenableBuilder<
                    List<Offset>>(
              valueListenable:
                  _pointsNotifier,
              builder: (
                context,
                points,
                child,
              ) {
                return CustomPaint(
                  painter: _SpiralPainter(
                    userPoints: points,
                  ),
                  child:
                      const SizedBox.expand(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // START TEST
  // =========================================================

  void _startTest() {
    _userPoints.clear();

    _pointsNotifier.value =
        <Offset>[];

    setState(() {
      _testStarted = true;
      _isDrawing = false;
      _hasCompleted = false;
      _isSaving = false;

      _deviationScore = null;
      _smoothnessScore = null;
      _screeningScore = null;

      _resultTitle = '';
      _resultDescription = '';
    });
  }

  // =========================================================
  // ANALYSIS
  // =========================================================

  void _analyzeDrawing() {
    if (_userPoints.length < 20) {
      _showMessage(
        'Please trace more of the pattern and try again.',
      );

      _userPoints.clear();

      _pointsNotifier.value =
          <Offset>[];

      if (mounted) {
        setState(() {
          _testStarted = true;
          _isDrawing = false;
        });
      }

      return;
    }

    final renderBox =
        context.findRenderObject()
            as RenderBox?;

    final drawingSize =
        renderBox?.size.width ??
            MediaQuery.of(context).size.width;

    final normalizedPoints =
        _normalizePoints(
      _userPoints,
      drawingSize,
    );

    final averageDeviation =
        _calculateAverageDeviation(
      normalizedPoints,
    );

    final smoothnessPenalty =
        _calculateSmoothness(
      normalizedPoints,
    );

    final deviationComponent =
        (averageDeviation / 35)
            .clamp(0.0, 1.0);

    final smoothnessComponent =
        (smoothnessPenalty / 0.35)
            .clamp(0.0, 1.0);

    final combined =
        (deviationComponent * 0.70) +
        (smoothnessComponent * 0.30);

    final screeningScore =
        (combined * 100)
            .clamp(0.0, 100.0)
            .toDouble();

    String title;
    String description;

    if (screeningScore < 30) {
      title =
          'Movement looks relatively steady';

      description =
          'Your traced path stayed reasonably close '
          'to the guided pattern during this test.';
    } else if (screeningScore < 60) {
      title =
          'Some movement variation detected';

      description =
          'The traced path showed some deviation or '
          'irregular movement. Consider repeating the '
          'test under similar conditions.';
    } else {
      title =
          'Higher movement variation detected';

      description =
          'The traced path showed greater deviation '
          'or irregularity during this test. A healthcare '
          'professional should interpret this result.';
    }

    if (!mounted) return;

    setState(() {
      _deviationScore =
          averageDeviation;

      _smoothnessScore =
          smoothnessPenalty;

      _screeningScore =
          screeningScore;

      _resultTitle =
          title;

      _resultDescription =
          description;

      _isDrawing = false;
      _testStarted = false;
      _hasCompleted = true;
    });
  }

  // =========================================================
  // NORMALIZE POINTS
  // =========================================================

  List<Offset> _normalizePoints(
    List<Offset> points,
    double drawingSize,
  ) {
    if (points.isEmpty ||
        drawingSize <= 0) {
      return <Offset>[];
    }

    return points.map((point) {
      return Offset(
        point.dx / drawingSize * 300,
        point.dy / drawingSize * 300,
      );
    }).toList();
  }

  // =========================================================
  // DEVIATION
  // =========================================================

  double _calculateAverageDeviation(
    List<Offset> points,
  ) {
    if (points.isEmpty) {
      return 0;
    }

    const center =
        Offset(150, 150);

    const maxRadius =
        120.0;

    double totalDeviation = 0;

    for (final point in points) {
      final dx =
          point.dx - center.dx;

      final dy =
          point.dy - center.dy;

      final distanceFromCenter =
          math.sqrt(
        dx * dx + dy * dy,
      );

      double angle =
          math.atan2(
        dy,
        dx,
      );

      if (angle < 0) {
        angle += 2 * math.pi;
      }

      double bestDeviation =
          double.infinity;

      for (int turn = 0;
          turn <= 3;
          turn++) {
        final totalAngle =
            angle +
            (turn * 2 * math.pi);

        final progress =
            totalAngle /
                (_spiralTurns *
                    2 *
                    math.pi);

        if (progress < 0 ||
            progress > 1) {
          continue;
        }

        final expectedRadius =
            maxRadius *
            (1 - progress);

        final deviation =
            (distanceFromCenter -
                    expectedRadius)
                .abs();

        if (deviation <
            bestDeviation) {
          bestDeviation =
              deviation;
        }
      }

      if (bestDeviation ==
          double.infinity) {
        bestDeviation =
            distanceFromCenter;
      }

      totalDeviation +=
          bestDeviation;
    }

    return totalDeviation /
        points.length;
  }

  // =========================================================
  // SMOOTHNESS
  // =========================================================

  double _calculateSmoothness(
    List<Offset> points,
  ) {
    if (points.length < 3) {
      return 0;
    }

    double totalDirectionChange =
        0;

    int validSamples = 0;

    for (int i = 2;
        i < points.length;
        i++) {
      final p1 =
          points[i - 2];

      final p2 =
          points[i - 1];

      final p3 =
          points[i];

      final v1 =
          p2 - p1;

      final v2 =
          p3 - p2;

      final distance1 =
          v1.distance;

      final distance2 =
          v2.distance;

      if (distance1 < 0.5 ||
          distance2 < 0.5) {
        continue;
      }

      final angle1 =
          math.atan2(
        v1.dy,
        v1.dx,
      );

      final angle2 =
          math.atan2(
        v2.dy,
        v2.dx,
      );

      double difference =
          (angle2 - angle1)
              .abs();

      if (difference > math.pi) {
        difference =
            2 * math.pi -
                difference;
      }

      totalDirectionChange +=
          difference;

      validSamples++;
    }

    if (validSamples == 0) {
      return 0;
    }

    return totalDirectionChange /
        validSamples;
  }

  // =========================================================
  // RESULT CARD
  // =========================================================

  Widget _buildResultCard() {
    final score =
        _screeningScore ?? 0;

    final Color resultColor;

    if (score < 30) {
      resultColor =
          const Color(0xFF55A88A);
    } else if (score < 60) {
      resultColor =
          const Color(0xFFE1A34F);
    } else {
      resultColor =
          const Color(0xFFD86B78);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFFE3E8F2),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      resultColor.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: resultColor,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Movement Analysis',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF25324A),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Center(
            child: SizedBox(
              width: 145,
              height: 145,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 145,
                    height: 145,
                    child:
                        CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 12,
                      backgroundColor:
                          const Color(0xFFECEFF5),
                      valueColor:
                          AlwaysStoppedAnimation<
                              Color>(
                        resultColor,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Text(
                        score.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight:
                              FontWeight.w800,
                          color: resultColor,
                        ),
                      ),
                      const Text(
                        'variation',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Color(0xFF8993A6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: Text(
              _resultTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: resultColor,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _resultDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF727D90),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _resultMetric(
                  'Path deviation',
                  _deviationScore
                          ?.toStringAsFixed(1) ??
                      '--',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _resultMetric(
                  'Movement change',
                  _smoothnessScore
                          ?.toStringAsFixed(2) ??
                      '--',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // RESULT METRIC
  // =========================================================

  Widget _resultMetric(
    String title,
    String value,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FE),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF303C52),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF8993A6),
            ),
          ),
        ],
      ),
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
            BorderRadius.circular(16),
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
            size: 20,
            color: Color(0xFFB58532),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This is a software-based movement screening '
              'test, not a medical diagnosis. Results should '
              'be interpreted by a qualified healthcare professional.',
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
  // SAVE BUTTON
  // =========================================================

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed:
            _isSaving ? null : _saveResult,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.cloud_upload_outlined,
              ),
        label: Text(
          _isSaving
              ? 'Saving Result...'
              : 'Save Assessment Result',
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF6385E5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // FIRESTORE
  // =========================================================

  Future<void> _saveResult() async {
    final user =
        _auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please log in before saving the result.',
      );
      return;
    }

    if (_screeningScore == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('motor_assessments')
          .add({
        'userId': user.uid,
        'source':
            'software_motor_assessment',
        'testType':
            'guided_spiral_trace',
        'score': _screeningScore,
        'screeningScore':
            _screeningScore,
        'pathDeviation':
            _deviationScore,
        'movementVariation':
            _smoothnessScore,
        'result':
            _resultTitle,
        'createdAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showMessage(
        'Motor assessment saved successfully.',
      );
    } on FirebaseException catch (e) {
      _showMessage(
        e.message ??
            'Unable to save the assessment.',
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

  // =========================================================
  // RETEST
  // =========================================================

  Widget _buildRetestButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed:
            _isSaving ? null : _resetTest,
        icon: const Icon(
          Icons.refresh_rounded,
        ),
        label: const Text(
          'Try Again',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              const Color(0xFF8B78D9),
          side: const BorderSide(
            color: Color(0xFF8B78D9),
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // RESET
  // =========================================================

  void _resetTest() {
    _userPoints.clear();

    _pointsNotifier.value =
        <Offset>[];

    setState(() {
      _testStarted = false;
      _isDrawing = false;
      _hasCompleted = false;
      _isSaving = false;

      _deviationScore = null;
      _smoothnessScore = null;
      _screeningScore = null;

      _resultTitle = '';
      _resultDescription = '';
    });
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
      ),
    );
  }
}

// =============================================================
// SPIRAL PAINTER
// =============================================================

class _SpiralPainter extends CustomPainter {
  final List<Offset> userPoints;

  const _SpiralPainter({
    required this.userPoints,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final maxRadius =
        math.min(
          size.width,
          size.height,
        ) *
        0.40;

    // ---------------------------------------------------------
    // TARGET SPIRAL
    // ---------------------------------------------------------

    final targetPaint = Paint()
      ..color =
          const Color(0xFFB8C3E8)
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap =
          StrokeCap.round;

    final targetPath =
        Path();

    const turns = 3.2;

    const samples = 220;

    for (int i = 0;
        i < samples;
        i++) {
      final t =
          i / (samples - 1);

      final angle =
          t *
          turns *
          2 *
          math.pi;

      final radius =
          maxRadius *
          (1 - t);

      final point = Offset(
        center.dx +
            radius *
                math.cos(angle),
        center.dy +
            radius *
                math.sin(angle),
      );

      if (i == 0) {
        targetPath.moveTo(
          point.dx,
          point.dy,
        );
      } else {
        targetPath.lineTo(
          point.dx,
          point.dy,
        );
      }
    }

    canvas.drawPath(
      targetPath,
      targetPaint,
    );

    // ---------------------------------------------------------
    // START POINT
    // ---------------------------------------------------------

    final startPaint = Paint()
      ..color =
          const Color(0xFF6C63FF);

    canvas.drawCircle(
      Offset(
        center.dx + maxRadius,
        center.dy,
      ),
      7,
      startPaint,
    );

    // ---------------------------------------------------------
    // USER TRACE
    // ---------------------------------------------------------

    if (userPoints.isEmpty) {
      return;
    }

    final userPaint = Paint()
      ..color =
          const Color(0xFF6385E5)
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap =
          StrokeCap.round
      ..strokeJoin =
          StrokeJoin.round;

    final userPath =
        Path();

    userPath.moveTo(
      userPoints.first.dx,
      userPoints.first.dy,
    );

    for (int i = 1;
        i < userPoints.length;
        i++) {
      final previous =
          userPoints[i - 1];

      final current =
          userPoints[i];

      final midpoint = Offset(
        (previous.dx +
                current.dx) /
            2,
        (previous.dy +
                current.dy) /
            2,
      );

      if (i == 1) {
        userPath.lineTo(
          midpoint.dx,
          midpoint.dy,
        );
      } else {
        userPath.quadraticBezierTo(
          previous.dx,
          previous.dy,
          midpoint.dx,
          midpoint.dy,
        );
      }
    }

    final last =
        userPoints.last;

    userPath.lineTo(
      last.dx,
      last.dy,
    );

    canvas.drawPath(
      userPath,
      userPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _SpiralPainter oldDelegate,
  ) {
    return oldDelegate.userPoints !=
        userPoints;
  }
}

