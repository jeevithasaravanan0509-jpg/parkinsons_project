import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WritingTestScreen extends StatefulWidget {
  const WritingTestScreen({super.key});

  @override
  State<WritingTestScreen> createState() => _WritingTestScreenState();
}

class _WritingTestScreenState extends State<WritingTestScreen> {
  final List<Offset> _points = [];

  DateTime? _startTime;

  bool _isWriting = false;
  bool _completed = false;
  bool _isSaving = false;

  double? _score;
  double? _smoothness;
  double? _duration;
  int _strokeCount = 0;

  static const String _phrase =
      'Today is a good day';

  void _startTest() {
    setState(() {
      _points.clear();
      _startTime = DateTime.now();

      _isWriting = true;
      _completed = false;
      _isSaving = false;

      _score = null;
      _smoothness = null;
      _duration = null;
      _strokeCount = 0;
    });
  }

  void _startStroke(Offset point, Size size) {
    if (!_isWriting) return;

    if (_points.isEmpty) {
      _startTime ??= DateTime.now();
    }

    _addPoint(point, size);
  }

  void _updateStroke(Offset point, Size size) {
    if (!_isWriting) return;

    _addPoint(point, size);
  }

  void _endStroke() {
    if (!_isWriting) return;

    setState(() {
      _strokeCount++;
    });
  }

  void _addPoint(Offset point, Size size) {
    final normalizedPoint = Offset(
      (point.dx / size.width).clamp(0.0, 1.0),
      (point.dy / size.height).clamp(0.0, 1.0),
    );

    setState(() {
      _points.add(normalizedPoint);
    });
  }

  void _finishTest() {
    if (!_isWriting || _points.length < 10) {
      _showMessage(
        'Please write something before finishing the test.',
      );
      return;
    }

    final endTime = DateTime.now();

    final duration =
        endTime.difference(_startTime ?? endTime).inMilliseconds / 1000;

    final smoothness = _calculateSmoothness();

    final calculatedScore =
        (smoothness * 100).clamp(0.0, 100.0).toDouble();

    setState(() {
      _isWriting = false;
      _completed = true;

      _duration = duration;
      _smoothness = smoothness;
      _score = calculatedScore;
    });

    _saveResult(
      score: calculatedScore,
      smoothness: smoothness,
      duration: duration,
    );
  }

  double _calculateSmoothness() {
    if (_points.length < 3) {
      return 0;
    }

    double totalAngleChange = 0;
    int angleCount = 0;

    for (int i = 1; i < _points.length - 1; i++) {
      final previous = _points[i - 1];
      final current = _points[i];
      final next = _points[i + 1];

      final firstVector = Offset(
        current.dx - previous.dx,
        current.dy - previous.dy,
      );

      final secondVector = Offset(
        next.dx - current.dx,
        next.dy - current.dy,
      );

      final firstMagnitude = math.sqrt(
        firstVector.dx * firstVector.dx +
            firstVector.dy * firstVector.dy,
      );

      final secondMagnitude = math.sqrt(
        secondVector.dx * secondVector.dx +
            secondVector.dy * secondVector.dy,
      );

      if (firstMagnitude == 0 || secondMagnitude == 0) {
        continue;
      }

      final dotProduct =
          firstVector.dx * secondVector.dx +
          firstVector.dy * secondVector.dy;

      final cosine =
          (dotProduct / (firstMagnitude * secondMagnitude))
              .clamp(-1.0, 1.0);

      final angle = math.acos(cosine);

      totalAngleChange += angle;
      angleCount++;
    }

    if (angleCount == 0) {
      return 0;
    }

    final averageAngle =
        totalAngleChange / angleCount;

    final normalized =
        1 - (averageAngle / math.pi);

    return normalized.clamp(0.0, 1.0).toDouble();
  }

