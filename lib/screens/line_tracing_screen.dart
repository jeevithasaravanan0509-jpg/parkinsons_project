import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LineTracingScreen extends StatefulWidget {
  const LineTracingScreen({super.key});

  @override
  State<LineTracingScreen> createState() => _LineTracingScreenState();
}

class _LineTracingScreenState extends State<LineTracingScreen> {
  final List<Offset> _points = [];

  DateTime? _startTime;

  bool _showInstructions = true;
  bool _isPractice = false;
  bool _isTesting = false;
  bool _completed = false;
  bool _isSaving = false;

  double? _score;
  double? _duration;
  double? _deviation;

  int _pointsRecorded = 0;

  static const double _pathWidth = 70.0;

  void _startPractice() {
    setState(() {
      _points.clear();
      _startTime = DateTime.now();

      _showInstructions = false;
      _isPractice = true;
      _isTesting = true;
      _completed = false;
      _isSaving = false;

      _score = null;
      _duration = null;
      _deviation = null;
      _pointsRecorded = 0;
    });
  }

  void _startActualTest() {
    setState(() {
      _points.clear();
      _startTime = DateTime.now();

      _showInstructions = false;
      _isPractice = false;
      _isTesting = true;
      _completed = false;
      _isSaving = false;

      _score = null;
      _duration = null;
      _deviation = null;
      _pointsRecorded = 0;
    });
  }

  void _addPoint(Offset point, Size size) {
    if (!_isTesting) return;

    final normalizedPoint = Offset(
      (point.dx / size.width).clamp(0.0, 1.0),
      (point.dy / size.height).clamp(0.0, 1.0),
    );

    setState(() {
      _points.add(normalizedPoint);
      _pointsRecorded = _points.length;
    });
  }

  void _finishTest() {
    if (!_isTesting || _points.length < 5) {
      _showMessage(
        'Please trace the path before finishing.',
      );
      return;
    }

    final endTime = DateTime.now();

    final duration =
        endTime.difference(_startTime ?? endTime).inMilliseconds / 1000;

    final deviation = _calculateDeviation();

    final score =
        (100 - (deviation * 100)).clamp(0.0, 100.0).toDouble();

    final wasPractice = _isPractice;

    setState(() {
      _isTesting = false;
      _completed = true;

      _duration = duration;
      _deviation = deviation;
      _score = score;
    });

    if (!wasPractice) {
      _saveResult(
        score: score,
        duration: duration,
        deviation: deviation,
      );
    }
  }

  double _calculateDeviation() {
    if (_points.isEmpty) {
      return 1.0;
    }

    double totalDeviation = 0;

    for (final point in _points) {
      final expectedY = _expectedPathY(point.dx);

      final difference = (point.dy - expectedY).abs();

      totalDeviation += difference;
    }

    final averageDeviation =
        totalDeviation / _points.length;

    return averageDeviation.clamp(0.0, 1.0).toDouble();
  }

  double _expectedPathY(double x) {
    final center = 0.50;

    final wave =
        math.sin(x * math.pi * 2.5) * 0.16;

    return center + wave;
  }

