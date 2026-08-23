import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FingerTappingTestScreen extends StatefulWidget {
  const FingerTappingTestScreen({super.key});

  @override
  State<FingerTappingTestScreen> createState() =>
      _FingerTappingTestScreenState();
}

class _FingerTappingTestScreenState
    extends State<FingerTappingTestScreen> {
  static const int _testDurationSeconds = 10;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Timer? _timer;

  final List<DateTime> _tapTimes = [];

  bool _isTestRunning = false;
  bool _hasCompleted = false;
  bool _isSaving = false;

  int _remainingSeconds = _testDurationSeconds;
  int _tapCount = 0;

  double? _tapsPerSecond;
  double? _averageInterval;
  double? _timingConsistency;
  double? _variationScore;

  String _resultTitle = '';
  String _resultDescription = '';

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

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
          'Finger Tapping Test',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
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

          _buildTestArea(),

          const SizedBox(height: 20),

          if (!_isTestRunning && !_hasCompleted)
            _buildStartButton(),

          if (_isTestRunning)
            _buildRunningStatus(),

          if (_hasCompleted)
            _buildResultCard(),

          if (_hasCompleted)
            const SizedBox(height: 15),

          if (_hasCompleted)
            _buildRetestButton(),

          const SizedBox(height: 20),

          _buildDisclaimer(),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

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
            Icons.touch_app_rounded,
            color: Color(0xFF6C63FF),
            size: 36,
          ),
          SizedBox(height: 12),
          Text(
            'Finger Tapping Test',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF25324A),
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Tap the button repeatedly with one finger. '
            'The app records your tapping speed and timing pattern.',
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

  // ============================================================
  // INSTRUCTIONS
  // ============================================================

  Widget _buildInstructionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFFE3E8F2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.touch_app_rounded,
              color: Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  'Press Start Test and tap the large button '
                  'as quickly and comfortably as you can using '
                  'one finger. Continue until the timer reaches zero.',
                  style: TextStyle(
                    fontSize: 12.5,
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

  // ============================================================
  // TEST AREA
  // ============================================================

  Widget _buildTestArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE1E7F0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTimer(),

          const SizedBox(height: 15),

          _buildTapCounter(),

          const SizedBox(height: 22),

          _buildTapButton(),

          const SizedBox(height: 16),

          Text(
            _isTestRunning
                ? 'Keep tapping with the same finger'
                : _hasCompleted
                    ? 'Test completed'
                    : 'Press Start Test to begin',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8993A6),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TIMER
  // ============================================================

  Widget _buildTimer() {
    final progress =
        _remainingSeconds / _testDurationSeconds;

    return SizedBox(
      width: 125,
      height: 125,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 125,
            height: 125,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 10,
              backgroundColor:
                  const Color(0xFFECEFF5),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(
                Color(0xFF6C63FF),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_remainingSeconds',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF303C52),
                ),
              ),
              const Text(
                'seconds',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8993A6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAP COUNTER
  // ============================================================

  Widget _buildTapCounter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Taps recorded',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF7A8499),
            ),
          ),
          Text(
            '$_tapCount',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6C63FF),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAP BUTTON
  // ============================================================

  Widget _buildTapButton() {
    return GestureDetector(
      onTapDown: (_) {
        if (_isTestRunning) {
          _recordTap();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 210,
        height: 210,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Color(0xFF7B72F2),
              Color(0xFF6385E5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF)
                  .withValues(alpha: 0.22),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app_rounded,
              size: 48,
              color: Colors.white,
            ),
            SizedBox(height: 10),
            Text(
              'TAP',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'with one finger',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFFEDEBFF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // START TEST
  // ============================================================

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _startTest,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text(
          'Start Test',
          style: TextStyle(fontWeight: FontWeight.w700),
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
    );
  }

  void _startTest() {
    _timer?.cancel();

    setState(() {
      _tapTimes.clear();

      _isTestRunning = true;
      _hasCompleted = false;
      _isSaving = false;

      _remainingSeconds =
          _testDurationSeconds;

      _tapCount = 0;

      _tapsPerSecond = null;
      _averageInterval = null;
      _timingConsistency = null;
      _variationScore = null;

      _resultTitle = '';
      _resultDescription = '';
    });

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_remainingSeconds <= 1) {
          timer.cancel();
          _finishTest();
          return;
        }

        setState(() {
          _remainingSeconds--;
        });
      },
    );
  }

  // ============================================================
  // RECORD TAP
  // ============================================================

  void _recordTap() {
    if (!_isTestRunning) return;

    final now = DateTime.now();

    setState(() {
      _tapTimes.add(now);
      _tapCount = _tapTimes.length;
    });
  }

  // ============================================================
  // FINISH TEST
  // ============================================================

  void _finishTest() {
    _timer?.cancel();

    if (!_isTestRunning) {
      return;
    }

    final tapCount = _tapTimes.length;

    final tapsPerSecond =
        tapCount / _testDurationSeconds;

    final intervals =
        <double>[];

    for (int i = 1;
        i < _tapTimes.length;
        i++) {
      final difference =
          _tapTimes[i]
              .difference(_tapTimes[i - 1])
              .inMilliseconds;

      if (difference > 0) {
        intervals.add(
          difference / 1000.0,
        );
      }
    }

    double averageInterval = 0;

    if (intervals.isNotEmpty) {
      averageInterval =
          intervals.reduce((a, b) => a + b) /
              intervals.length;
    }

    final consistency =
        _calculateTimingConsistency(
      intervals,
    );

    final variationScore =
        _calculateVariationScore(
      tapsPerSecond,
      consistency,
    );

    final result =
        _getResult(variationScore);

    if (!mounted) return;

    setState(() {
      _isTestRunning = false;
      _hasCompleted = true;

      _remainingSeconds = 0;

      _tapsPerSecond =
          tapsPerSecond;

      _averageInterval =
          averageInterval;

      _timingConsistency =
          consistency;

      _variationScore =
          variationScore;

      _resultTitle =
          result.title;

      _resultDescription =
          result.description;
    });

    _saveResult(
      tapsPerSecond: tapsPerSecond,
      averageInterval: averageInterval,
      consistency: consistency,
      variationScore: variationScore,
    );
  }

  // ============================================================
  // TIMING CONSISTENCY
  // ============================================================

  double _calculateTimingConsistency(
    List<double> intervals,
  ) {
    if (intervals.length < 2) {
      return intervals.isEmpty ? 0 : 1;
    }

    final mean =
        intervals.reduce((a, b) => a + b) /
            intervals.length;

    if (mean <= 0) {
      return 0;
    }

    double variance = 0;

    for (final interval in intervals) {
      final difference =
          interval - mean;

      variance +=
          difference * difference;
    }

    variance /= intervals.length;

    final standardDeviation =
        math.sqrt(variance);

    final coefficientOfVariation =
        standardDeviation / mean;

    final consistency =
        1 -
            coefficientOfVariation
                .clamp(0.0, 1.0);

    return consistency
        .clamp(0.0, 1.0)
        .toDouble();
  }

  // ============================================================
  // VARIATION SCORE
  // ============================================================

  double _calculateVariationScore(
    double tapsPerSecond,
    double consistency,
  ) {
    /*
      This is a screening-oriented software score.

      Higher score = greater movement variation.

      Speed contributes 40%.
      Timing irregularity contributes 60%.
    */

    final speedVariation =
        (1 -
                (tapsPerSecond / 6.0)
                    .clamp(0.0, 1.0))
            .toDouble();

    final timingVariation =
        1 - consistency;

    final score =
        (speedVariation * 0.40) +
            (timingVariation * 0.60);

    return (score * 100)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  // ============================================================
  // RESULT
  // ============================================================

  _FingerTapResult _getResult(
    double score,
  ) {
    if (score < 30) {
      return const _FingerTapResult(
        title:
            'Tapping pattern looks relatively steady',
        description:
            'Your tapping pattern was relatively '
            'consistent during this short screening test.',
      );
    }

    if (score < 60) {
      return const _FingerTapResult(
        title:
            'Some tapping variation detected',
        description:
            'The tapping pattern showed some variation '
            'in speed or timing. Consider repeating the '
            'test under similar conditions.',
      );
    }

    return const _FingerTapResult(
      title:
          'Higher tapping variation detected',
      description:
          'The tapping pattern showed greater variation '
          'in speed or timing during this test. A healthcare '
          'professional should interpret this result.',
    );
  }

  // ============================================================
  // RUNNING STATUS
  // ============================================================

  Widget _buildRunningStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF6C63FF),
            ),
          ),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Test is running. Keep tapping until the timer reaches zero.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF5F6D86),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESULT CARD
  // ============================================================

  Widget _buildResultCard() {
    final score =
        _variationScore ?? 0;

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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFFE1E7F0),
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
                  'Tapping Analysis',
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

          const SizedBox(height: 18),

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
                  'Taps',
                  '$_tapCount',
                  Icons.touch_app_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _resultMetric(
                  'Taps / second',
                  _tapsPerSecond
                          ?.toStringAsFixed(2) ??
                      '--',
                  Icons.speed_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _resultMetric(
                  'Avg. interval',
                  _averageInterval == null
                      ? '--'
                      : '${_averageInterval!.toStringAsFixed(2)} s',
                  Icons.timer_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _resultMetric(
                  'Timing consistency',
                  _timingConsistency == null
                      ? '--'
                      : '${(_timingConsistency! * 100).toStringAsFixed(0)}%',
                  Icons.waves_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

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
                    fontSize: 12,
                    color: Color(0xFF69758A),
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
                color: Color(0xFF7A8499),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // RESULT METRIC
  // ============================================================

  Widget _resultMetric(
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 21,
            color: const Color(0xFF6C63FF),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF303C52),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
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

  // ============================================================
  // RETEST
  // ============================================================

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
              const Color(0xFF6C63FF),
          side: const BorderSide(
            color: Color(0xFF6C63FF),
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

  // ============================================================
  // RESET
  // ============================================================

  void _resetTest() {
    _timer?.cancel();

    setState(() {
      _tapTimes.clear();

      _isTestRunning = false;
      _hasCompleted = false;
      _isSaving = false;

      _remainingSeconds =
          _testDurationSeconds;

      _tapCount = 0;

      _tapsPerSecond = null;
      _averageInterval = null;
      _timingConsistency = null;
      _variationScore = null;

      _resultTitle = '';
      _resultDescription = '';
    });
  }

  // ============================================================
  // FIREBASE SAVE
  // ============================================================

  Future<void> _saveResult({
    required double tapsPerSecond,
    required double averageInterval,
    required double consistency,
    required double variationScore,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
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
        'testType': 'finger_tapping_test',
        'score': variationScore,
        'durationSeconds':
            _testDurationSeconds,
        'tapCount': _tapCount,
        'tapsPerSecond':
            tapsPerSecond,
        'averageIntervalSeconds':
            averageInterval,
        'timingConsistency':
            consistency,
        'variationScore':
            variationScore,
        'createdAt':
            FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (mounted) {
        _showMessage(
          e.message ??
              'Assessment completed, but the result could not be saved.',
        );
      }
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

  // ============================================================
  // DISCLAIMER
  // ============================================================

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9ED),
        borderRadius: BorderRadius.circular(16),
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
              'This is a software-based movement '
              'screening test, not a medical diagnosis. '
              'Results should be interpreted by a qualified '
              'healthcare professional.',
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

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
      ),
    );
  }
}

// ================================================================
// RESULT MODEL
// ================================================================

class _FingerTapResult {
  final String title;
  final String description;

  const _FingerTapResult({
    required this.title,
    required this.description,
  });
}
