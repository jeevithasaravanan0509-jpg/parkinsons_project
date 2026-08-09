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
  bool _isTracing = false;
  bool _completed = false;
  bool _isSaving = false;

  double? _score;
  double? _deviation;
  double? _duration;

  // Target line coordinates are normalized from 0 to 1.
  // This makes the test work on different screen sizes.
  final List<Offset> _targetPoints = const [
    Offset(0.08, 0.50),
    Offset(0.15, 0.47),
    Offset(0.22, 0.44),
    Offset(0.29, 0.41),
    Offset(0.36, 0.39),
    Offset(0.43, 0.37),
    Offset(0.50, 0.36),
    Offset(0.57, 0.37),
    Offset(0.64, 0.39),
    Offset(0.71, 0.41),
    Offset(0.78, 0.44),
    Offset(0.85, 0.47),
    Offset(0.92, 0.50),
  ];

  void _startTracing() {
    setState(() {
      _points.clear();
      _score = null;
      _deviation = null;
      _duration = null;
      _completed = false;
      _isTracing = true;
      _startTime = DateTime.now();
    });
  }

  void _addPoint(Offset point, Size size) {
    if (!_isTracing) return;

    final normalizedPoint = Offset(
      (point.dx / size.width).clamp(0.0, 1.0),
      (point.dy / size.height).clamp(0.0, 1.0),
    );

    setState(() {
      _points.add(normalizedPoint);
    });
  }

  void _finishTracing() {
    if (!_isTracing || _points.length < 5) {
      return;
    }

    final endTime = DateTime.now();

    final duration =
        endTime.difference(_startTime ?? endTime).inMilliseconds / 1000;

    final averageDeviation = _calculateAverageDeviation();

    // Convert deviation into a simple screening score.
    // Smaller deviation = better tracing accuracy.
    final calculatedScore =
        (100 - (averageDeviation * 1000)).clamp(0.0, 100.0).toDouble();

    setState(() {
      _isTracing = false;
      _completed = true;
      _duration = duration;
      _deviation = averageDeviation;
      _score = calculatedScore;
    });

    _saveResult(
      score: calculatedScore,
      deviation: averageDeviation,
      duration: duration,
    );
  }

  double _calculateAverageDeviation() {
    if (_points.isEmpty) return 1.0;

    double totalDistance = 0;

    for (final patientPoint in _points) {
      double minimumDistance = double.infinity;

      for (final targetPoint in _targetPoints) {
        final distance = _distance(
          patientPoint,
          targetPoint,
        );

        if (distance < minimumDistance) {
          minimumDistance = distance;
        }
      }

      totalDistance += minimumDistance;
    }

    return totalDistance / _points.length;
  }

  double _distance(Offset a, Offset b) {
    final dx = a.dx - b.dx;
    final dy = a.dy - b.dy;

    return math.sqrt(
      (dx * dx) + (dy * dy),
    );
  }

  Future<void> _saveResult({
    required double score,
    required double deviation,
    required double duration,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

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
        'averageDeviation': deviation,
        'durationSeconds': duration,
        'pointsRecorded': _points.length,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Assessment completed, but the result could not be saved.',
            ),
          ),
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

  void _resetTest() {
    setState(() {
      _points.clear();
      _startTime = null;
      _isTracing = false;
      _completed = false;
      _isSaving = false;
      _score = null;
      _deviation = null;
      _duration = null;
    });
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
          'Line Tracing',
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
              _buildIntroduction(),

              const SizedBox(height: 20),

              _buildInstructionCard(),

              const SizedBox(height: 18),

              _buildTracingArea(),

              const SizedBox(height: 20),

              if (!_isTracing && !_completed)
                _buildStartButton(),

              if (_completed)
                _buildResultCard(),

              if (_completed)
                const SizedBox(height: 15),

              if (_completed)
                _buildRetestButton(),

              const SizedBox(height: 18),

              _buildDisclaimer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroduction() {
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
            color: Color(0xFF55A88A),
            size: 36,
          ),
          SizedBox(height: 12),
          Text(
            'Follow the line',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF25324A),
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Trace the path naturally. The app will record '
            'your finger movement and compare it with the '
            'target path.',
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE4E9F2),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.touch_app_rounded,
            color: Color(0xFF55A88A),
            size: 23,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Tap Start Test, then place your finger near '
              'the beginning of the line and follow it '
              'towards the end at your natural speed.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF69758A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTracingArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final drawingWidth = constraints.maxWidth;
        const drawingHeight = 260.0;

        return Container(
          width: drawingWidth,
          height: drawingHeight,
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
              if (!_isTracing) return;

              _addPoint(
                details.localPosition,
                Size(drawingWidth, drawingHeight),
              );
            },
            onPanUpdate: (details) {
              if (!_isTracing) return;

              _addPoint(
                details.localPosition,
                Size(drawingWidth, drawingHeight),
              );
            },
            onPanEnd: (_) {
              if (_isTracing) {
                _finishTracing();
              }
            },
            child: CustomPaint(
              painter: _LineTracingPainter(
                targetPoints: _targetPoints,
                patientPoints: _points,
                isTracing: _isTracing,
                isCompleted: _completed,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _startTracing,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text(
          'Start Test',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF55A88A),
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
    return Container(
      width: double.infinity,
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
          const Text(
            'Assessment Complete',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF25324A),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _resultItem(
                  'Movement Score',
                  '${_score?.toStringAsFixed(1) ?? '--'}',
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
            'Average Path Deviation',
            '${((_deviation ?? 0) * 100).toStringAsFixed(2)}%',
            Icons.compare_arrows_rounded,
          ),

          const SizedBox(height: 15),

          if (_isSaving)
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
            )
          else
            const Text(
              'Your movement data has been recorded for '
              'future progress tracking.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: Color(0xFF7A8499),
              ),
            ),
        ],
      ),
    );
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
            color: const Color(0xFF55A88A),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
        onPressed: _isSaving ? null : _resetTest,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text(
          'Try Again',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF55A88A),
          side: const BorderSide(
            color: Color(0xFF55A88A),
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
  final List<Offset> targetPoints;
  final List<Offset> patientPoints;
  final bool isTracing;
  final bool isCompleted;

  _LineTracingPainter({
    required this.targetPoints,
    required this.patientPoints,
    required this.isTracing,
    required this.isCompleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final targetPaint = Paint()
      ..color = const Color(0xFF55A88A)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final guidePaint = Paint()
      ..color = const Color(0xFF55A88A).withValues(alpha: 0.12)
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final patientPaint = Paint()
      ..color = const Color(0xFF6C63FF)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final targetPath = Path();

    for (int i = 0; i < targetPoints.length; i++) {
      final point = Offset(
        targetPoints[i].dx * size.width,
        targetPoints[i].dy * size.height,
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
      guidePaint,
    );

    canvas.drawPath(
      targetPath,
      targetPaint,
    );

    if (patientPoints.isNotEmpty) {
      final patientPath = Path();

      for (int i = 0; i < patientPoints.length; i++) {
        final point = Offset(
          patientPoints[i].dx * size.width,
          patientPoints[i].dy * size.height,
        );

        if (i == 0) {
          patientPath.moveTo(
            point.dx,
            point.dy,
          );
        } else {
          patientPath.lineTo(
            point.dx,
            point.dy,
          );
        }
      }

      canvas.drawPath(
        patientPath,
        patientPaint,
      );
    }

    final start = Offset(
      targetPoints.first.dx * size.width,
      targetPoints.first.dy * size.height,
    );

    final end = Offset(
      targetPoints.last.dx * size.width,
      targetPoints.last.dy * size.height,
    );

    final markerPaint = Paint()
      ..color = const Color(0xFF25324A)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      start,
      9,
      markerPaint,
    );

    canvas.drawCircle(
      end,
      9,
      markerPaint,
    );

    if (!isTracing && !isCompleted) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'Follow the green line',
          style: TextStyle(
            color: Color(0xFF8993A5),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          30,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _LineTracingPainter oldDelegate,
  ) {
    return oldDelegate.patientPoints != patientPoints ||
        oldDelegate.isTracing != isTracing ||
        oldDelegate.isCompleted != isCompleted;
  }
}