  Future<void> _saveResult({
    required double score,
    required double smoothness,
    required double duration,
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
        'testType': 'writing_test',
        'phrase': _phrase,
        'score': score,
        'smoothness': smoothness,
        'durationSeconds': duration,
        'pointsRecorded': _points.length,
        'strokeCount': _strokeCount,
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

  void _resetTest() {
    setState(() {
      _points.clear();
      _startTime = null;

      _isWriting = false;
      _completed = false;
      _isSaving = false;

      _score = null;
      _smoothness = null;
      _duration = null;
      _strokeCount = 0;
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
          'Writing Test',
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

              const SizedBox(height: 20),

              _buildInstructionCard(),

              const SizedBox(height: 18),

              _buildWritingArea(),

              const SizedBox(height: 20),

              if (!_isWriting && !_completed)
                _buildStartButton(),

              if (_isWriting)
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
            Icons.edit_rounded,
            color: Color(0xFF4D8EDC),
            size: 36,
          ),
          SizedBox(height: 12),
          Text(
            'Handwriting Test',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF25324A),
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Write the displayed phrase naturally. '
            'The app records your movement while you write.',
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Write this phrase:',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF7A8499),
            ),
          ),
          SizedBox(height: 7),
          Text(
            _phrase,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF303C52),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Use your finger and write naturally. '
            'Do not worry about making it perfect.',
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

  Widget _buildWritingArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 300.0;

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
              _startStroke(
                details.localPosition,
                Size(width, height),
              );
            },
            onPanUpdate: (details) {
              _updateStroke(
                details.localPosition,
                Size(width, height),
              );
            },
            onPanEnd: (_) {
              _endStroke();
            },
            child: CustomPaint(
              painter: _WritingPainter(
                points: _points,
                isWriting: _isWriting,
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
        onPressed: _startTest,
        icon: const Icon(
          Icons.play_arrow_rounded,
        ),
        label: const Text(
          'Start Writing Test',
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
        label: const Text(
          'Finish Test',
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
    );
  }

  Widget _buildResultCard() {
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
            'Movement Smoothness',
            '${((_smoothness ?? 0) * 100).toStringAsFixed(1)}%',
            Icons.waves_rounded,
          ),

          const SizedBox(height: 10),

          _resultItem(
            'Strokes Recorded',
            '$_strokeCount',
            Icons.gesture_rounded,
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
              'Your writing movement has been recorded '
              'for future progress tracking.',
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
        onPressed: _isSaving ? null : _resetTest,
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

class _WritingPainter extends CustomPainter {
  final List<Offset> points;
  final bool isWriting;
  final bool isCompleted;

  _WritingPainter({
    required this.points,
    required this.isWriting,
    required this.isCompleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = const Color(0xFFCFD7E5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final writingPaint = Paint()
      ..color = const Color(0xFF4D8EDC)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Writing guidelines.
    final baseline = size.height * 0.67;
    final midline = size.height * 0.48;
    final topLine = size.height * 0.29;

    canvas.drawLine(
      Offset(20, topLine),
      Offset(size.width - 20, topLine),
      guidePaint,
    );

    canvas.drawLine(
      Offset(20, midline),
      Offset(size.width - 20, midline),
      guidePaint,
    );

    canvas.drawLine(
      Offset(20, baseline),
      Offset(size.width - 20, baseline),
      guidePaint,
    );

    // Patient writing path.
    if (points.isNotEmpty) {
      final path = Path();

      for (int i = 0; i < points.length; i++) {
        final point = Offset(
          points[i].dx * size.width,
          points[i].dy * size.height,
        );

        if (i == 0) {
          path.moveTo(
            point.dx,
            point.dy,
          );
        } else {
          path.lineTo(
            point.dx,
            point.dy,
          );
        }
      }

      canvas.drawPath(
        path,
        writingPaint,
      );
    }

    if (!isWriting && !isCompleted && points.isEmpty) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'Write here',
          style: TextStyle(
            color: Color(0xFFB1BAC8),
            fontSize: 18,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          size.height * 0.74,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _WritingPainter oldDelegate,
  ) {
    return oldDelegate.points != points ||
        oldDelegate.isWriting != isWriting ||
        oldDelegate.isCompleted != isCompleted;
  }
}