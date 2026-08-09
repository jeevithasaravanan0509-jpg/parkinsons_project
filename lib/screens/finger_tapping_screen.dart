import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FingerTappingScreen extends StatefulWidget {
  const FingerTappingScreen({super.key});

  @override
  State<FingerTappingScreen> createState() =>
      _FingerTappingScreenState();
}

class _FingerTappingScreenState
    extends State<FingerTappingScreen> {
  static const int testDurationSeconds = 10;

  final List<DateTime> _tapTimes = [];

  DateTime? _startTime;

  bool _isRunning = false;
  bool _completed = false;
  bool _isSaving = false;

  int _remainingSeconds = testDurationSeconds;

  double? _score;
  double? _averageInterval;
  double? _consistency;
  double? _tapRate;

  // =========================================================
  // START TEST
  // =========================================================

  void _startTest() {
    if (_isRunning) return;

    setState(() {
      _tapTimes.clear();

      _startTime = DateTime.now();

      _isRunning = true;
      _completed = false;
      _isSaving = false;

      _remainingSeconds = testDurationSeconds;

      _score = null;
      _averageInterval = null;
      _consistency = null;
      _tapRate = null;
    });

    _runTimer();
  }

  // =========================================================
  // TIMER
  // =========================================================

  Future<void> _runTimer() async {
    for (int second = testDurationSeconds - 1;
        second >= 0;
        second--) {
      await Future.delayed(
        const Duration(seconds: 1),
      );

      if (!mounted || !_isRunning) {
        return;
      }

      setState(() {
        _remainingSeconds = second;
      });
    }

    if (mounted && _isRunning) {
      _finishTest();
    }
  }

  // =========================================================
  // REGISTER TAP
  // =========================================================

  void _registerTap() {
    if (!_isRunning) return;

    setState(() {
      _tapTimes.add(DateTime.now());
    });
  }

  // =========================================================
  // FINISH TEST
  // =========================================================

  void _finishTest() {
    if (!_isRunning) return;

    final endTime = DateTime.now();

    final actualDuration =
        endTime
                .difference(_startTime ?? endTime)
                .inMilliseconds /
            1000;

    final tapCount = _tapTimes.length;

    final averageInterval =
        _calculateAverageInterval();

    final consistency =
        _calculateConsistency();

    final tapRate = actualDuration > 0
        ? tapCount / actualDuration
        : 0.0;

    final score = _calculateScore(
      tapCount: tapCount,
      consistency: consistency,
    );

    setState(() {
      _isRunning = false;
      _completed = true;

      _remainingSeconds = 0;

      _averageInterval = averageInterval;
      _consistency = consistency;
      _tapRate = tapRate;
      _score = score;
    });

    _saveResult(
      tapCount: tapCount,
      duration: actualDuration,
      averageInterval: averageInterval,
      consistency: consistency,
      tapRate: tapRate,
      score: score,
    );
  }

  // =========================================================
  // AVERAGE TAP INTERVAL
  // =========================================================

  double _calculateAverageInterval() {
    if (_tapTimes.length < 2) {
      return 0;
    }

    double totalInterval = 0;

    for (int i = 1; i < _tapTimes.length; i++) {
      totalInterval += _tapTimes[i]
          .difference(_tapTimes[i - 1])
          .inMilliseconds;
    }

    final averageMilliseconds =
        totalInterval / (_tapTimes.length - 1);

    return averageMilliseconds / 1000;
  }

  // =========================================================
  // TAPPING CONSISTENCY
  // =========================================================

  double _calculateConsistency() {
    if (_tapTimes.length < 3) {
      return 0;
    }

    final intervals = <double>[];

    for (int i = 1; i < _tapTimes.length; i++) {
      final interval = _tapTimes[i]
              .difference(_tapTimes[i - 1])
              .inMilliseconds /
          1000;

      intervals.add(interval);
    }

    final mean =
        intervals.reduce((a, b) => a + b) /
            intervals.length;

    if (mean == 0) {
      return 0;
    }

    double variance = 0;

    for (final interval in intervals) {
      variance += math.pow(
        interval - mean,
        2,
      );
    }

    variance /= intervals.length;

    final standardDeviation =
        math.sqrt(variance);

    final coefficient =
        standardDeviation / mean;

    final consistency =
        (1 - coefficient)
            .clamp(0.0, 1.0)
            .toDouble();

    return consistency;
  }

  // =========================================================
  // MOVEMENT SCORE
  // =========================================================

  double _calculateScore({
    required int tapCount,
    required double consistency,
  }) {
    /*
      This is a software movement metric.

      It is NOT a clinical Parkinson's severity score.

      The score combines:
      - tapping activity
      - tapping consistency
    */

    final activityScore =
        ((tapCount / 20) * 100)
            .clamp(0.0, 100.0)
            .toDouble();

    final consistencyScore =
        consistency * 100;

    final score =
        (activityScore * 0.6) +
            (consistencyScore * 0.4);

    return score
        .clamp(0.0, 100.0)
        .toDouble();
  }

  // =========================================================
  // SAVE TO FIREBASE
  // =========================================================

  Future<void> _saveResult({
    required int tapCount,
    required double duration,
    required double averageInterval,
    required double consistency,
    required double tapRate,
    required double score,
  }) async {
    final user =
        FirebaseAuth.instance.currentUser;

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
        'testType': 'finger_tapping',
        'tapCount': tapCount,
        'durationSeconds': duration,
        'averageTapIntervalSeconds':
            averageInterval,
        'tapRatePerSecond': tapRate,
        'tappingConsistency': consistency,
        'score': score,
        'createdAt':
            FieldValue.serverTimestamp(),
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

  // =========================================================
  // RESET
  // =========================================================

  void _resetTest() {
    setState(() {
      _tapTimes.clear();

      _startTime = null;

      _isRunning = false;
      _completed = false;
      _isSaving = false;

      _remainingSeconds =
          testDurationSeconds;

      _score = null;
      _averageInterval = null;
      _consistency = null;
      _tapRate = null;
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
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F9FE),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF7F9FE),
        foregroundColor:
            const Color(0xFF25324A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Finger Tapping',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            30,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 20),

              _buildInstructionCard(),

              const SizedBox(height: 20),

              _buildTimerCard(),

              const SizedBox(height: 18),

              _buildTapButton(),

              const SizedBox(height: 20),

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

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFFEAF2FF),
            Color(0xFFF1EEFF),
          ],
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.touch_app_rounded,
            color: Color(0xFF8B78D9),
            size: 36,
          ),

          SizedBox(height: 12),

          Text(
            'Finger Tapping Test',
            style: TextStyle(
              fontSize: 24,
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(0xFF25324A),
            ),
          ),

          SizedBox(height: 7),

          Text(
            'Tap the button repeatedly and naturally. '
            'The app will measure your tapping rhythm '
            'and consistency.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color:
                  Color(0xFF68758A),
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
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(0xFFE4E9F2),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color:
                Color(0xFF8B78D9),
            size: 23,
          ),

          SizedBox(width: 11),

          Expanded(
            child: Text(
              'Press START to begin. Then tap the large '
              'button as many times as you comfortably can '
              'until the timer reaches zero.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color:
                    Color(0xFF69758A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TIMER
  // =========================================================

  Widget _buildTimerCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 24,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color:
              const Color(0xFFE1E7F0),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'TIME REMAINING',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF8A94A5),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '$_remainingSeconds',
            style: const TextStyle(
              fontSize: 52,
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(0xFF303C52),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            _isRunning
                ? 'Keep tapping naturally'
                : _completed
                    ? 'Test completed'
                    : '10 second assessment',
            style: const TextStyle(
              fontSize: 13,
              color:
                  Color(0xFF7A8499),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TAP BUTTON
  // =========================================================

  Widget _buildTapButton() {
    return Center(
      child: GestureDetector(
        onTap: _isRunning
            ? _registerTap
            : (_completed
                ? null
                : _startTest),

        child: AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 180,
          ),

          width: 210,
          height: 210,

          decoration:
              BoxDecoration(
            shape: BoxShape.circle,

            color: _isRunning
                ? const Color(
                    0xFF8B78D9,
                  )
                : _completed
                    ? const Color(
                        0xFFD7DDE8,
                      )
                    : const Color(
                        0xFF8B78D9,
                      ),

            boxShadow: _isRunning
                ? const [
                    BoxShadow(
                      blurRadius: 24,
                      spreadRadius: 2,
                      color:
                          Color(
                        0x258B78D9,
                      ),
                    ),
                  ]
                : null,
          ),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              Icon(
                _isRunning
                    ? Icons.touch_app_rounded
                    : _completed
                        ? Icons.check_circle_outline_rounded
                        : Icons.play_arrow_rounded,

                size: 52,

                color: Colors.white,
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                _isRunning
                    ? 'TAP'
                    : _completed
                        ? 'DONE'
                        : 'START',

                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // RESULTS
  // =========================================================

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              const Color(0xFFE1E7F0),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Assessment Complete',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(0xFF25324A),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _resultItem(
                  'Movement Score',
                  _score != null
                      ? _score!
                          .toStringAsFixed(1)
                      : '--',
                  Icons.analytics_outlined,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _resultItem(
                  'Tap Rate',
                  _tapRate != null
                      ? '${_tapRate!.toStringAsFixed(2)} /s'
                      : '--',
                  Icons.speed_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          _resultItem(
            'Average Tap Interval',
            _averageInterval != null
                ? '${_averageInterval!.toStringAsFixed(2)} s'
                : '--',
            Icons.timer_outlined,
          ),

          const SizedBox(height: 10),

          _resultItem(
            'Tapping Consistency',
            '${((_consistency ?? 0) * 100).toStringAsFixed(1)}%',
            Icons.waves_rounded,
          ),

          const SizedBox(height: 15),

          if (_isSaving)
            const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),

                SizedBox(width: 10),

                Text(
                  'Saving assessment...',
                  style: TextStyle(
                    color:
                        Color(0xFF69758A),
                  ),
                ),
              ],
            )
          else
            const Text(
              'Your tapping movement has been recorded '
              'for future progress tracking.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color:
                    Color(0xFF7A8499),
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // RESULT ITEM
  // =========================================================

  Widget _resultItem(
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF7F9FE),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color:
                const Color(0xFF8B78D9),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      const TextStyle(
                    fontSize: 11,
                    color:
                        Color(0xFF7A8499),
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 17,
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
    );
  }

  // =========================================================
  // RETEST BUTTON
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
            fontWeight:
                FontWeight.w700,
          ),
        ),

        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              const Color(0xFF8B78D9),

          side:
              const BorderSide(
            color:
                Color(0xFF8B78D9),
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // DISCLAIMER
  // =========================================================

  Widget _buildDisclaimer() {
    return const Text(
      'This assessment is designed for movement screening '
      'and progress tracking. It is not a standalone '
      'medical diagnosis.',
      textAlign:
          TextAlign.center,
      style: TextStyle(
        fontSize: 11.5,
        height: 1.45,
        color:
            Color(0xFF8A94A5),
      ),
    );
  }
}