  Future<void> _saveResult({
    required double score,
    required double duration,
    required double deviation,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('motor_assessments')
          .add({
        'testType': 'line_tracing',
        'score': score,
        'durationSeconds': duration,
        'deviation': deviation,
        'deviationPercentage': deviation * 100,
        'pointsRecorded': _pointsRecorded,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Assessment completed, but the result could not be saved.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _resetToInstructions() {
    setState(() {
      _points.clear();
      _startTime = null;

      _showInstructions = true;
      _isPractice = false;
      _isTesting = false;
      _completed = false;
      _isSaving = false;

      _score = null;
      _duration = null;
      _deviation = null;
      _pointsRecorded = 0;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FE),
        foregroundColor: const Color(0xFF25324A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Line Tracing Test',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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

              const SizedBox(height: 18),

              if (_showInstructions)
                _buildInstructionCard(),

              if (_showInstructions)
                const SizedBox(height: 18),

              _buildTracingArea(),

              const SizedBox(height: 20),

              if (_showInstructions)
                _buildStartButtons(),

              if (_isTesting)
                _buildFinishButton(),

              if (_completed)
                _buildResultCard(),

              if (_completed)
                const SizedBox(height: 15),

              if (_completed)
                _buildRetestButton(),

              const SizedBox(height: 20),

              _buildDisclaimer(),
            ],
          ),
        ),
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
            Icons.timeline_rounded,
            color: Color(0xFF4D8EDC),
            size: 36,
          ),
          SizedBox(height: 12),
          Text(
            'Line Tracing',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF25324A),
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Follow the guided path naturally using your finger.',
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

  Widget _buildInstructionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E7F0),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF4D8EDC),
              ),
              SizedBox(width: 9),
              Text(
                'How to perform the test',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF25324A),
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Text(
            '1. Place your finger at the START point.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF68758A),
              height: 1.5,
            ),
          ),
          SizedBox(height: 5),
          Text(
            '2. Follow the path from left to right.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF68758A),
              height: 1.5,
            ),
          ),
          SizedBox(height: 5),
          Text(
            '3. Try to stay close to the centre of the path.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF68758A),
              height: 1.5,
            ),
          ),
          SizedBox(height: 5),
          Text(
            '4. Move naturally. Do not rush.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF68758A),
              height: 1.5,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'A practice attempt is provided first so you can understand the task.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4D8EDC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTracingArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 320.0;

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE0E6F0),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: GestureDetector(
            onPanStart: (details) {
              _addPoint(
                details.localPosition,
                Size(width, height),
              );
            },
            onPanUpdate: (details) {
              _addPoint(
                details.localPosition,
                Size(width, height),
              );
            },
            child: CustomPaint(
              painter: _LineTracingPainter(
                points: _points,
                isTesting: _isTesting,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStartButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _startPractice,
            icon: const Icon(
              Icons.school_rounded,
            ),
            label: const Text(
              'Try Practice First',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4D8EDC),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _startActualTest,
            icon: const Icon(
              Icons.play_arrow_rounded,
            ),
            label: const Text(
              'Start Actual Test',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4D8EDC),
              side: const BorderSide(
                color: Color(0xFF4D8EDC),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinishButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _finishTest,
        icon: const Icon(
          Icons.check_rounded,
        ),
        label: Text(
          _isPractice
              ? 'Finish Practice'
              : 'Finish Assessment',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4D8EDC),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final score = _score ?? 0;
    final isPractice = _isPractice;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE1E7F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPractice
                ? 'Practice Complete'
                : 'Assessment Complete',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF25324A),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            isPractice
                ? 'This practice attempt is not included in your assessment history.'
                : _getResultSummary(score),
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: Color(0xFF69758A),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _resultItem(
                  'Score',
                  score.toStringAsFixed(1),
                  Icons.analytics_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _resultItem(
                  'Time',
                  '${_duration?.toStringAsFixed(1) ?? '--'} s',
                  Icons.timer_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          _resultItem(
            'Path Deviation',
            '${((_deviation ?? 0) * 100).toStringAsFixed(1)}%',
            Icons.timeline_rounded,
          ),

          const SizedBox(height: 10),

          _resultItem(
            'Points Recorded',
            '$_pointsRecorded',
            Icons.gesture_rounded,
          ),

          if (_isSaving) ...[
            const SizedBox(height: 15),
            const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Saving assessment...',
                  style: TextStyle(
                    color: Color(0xFF69758A),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getResultSummary(double score) {
    if (score >= 85) {
      return 'The tracing stayed relatively close to the guided path during this assessment, indicating good tracing accuracy.';
    }

    if (score >= 70) {
      return 'The tracing showed some deviation from the guided path. This may reflect variation in movement accuracy during the assessment.';
    }

    return 'The tracing showed greater deviation from the guided path during this assessment. Repeat testing can help monitor movement consistency.';
  }

  Widget _resultItem(
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FE),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: const Color(0xFF4D8EDC),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7A8499),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
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

  Widget _buildRetestButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _isSaving
            ? null
            : _resetToInstructions,
        icon: const Icon(
          Icons.refresh_rounded,
        ),
        label: const Text(
          'Back to Instructions',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4D8EDC),
          side: const BorderSide(
            color: Color(0xFF4D8EDC),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return const Text(
      'This assessment is designed for movement screening '
      'and progress tracking. It is not a standalone '
      'medical diagnosis.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 11.5,
        height: 1.45,
        color: Color(0xFF8A94A5),
      ),
    );
  }
}

class _LineTracingPainter extends CustomPainter {
  final List<Offset> points;
  final bool isTesting;

  _LineTracingPainter({
    required this.points,
    required this.isTesting,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final pathPaint = Paint()
      ..color = const Color(0xFFDCE9FA)
      ..strokeWidth = 70
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final centerPaint = Paint()
      ..color = const Color(0xFF4D8EDC)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final writingPaint = Paint()
      ..color = const Color(0xFF25324A)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final guidePath = Path();

    const int segments = 100;

    for (int i = 0; i <= segments; i++) {
      final x = i / segments;

      final y =
          0.50 +
          math.sin(x * math.pi * 2.5) * 0.16;

      final point = Offset(
        x * size.width,
        y * size.height,
      );

      if (i == 0) {
        guidePath.moveTo(
          point.dx,
          point.dy,
        );
      } else {
        guidePath.lineTo(
          point.dx,
          point.dy,
        );
      }
    }

    canvas.drawPath(
      guidePath,
      pathPaint,
    );

    canvas.drawPath(
      guidePath,
      centerPaint,
    );

    if (points.isNotEmpty) {
      final userPath = Path();

      for (int i = 0; i < points.length; i++) {
        final point = Offset(
          points[i].dx * size.width,
          points[i].dy * size.height,
        );

        if (i == 0) {
          userPath.moveTo(
            point.dx,
            point.dy,
          );
        } else {
          userPath.lineTo(
            point.dx,
            point.dy,
          );
        }
      }

      canvas.drawPath(
        userPath,
        writingPaint,
      );
    }

    final startPaint = Paint()
      ..color = const Color(0xFF4BAA8A);

    final endPaint = Paint()
      ..color = const Color(0xFFE28A55);

    final startY =
        (0.50) * size.height;

    final endX = size.width;
    final endY =
        (0.50 +
                math.sin(math.pi * 2.5) * 0.16) *
            size.height;

    canvas.drawCircle(
      Offset(20, startY),
      9,
      startPaint,
    );

    canvas.drawCircle(
      Offset(endX - 20, endY),
      9,
      endPaint,
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'START',
        style: TextStyle(
          color: Color(0xFF4BAA8A),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(
        12,
        startY - 30,
      ),
    );

    final endTextPainter = TextPainter(
      text: const TextSpan(
        text: 'END',
        style: TextStyle(
          color: Color(0xFFE28A55),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    endTextPainter.layout();

    endTextPainter.paint(
      canvas,
      Offset(
        size.width - endTextPainter.width - 12,
        endY - 30,
      ),
    );

    if (!isTesting && points.isEmpty) {
      final hintPainter = TextPainter(
        text: const TextSpan(
          text: 'Follow the blue path',
          style: TextStyle(
            color: Color(0xFF8A94A5),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      hintPainter.layout();

      hintPainter.paint(
        canvas,
        Offset(
          (size.width - hintPainter.width) / 2,
          size.height - 35,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _LineTracingPainter oldDelegate,
  ) {
    return oldDelegate.points != points ||
        oldDelegate.isTesting != isTesting;
  }
}