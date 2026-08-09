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

  final List<Offset> _userPoints = [];

  bool _isDrawing = false;
  bool _hasCompleted = false;
  bool _isSaving = false;

  double? _deviationScore;
  double? _smoothnessScore;
  double? _screeningScore;

  String _resultTitle = '';
  String _resultDescription = '';

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
      body: SingleChildScrollView(
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

            const SizedBox(height: 20),

            if (_hasCompleted)
              _buildResultCard(),

            if (_hasCompleted)
              const SizedBox(height: 18),

            if (_hasCompleted)
              _buildDisclaimer(),

            const SizedBox(height: 20),

            if (_hasCompleted)
              SizedBox(
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
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(17),
                    ),
                  ),
                ),
              ),

            if (_hasCompleted)
              const SizedBox(height: 12),

            if (_hasCompleted)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _resetTest,
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
                        const Color(0xFF6385E5),
                    side: const BorderSide(
                      color: Color(0xFFB9C8EE),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(17),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────

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
        borderRadius: BorderRadius.circular(25),
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

  // ─────────────────────────────────────────────
  // INSTRUCTIONS
  // ─────────────────────────────────────────────

  Widget _buildInstructionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                  'Place your finger on the starting point '
                  'and slowly trace the spiral toward the center. '
                  'Try to stay close to the guide.',
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

  // ─────────────────────────────────────────────
  // DRAWING AREA
  // ─────────────────────────────────────────────

  Widget _buildTracingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
                      'Follow the dotted guide',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8993A6),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isDrawing)
                const _LiveIndicator(),
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
                child: GestureDetector(
                  onPanStart: (details) {
                    if (_hasCompleted) return;

                    setState(() {
                      _isDrawing = true;
                      _userPoints.clear();
                      _userPoints.add(
                        details.localPosition,
                      );
                    });
                  },
                  onPanUpdate: (details) {
                    if (_hasCompleted ||
                        !_isDrawing) {
                      return;
                    }

                    setState(() {
                      _userPoints.add(
                        details.localPosition,
                      );
                    });
                  },
                  onPanEnd: (_) {
                    if (_hasCompleted ||
                        !_isDrawing) {
                      return;
                    }

                    setState(() {
                      _isDrawing = false;
                    });

                    _analyzeDrawing();
                  },
                  child: CustomPaint(
                    painter: _SpiralPainter(
                      userPoints: _userPoints,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _infoChip(
                  Icons.edit_rounded,
                  'Draw slowly',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _infoChip(
                  Icons.track_changes_rounded,
                  'Follow guide',
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Text(
            'The test records movement only while you trace.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF9AA3B3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(
    IconData icon,
    String text,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FD),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 17,
            color: const Color(0xFF6C63FF),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF68758A),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ANALYSIS
  // ─────────────────────────────────────────────

  void _analyzeDrawing() {
    if (_userPoints.length < 20) {
      _showMessage(
        'Please trace more of the pattern and try again.',
      );

      setState(() {
        _userPoints.clear();
      });

      return;
    }

    final target =
        _generateSpiralPoints();

    double totalDeviation = 0;

    for (final point in _userPoints) {
      double nearestDistance =
          double.infinity;

      for (final targetPoint in target) {
        final distance =
            (point - targetPoint).distance;

        if (distance < nearestDistance) {
          nearestDistance = distance;
        }
      }

      totalDeviation += nearestDistance;
    }

    final averageDeviation =
        totalDeviation / _userPoints.length;

    // Estimate movement smoothness.
    double totalDirectionChange = 0;

    for (int i = 2;
        i < _userPoints.length;
        i++) {
      final p1 = _userPoints[i - 2];
      final p2 = _userPoints[i - 1];
      final p3 = _userPoints[i];

      final v1 = p2 - p1;
      final v2 = p3 - p2;

      if (v1.distance == 0 ||
          v2.distance == 0) {
        continue;
      }

      final angle1 =
          math.atan2(v1.dy, v1.dx);

      final angle2 =
          math.atan2(v2.dy, v2.dx);

      double difference =
          (angle2 - angle1).abs();

      if (difference > math.pi) {
        difference =
            2 * math.pi - difference;
      }

      totalDirectionChange += difference;
    }

    final smoothnessPenalty =
        _userPoints.length > 2
            ? (totalDirectionChange /
                    (_userPoints.length - 2))
                .toDouble()
            : 0.0;

    // Convert measurements into a simple
    // screening-oriented score.
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
        (combined * 100).clamp(0.0, 100.0);

    String title;
    String description;

    if (screeningScore < 30) {
      title = 'Movement looks relatively steady';
      description =
          'Your traced path stayed reasonably close '
          'to the guided pattern during this test.';
    } else if (screeningScore < 60) {
      title = 'Some movement variation detected';
      description =
          'The traced path showed some deviation or '
          'irregular movement. Consider repeating the '
          'test under similar conditions.';
    } else {
      title = 'Higher movement variation detected';
      description =
          'The traced path showed greater deviation '
          'or irregularity during this test. A healthcare '
          'professional should interpret this result.';
    }

    setState(() {
      _deviationScore =
          averageDeviation;

      _smoothnessScore =
          smoothnessPenalty;

      _screeningScore =
          screeningScore;

      _resultTitle = title;

      _resultDescription =
          description;

      _hasCompleted = true;
    });
  }

  // ─────────────────────────────────────────────
  // SPIRAL GENERATION
  // ─────────────────────────────────────────────

  List<Offset> _generateSpiralPoints() {
    const center = Offset(150, 150);

    final List<Offset> points = [];

    const turns = 3.2;
    const maxRadius = 125.0;
    const samples = 420;

    for (int i = 0;
        i < samples;
        i++) {
      final t =
          i / (samples - 1);

      final angle =
          t * turns * 2 * math.pi;

      final radius =
          maxRadius * (1 - t);

      points.add(
        Offset(
          center.dx +
              radius * math.cos(angle),
          center.dy +
              radius * math.sin(angle),
        ),
      );
    }

    return points;
  }

  // ─────────────────────────────────────────────
  // RESULT CARD
  // ─────────────────────────────────────────────

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
                  color: resultColor.withValues(
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 145,
                  height: 145,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 12,
                    backgroundColor:
                        const Color(0xFFECEFF5),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
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

  Widget _resultMetric(
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
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

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(15),
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

  // ─────────────────────────────────────────────
  // FIRESTORE
  // ─────────────────────────────────────────────

  Future<void> _saveResult() async {
    final user = _auth.currentUser;

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
          .collection('symptom_assessments')
          .add({
        'userId': user.uid,

        'source':
            'software_motor_assessment',

        'testType':
            'guided_spiral_trace',

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

  // ─────────────────────────────────────────────
  // RESET
  // ─────────────────────────────────────────────

  void _resetTest() {
    setState(() {
      _userPoints.clear();

      _isDrawing = false;

      _hasCompleted = false;

      _deviationScore = null;

      _smoothnessScore = null;

      _screeningScore = null;

      _resultTitle = '';

      _resultDescription = '';
    });
  }

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

// ─────────────────────────────────────────────
// LIVE INDICATOR
// ─────────────────────────────────────────────

class _LiveIndicator extends StatelessWidget {
  const _LiveIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F1),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: Color(0xFF55A88A),
          ),
          SizedBox(width: 5),
          Text(
            'Recording',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4C927A),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SPIRAL PAINTER
// ─────────────────────────────────────────────

class _SpiralPainter extends CustomPainter {
  final List<Offset> userPoints;

  _SpiralPainter({
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

    // Target spiral
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
    const samples = 420;

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

    // Draw guide
    canvas.drawPath(
      targetPath,
      targetPaint,
    );

    // Start point
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

    // User's drawing
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
      userPath.lineTo(
        userPoints[i].dx,
        userPoints[i].dy,
      );
    }

    canvas.drawPath(
      userPath,
      userPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _SpiralPainter oldDelegate,
  ) {
    return oldDelegate.userPoints
            .length !=
        userPoints.length;
  }
}