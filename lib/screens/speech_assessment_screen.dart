import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class SpeechAssessmentScreen extends StatefulWidget {
  const SpeechAssessmentScreen({super.key});

  @override
  State<SpeechAssessmentScreen> createState() =>
      _SpeechAssessmentScreenState();
}

class _SpeechAssessmentScreenState
    extends State<SpeechAssessmentScreen> {
  final AudioRecorder _recorder = AudioRecorder();

  Timer? _timer;

  bool _showInstructions = true;
  bool _isRecording = false;
  bool _completed = false;
  bool _isSaving = false;

  int _seconds = 0;
  double? _score;

  String? _recordingPath;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();

      if (!hasPermission) {
        if (!mounted) return;

        _showMessage(
          'Microphone permission is required for the speech assessment.',
        );
        return;
      }

      // ------------------------------------------------------------
      // Create a writable temporary directory for the recording.
      // ------------------------------------------------------------

      final directory = await getTemporaryDirectory();

      final filePath = '${directory.path}${Platform.pathSeparator}'
          'speech_assessment_${DateTime.now().millisecondsSinceEpoch}.m4a';

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      await _recorder.start(
        config,
        path: filePath,
      );

      _recordingPath = filePath;

      if (!mounted) return;

      setState(() {
        _showInstructions = false;
        _isRecording = true;
        _completed = false;
        _seconds = 0;
        _score = null;
      });

      _timer?.cancel();

      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          if (!mounted || !_isRecording) return;

          setState(() {
            _seconds++;
          });
        },
      );
    } catch (e) {
      _timer?.cancel();

      if (!mounted) return;

      setState(() {
        _isRecording = false;
      });

      _showMessage(
        'Unable to start recording. Please check microphone access and try again.',
      );
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      _timer?.cancel();

      final path = await _recorder.stop();

      _recordingPath = path;

      final score = _calculateScore();

      if (!mounted) return;

      setState(() {
        _isRecording = false;
        _completed = true;
        _score = score;
      });
    } catch (e) {
      _timer?.cancel();

      if (!mounted) return;

      setState(() {
        _isRecording = false;
      });

      _showMessage(
        'Unable to complete the recording. Please try again.',
      );
    }
  }

  double _calculateScore() {
    /*
      Preliminary software-based score.

      This score is based only on sample duration.
      It is NOT a medical diagnosis.

      Later, actual speech analysis can be added using
      features such as:
      - speech rate
      - pauses
      - pitch variation
      - voice intensity
      - articulation characteristics
    */

    if (_seconds < 3) {
      return 45.0;
    }

    if (_seconds < 5) {
      return 60.0;
    }

    if (_seconds < 8) {
      return 72.0;
    }

    if (_seconds <= 20) {
      return 85.0;
    }

    return 90.0;
  }

  Future<void> _saveResult() async {
    if (_score == null || _isSaving) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please log in before saving the assessment.',
      );
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
        'testType': 'Speech Assessment',
        'score': _score,
        'durationSeconds': _seconds,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        'Speech assessment saved successfully.',
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        'Unable to save the assessment. Please try again.',
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String _summaryText() {
    final score = _score ?? 0;

    if (score >= 85) {
      return 'The speech sample was completed for an adequate duration. '
          'The result indicates a good-quality assessment sample.';
    }

    if (score >= 70) {
      return 'The speech sample was completed, but the recording '
          'duration was shorter than the preferred assessment range.';
    }

    return 'The speech sample was too short for a reliable preliminary '
        'assessment. Consider repeating the test with a longer sample.';
  }

  void _restart() {
    _timer?.cancel();

    setState(() {
      _showInstructions = true;
      _isRecording = false;
      _completed = false;
      _isSaving = false;
      _seconds = 0;
      _score = null;
      _recordingPath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FE),
        elevation: 0,
        foregroundColor: const Color(0xFF25324A),
        title: const Text(
          'Speech Assessment',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showInstructions
              ? _buildInstructions()
              : _isRecording
                  ? _buildRecording()
                  : _completed
                      ? _buildResult()
                      : _buildInstructions(),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return SingleChildScrollView(
      key: const ValueKey('instructions'),
      padding: const EdgeInsets.fromLTRB(
        22,
        20,
        22,
        30,
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FF),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.record_voice_over_rounded,
              size: 45,
              color: Color(0xFF7B61C9),
            ),
          ),

          const SizedBox(height: 22),

          const Text(
            'Before you begin',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: Color(0xFF25324A),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'This assessment records a short speech sample '
            'to evaluate basic speech characteristics.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF707B90),
            ),
          ),

          const SizedBox(height: 25),

          _instructionCard(
            Icons.volume_up_rounded,
            'Find a quiet place',
            'Reduce background noise as much as possible.',
          ),

          _instructionCard(
            Icons.mic_rounded,
            'Allow microphone access',
            'The microphone is required to record your speech.',
          ),

          _instructionCard(
            Icons.record_voice_over_rounded,
            'Speak naturally',
            'Read a short sentence or speak normally for several seconds.',
          ),

          _instructionCard(
            Icons.timer_outlined,
            'Keep speaking',
            'Try to provide a sample of at least 8 seconds.',
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFB77A1B),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This is a screening assessment and not a '
                    'medical diagnosis.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: Color(0xFF73551F),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _startRecording,
              icon: const Icon(
                Icons.mic_rounded,
              ),
              label: const Text(
                'Start Speech Assessment',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B61C9),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _instructionCard(
    IconData icon,
    String title,
    String description,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE4E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EDFF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF7B61C9),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF303C52),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
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

  Widget _buildRecording() {
    return Center(
      key: const ValueKey('recording'),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFFF0EDFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic_rounded,
                size: 60,
                color: Color(0xFF7B61C9),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Recording...',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: Color(0xFF25324A),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '$_seconds seconds',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7B61C9),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Speak naturally and keep going.\n'
              'Tap stop when you are finished.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF7A8499),
              ),
            ),

            const SizedBox(height: 35),

            SizedBox(
              width: 180,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _stopRecording,
                icon: const Icon(
                  Icons.stop_rounded,
                ),
                label: const Text(
                  'Stop Recording',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDB5A5A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final score = _score ?? 0;

    return SingleChildScrollView(
      key: const ValueKey('result'),
      padding: const EdgeInsets.fromLTRB(
        22,
        20,
        22,
        30,
      ),
      child: Column(
        children: [
          const Text(
            'Assessment Complete',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: Color(0xFF25324A),
            ),
          ),

          const SizedBox(height: 22),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFEDE9FF),
                  Color(0xFFF5F2FF),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              children: [
                const Text(
                  'Speech Assessment Score',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5E5875),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  '${score.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7B61C9),
                  ),
                ),

                const SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _resultMetric(
                      'Duration',
                      '$_seconds s',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: const Color(0xFFE2E7F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF7B61C9),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'What does this mean?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF303C52),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  _summaryText(),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF69758A),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saveResult,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.cloud_upload_rounded,
                    ),
              label: Text(
                _isSaving
                    ? 'Saving...'
                    : 'Save Assessment',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B61C9),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          TextButton(
            onPressed: _restart,
            child: const Text(
              'Take Again',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF7B61C9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultMetric(
    String label,
    String value,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF303C52),
          ),
        ),

        const SizedBox(height: 3),

        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF7A8499),
          ),
        ),
      ],
    );
  }
}

