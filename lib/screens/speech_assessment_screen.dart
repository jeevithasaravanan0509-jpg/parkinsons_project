import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

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

  int _currentPhase = 0;

  final List<String> _phaseTitles = [
    'Sustained Voice',
    'Guided Sentence',
    'Speech Repetition',
  ];

  final List<String> _phaseInstructions = [
    'Say "aaah" steadily for as long as comfortable.',
    'Read the sentence naturally and clearly.',
    'Repeat "pa-ta-ka" steadily several times.',
  ];

  final List<String> _phasePrompts = [
    'AAAH',
    'Today is a beautiful day and I am speaking clearly.',
    'PA - TA - KA',
  ];

  final List<String?> _recordingPaths = [
    null,
    null,
    null,
  ];

  final List<SpeechPhaseResult?> _phaseResults = [
    null,
    null,
    null,
  ];

  SpeechAnalysisResult? _analysis;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startAssessment() async {
    setState(() {
      _showInstructions = false;
      _completed = false;
      _currentPhase = 0;
      _seconds = 0;

      _recordingPaths.fillRange(0, _recordingPaths.length, null);
      _phaseResults.fillRange(0, _phaseResults.length, null);
      _analysis = null;
    });

    await _startCurrentPhase();
  }

  Future<void> _startCurrentPhase() async {
    try {
      final hasPermission = await _recorder.hasPermission();

      if (!hasPermission) {
        if (!mounted) return;

        _showMessage(
          'Microphone permission is required for the speech assessment.',
        );
        return;
      }

      final directory = await getTemporaryDirectory();

      final filePath =
          '${directory.path}${Platform.pathSeparator}'
          'speech_phase_${_currentPhase}_${DateTime.now().millisecondsSinceEpoch}.wav';

      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
      );

      await _recorder.start(
        config,
        path: filePath,
      );

      _recordingPaths[_currentPhase] = filePath;

      if (!mounted) return;

      setState(() {
        _isRecording = true;
        _seconds = 0;
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
        'Unable to start the microphone recording. Please try again.',
      );
    }
  }

  Future<void> _stopCurrentPhase() async {
    if (!_isRecording) return;

    try {
      _timer?.cancel();

      final path = await _recorder.stop();

      final actualPath =
          path ?? _recordingPaths[_currentPhase];

      _recordingPaths[_currentPhase] = actualPath;

      if (actualPath == null ||
          !await File(actualPath).exists()) {
        throw Exception('Recording file was not created.');
      }

      final result = await _analyzeAudioFile(actualPath);

      _phaseResults[_currentPhase] = result;

      if (!mounted) return;

      setState(() {
        _isRecording = false;
      });

      if (_currentPhase < _phaseTitles.length - 1) {
        await Future.delayed(
          const Duration(milliseconds: 500),
        );

        if (!mounted) return;

        setState(() {
          _currentPhase++;
          _seconds = 0;
        });

        await _startCurrentPhase();
      } else {
        _finishAssessment();
      }
    } catch (e) {
      _timer?.cancel();

      if (!mounted) return;

      setState(() {
        _isRecording = false;
      });

      _showMessage(
        'Unable to analyze this recording. Please repeat the assessment.',
      );
    }
  }

  void _finishAssessment() {
    final vowel = _phaseResults[0];
    final sentence = _phaseResults[1];
    final syllable = _phaseResults[2];

    if (vowel == null ||
        sentence == null ||
        syllable == null) {
      _showMessage(
        'All three speech tasks must be completed.',
      );
      return;
    }

    final analysis = SpeechAnalysisResult.fromPhases(
      vowel: vowel,
      sentence: sentence,
      syllable: syllable,
    );

    if (!mounted) return;

    setState(() {
      _analysis = analysis;
      _completed = true;
      _isRecording = false;
    });
  }

  Future<SpeechPhaseResult> _analyzeAudioFile(
    String filePath,
  ) async {
    final bytes = await File(filePath).readAsBytes();

    final wav = _parseWav(bytes);

    final samples = wav.samples;
    final sampleRate = wav.sampleRate;

    if (samples.isEmpty) {
      throw Exception('No audio samples were found.');
    }

    final duration =
        samples.length / sampleRate;

    const frameSize = 320;
    const hopSize = 160;

    final rmsValues = <double>[];
    final zeroCrossingValues = <double>[];
    final pitchValues = <double>[];

    for (
      int start = 0;
      start + frameSize <= samples.length;
      start += hopSize
    ) {
      final frame = samples.sublist(
        start,
        start + frameSize,
      );

      final rms = _calculateRms(frame);

      rmsValues.add(rms);

      zeroCrossingValues.add(
        _calculateZeroCrossingRate(frame),
      );

      if (rms > 0.008) {
        final pitch = _estimatePitch(
          frame,
          sampleRate,
        );

        if (pitch >= 70 && pitch <= 400) {
          pitchValues.add(pitch);
        }
      }
    }

    if (rmsValues.isEmpty) {
      throw Exception('Audio analysis produced no frames.');
    }

    final maxRms = rmsValues.reduce(math.max);

    final threshold = math.max(
      0.008,
      maxRms * 0.12,
    );

    int activeFrames = 0;

    for (final rms in rmsValues) {
      if (rms >= threshold) {
        activeFrames++;
      }
    }

    final speechActivityRatio =
        activeFrames / rmsValues.length;

    final pauseDurations = _findPauseDurations(
      rmsValues,
      threshold,
      hopSize,
      sampleRate,
    );

    final pauseCount = pauseDurations.length;

    final averagePauseDuration =
        pauseDurations.isEmpty
            ? 0.0
            : pauseDurations.reduce((a, b) => a + b) /
                pauseDurations.length;

    final averageRms = activeFrames == 0
        ? 0.0
        : rmsValues
                .where((value) => value >= threshold)
                .fold<double>(
                  0.0,
                  (total, value) => total + value,
                ) /
            activeFrames;

    final loudness = _rmsToDb(averageRms);

    final pitchMean = pitchValues.isEmpty
        ? 0.0
        : pitchValues.reduce((a, b) => a + b) /
            pitchValues.length;

    final pitchVariation =
        _coefficientOfVariation(pitchValues);

    final pitchStability =
        _stabilityFromVariation(pitchVariation);

    final voiceStability =
        _calculateVoiceStability(
      rmsValues,
      threshold,
    );

    final averageZeroCrossing =
        zeroCrossingValues.isEmpty
            ? 0.0
            : zeroCrossingValues.reduce(
                  (a, b) => a + b,
                ) /
                zeroCrossingValues.length;

    final breathiness =
        _calculateBreathiness(
      averageZeroCrossing,
      averageRms,
    );

    final speechRate =
        _estimateSpeechRate(
      rmsValues,
      threshold,
      sampleRate,
      hopSize,
    );

    return SpeechPhaseResult(
      duration: duration,
      activeRatio: speechActivityRatio,
      pauseCount: pauseCount,
      averagePauseDuration: averagePauseDuration,
      averageLoudnessDb: loudness,
      pitchMean: pitchMean,
      pitchVariation: pitchVariation,
      pitchStability: pitchStability,
      voiceStability: voiceStability,
      breathiness: breathiness,
      speechRate: speechRate,
    );
  }

  List<double> _findPauseDurations(
    List<double> rmsValues,
    double threshold,
    int hopSize,
    int sampleRate,
  ) {
    final pauses = <double>[];

    int silentFrames = 0;

    for (final rms in rmsValues) {
      if (rms < threshold) {
        silentFrames++;
      } else {
        if (silentFrames >= 3) {
          final duration =
              silentFrames *
                  hopSize /
                  sampleRate;

          if (duration >= 0.15) {
            pauses.add(duration);
          }
        }

        silentFrames = 0;
      }
    }

    if (silentFrames >= 3) {
      final duration =
          silentFrames *
              hopSize /
              sampleRate;

      if (duration >= 0.15) {
        pauses.add(duration);
      }
    }

    return pauses;
  }

  double _calculateRms(
    List<double> samples,
  ) {
    if (samples.isEmpty) return 0;

    double sum = 0;

    for (final sample in samples) {
      sum += sample * sample;
    }

    return math.sqrt(
      sum / samples.length,
    );
  }

  double _calculateZeroCrossingRate(
    List<double> samples,
  ) {
    if (samples.length < 2) return 0;

    int crossings = 0;

    for (int i = 1; i < samples.length; i++) {
      if ((samples[i - 1] >= 0 &&
              samples[i] < 0) ||
          (samples[i - 1] < 0 &&
              samples[i] >= 0)) {
        crossings++;
      }
    }

    return crossings / samples.length;
  }

  double _estimatePitch(
    List<double> frame,
    int sampleRate,
  ) {
    const minFrequency = 70.0;
    const maxFrequency = 400.0;

    final minLag =
        (sampleRate / maxFrequency).floor();

    final maxLag =
        (sampleRate / minFrequency).ceil();

    if (frame.length <= maxLag) {
      return 0;
    }

    double bestCorrelation = 0;
    int bestLag = 0;

    for (
      int lag = minLag;
      lag <= maxLag;
      lag++
    ) {
      double sum = 0;
      double energyA = 0;
      double energyB = 0;

      for (
        int i = 0;
        i < frame.length - lag;
        i++
      ) {
        final a = frame[i];
        final b = frame[i + lag];

        sum += a * b;
        energyA += a * a;
        energyB += b * b;
      }

      final denominator =
          math.sqrt(energyA * energyB);

      if (denominator == 0) continue;

      final correlation =
          sum / denominator;

      if (correlation > bestCorrelation) {
        bestCorrelation = correlation;
        bestLag = lag;
      }
    }

    if (bestLag == 0 ||
        bestCorrelation < 0.35) {
      return 0;
    }

    return sampleRate / bestLag;
  }

  double _coefficientOfVariation(
    List<double> values,
  ) {
    if (values.length < 2) return 0;

    final mean =
        values.reduce((a, b) => a + b) /
            values.length;

    if (mean == 0) return 0;

    double variance = 0;

    for (final value in values) {
      final difference = value - mean;
      variance += difference * difference;
    }

    variance /= values.length;

    final standardDeviation =
        math.sqrt(variance);

    return standardDeviation / mean;
  }

  double _stabilityFromVariation(
    double variation,
  ) {
    return (100 -
            variation.clamp(0.0, 1.0) *
                100)
        .clamp(0.0, 100.0);
  }

  double _calculateVoiceStability(
    List<double> rmsValues,
    double threshold,
  ) {
    final activeValues = rmsValues
        .where((value) => value >= threshold)
        .toList();

    if (activeValues.length < 2) {
      return 0;
    }

    final variation =
        _coefficientOfVariation(activeValues);

    return (100 -
            variation.clamp(0.0, 1.0) *
                100)
        .clamp(0.0, 100.0);
  }

  double _calculateBreathiness(
    double zeroCrossingRate,
    double rms,
  ) {
    if (rms <= 0) return 0;

    final normalizedZcr =
        (zeroCrossingRate / 0.20)
            .clamp(0.0, 1.0);

    final lowEnergyFactor =
        (1.0 - (rms / 0.20))
            .clamp(0.0, 1.0);

    return ((normalizedZcr * 0.6) +
            (lowEnergyFactor * 0.4)) *
        100;
  }

  double _estimateSpeechRate(
    List<double> rmsValues,
    double threshold,
    int sampleRate,
    int hopSize,
  ) {
    if (rmsValues.length < 3) {
      return 0;
    }

    int peaks = 0;

    for (int i = 1;
        i < rmsValues.length - 1;
        i++) {
      final previous = rmsValues[i - 1];
      final current = rmsValues[i];
      final next = rmsValues[i + 1];

      if (current >= threshold &&
          current > previous &&
          current >= next) {
        peaks++;
      }
    }

    final duration =
        rmsValues.length *
            hopSize /
            sampleRate;

    if (duration <= 0) return 0;

    return peaks / duration;
  }

  double _rmsToDb(
    double rms,
  ) {
    if (rms <= 0) return -60;

    return 20 *
        math.log(
          rms,
        ) /
        math.ln10;
  }

  WavData _parseWav(
    Uint8List bytes,
  ) {
    if (bytes.length < 44) {
      throw Exception('Invalid WAV file.');
    }

    final byteData =
        ByteData.sublistView(bytes);

    final channels =
        byteData.getUint16(
      22,
      Endian.little,
    );

    final sampleRate =
        byteData.getUint32(
      24,
      Endian.little,
    );

    final bitsPerSample =
        byteData.getUint16(
      34,
      Endian.little,
    );

    if (channels != 1) {
      throw Exception(
        'Expected mono audio.',
      );
    }

    if (bitsPerSample != 16) {
      throw Exception(
        'Expected 16-bit PCM audio.',
      );
    }

    int dataOffset = -1;
    int dataSize = 0;

    int offset = 12;

    while (offset + 8 <= bytes.length) {
      final chunkId = String.fromCharCodes(
        bytes.sublist(
          offset,
          offset + 4,
        ),
      );

      final chunkSize =
          byteData.getUint32(
        offset + 4,
        Endian.little,
      );

      if (chunkId == 'data') {
        dataOffset = offset + 8;
        dataSize = chunkSize;
        break;
      }

      offset += 8 + chunkSize;

      if (chunkSize.isOdd) {
        offset++;
      }
    }

    if (dataOffset < 0) {
      throw Exception(
        'WAV audio data could not be found.',
      );
    }

    final end = math.min(
      dataOffset + dataSize,
      bytes.length,
    );

    final samples = <double>[];

    for (
      int i = dataOffset;
      i + 1 < end;
      i += 2
    ) {
      final value =
          byteData.getInt16(
        i,
        Endian.little,
      );

      samples.add(
        value / 32768.0,
      );
    }

    return WavData(
      sampleRate: sampleRate.toInt(),
      samples: samples,
    );
  }

  Future<void> _saveResult() async {
    if (_analysis == null ||
        _isSaving) {
      return;
    }

    final user =
        FirebaseAuth.instance.currentUser;

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
      final analysis = _analysis!;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('motor_assessments')
          .add({
        'testType': 'Speech Assessment',
        'score': analysis.compositeScore,
        'assessmentType':
            'Preliminary Acoustic Speech Analysis',

        'totalDurationSeconds':
            analysis.totalDuration,

        'speechActivityRatio':
            analysis.speechActivityRatio,

        'pauseCount':
            analysis.pauseCount,

        'averagePauseDuration':
            analysis.averagePauseDuration,

        'speechRate':
            analysis.speechRate,

        'pitchMean':
            analysis.pitchMean,

        'pitchVariation':
            analysis.pitchVariation,

        'pitchStability':
            analysis.pitchStability,

        'averageLoudnessDb':
            analysis.averageLoudnessDb,

        'voiceStability':
            analysis.voiceStability,

        'breathinessIndicator':
            analysis.breathiness,

        'createdAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        'Speech assessment saved successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        'Unable to save the speech assessment. Please try again.',
      );
    }
  }

  void _restartAssessment() {
    _timer?.cancel();

    setState(() {
      _showInstructions = true;
      _isRecording = false;
      _completed = false;
      _isSaving = false;

      _seconds = 0;
      _currentPhase = 0;

      _recordingPaths.fillRange(
        0,
        _recordingPaths.length,
        null,
      );

      _phaseResults.fillRange(
        0,
        _phaseResults.length,
        null,
      );

      _analysis = null;
    });
  }

  void _showMessage(
    String message,
  ) {
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

  @override
  Widget build(
    BuildContext context,
  ) {
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
          'Speech Assessment',
          style: TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration:
              const Duration(milliseconds: 300),
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
      key:
          const ValueKey('instructions'),
      padding:
          const EdgeInsets.fromLTRB(
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
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFEDE9FF),
              borderRadius:
                  BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.record_voice_over_rounded,
              size: 45,
              color:
                  Color(0xFF7B61C9),
            ),
          ),

          const SizedBox(height: 22),

          const Text(
            'Speech Assessment',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 25,
              fontWeight:
                  FontWeight.w900,
              color:
                  Color(0xFF25324A),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'This assessment uses several short speech tasks to measure preliminary acoustic characteristics of your voice.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color:
                  Color(0xFF707B90),
            ),
          ),

          const SizedBox(height: 25),

          _instructionCard(
            Icons.mic_rounded,
            'Microphone access',
            'Allow microphone access so the app can record the speech samples.',
          ),

          _instructionCard(
            Icons.volume_up_rounded,
            'Quiet environment',
            'Try to perform the assessment in a quiet place with minimal background noise.',
          ),

          _instructionCard(
            Icons.record_voice_over_rounded,
            'Three short tasks',
            'You will complete a sustained vowel, a guided sentence, and a pa-ta-ka repetition task.',
          ),

          _instructionCard(
            Icons.analytics_outlined,
            'Multiple indicators',
            'The software examines pauses, speech activity, pitch, loudness, voice stability, speech rate, and other acoustic indicators.',
          ),

          const SizedBox(height: 20),

          Container(
            padding:
                const EdgeInsets.all(15),
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFFFF7E8),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color:
                      Color(0xFFB77A1B),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'These are preliminary software-based acoustic indicators. They are not a medical diagnosis and should not replace assessment by a qualified healthcare professional.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color:
                          Color(0xFF73551F),
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
            child:
                ElevatedButton.icon(
              onPressed:
                  _startAssessment,
              icon: const Icon(
                Icons.play_arrow_rounded,
              ),
              label: const Text(
                'Start Speech Assessment',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF7B61C9),
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(17),
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
      width: double.infinity,
      margin:
          const EdgeInsets.only(bottom: 10),
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(0xFFE2E7F0),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFF0EDFF),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color:
                  const Color(0xFF7B61C9),
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xFF303C52),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style:
                      const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color:
                        Color(0xFF707B90),
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
    final title =
        _phaseTitles[_currentPhase];

    final instruction =
        _phaseInstructions[
            _currentPhase];

    final prompt =
        _phasePrompts[_currentPhase];

    return SingleChildScrollView(
      key:
          const ValueKey('recording'),
      padding:
          const EdgeInsets.fromLTRB(
        22,
        20,
        22,
        30,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child:
                    _phaseIndicator(
                  0,
                  'Voice',
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child:
                    _phaseIndicator(
                  1,
                  'Sentence',
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child:
                    _phaseIndicator(
                  2,
                  'Repeat',
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          Text(
            'Task ${_currentPhase + 1} of 3',
            style:
                const TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF7B61C9),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            title,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 25,
              fontWeight:
                  FontWeight.w900,
              color:
                  Color(0xFF25324A),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            instruction,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 14,
              height: 1.5,
              color:
                  Color(0xFF707B90),
            ),
          ),

          const SizedBox(height: 30),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(22),
            decoration:
                BoxDecoration(
              gradient:
                  const LinearGradient(
                colors: [
                  Color(0xFFF0EDFF),
                  Color(0xFFF7F5FF),
                ],
              ),
              borderRadius:
                  BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.mic_rounded,
                  size: 58,
                  color:
                      Color(0xFF7B61C9),
                ),

                const SizedBox(height: 18),

                Text(
                  prompt,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xFF303C52),
                  ),
                ),

                const SizedBox(height: 15),

                Text(
                  '$_seconds seconds',
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(0xFF7B61C9),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            'Speak naturally. Do not intentionally change your voice.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              fontSize: 13,
              height: 1.4,
              color:
                  Color(0xFF7A8499),
            ),
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: 190,
            height: 54,
            child:
                ElevatedButton.icon(
              onPressed:
                  _stopCurrentPhase,
              icon: const Icon(
                Icons.stop_rounded,
              ),
              label: const Text(
                'Finish This Task',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFDB5A5A),
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(17),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _phaseIndicator(
    int index,
    String label,
  ) {
    final isCurrent =
        index == _currentPhase;

    final isComplete =
        _phaseResults[index] != null;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 9,
        horizontal: 5,
      ),
      decoration:
          BoxDecoration(
        color: isCurrent
            ? const Color(0xFFEDE9FF)
            : isComplete
                ? const Color(0xFFE8F6F0)
                : Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? const Color(0xFF7B61C9)
              : const Color(0xFFE2E7F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            isComplete
                ? Icons.check_circle_rounded
                : Icons.circle_outlined,
            size: 17,
            color: isComplete
                ? const Color(0xFF55A88A)
                : isCurrent
                    ? const Color(
                        0xFF7B61C9,
                      )
                    : const Color(
                        0xFF9AA4B5,
                      ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight:
                  FontWeight.w700,
              color: isCurrent
                  ? const Color(
                      0xFF7B61C9,
                    )
                  : const Color(
                      0xFF69758A,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final analysis = _analysis!;

    return SingleChildScrollView(
      key:
          const ValueKey('result'),
      padding:
          const EdgeInsets.fromLTRB(
        22,
        20,
        22,
        30,
      ),
      child: Column(
        children: [
          const Text(
            'Assessment Complete',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 25,
              fontWeight:
                  FontWeight.w900,
              color:
                  Color(0xFF25324A),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Preliminary Acoustic Speech Analysis',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF7B61C9),
            ),
          ),

          const SizedBox(height: 22),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(22),
            decoration:
                BoxDecoration(
              gradient:
                  const LinearGradient(
                colors: [
                  Color(0xFFEDE9FF),
                  Color(0xFFF5F2FF),
                ],
              ),
              borderRadius:
                  BorderRadius.circular(25),
            ),
            child: Column(
              children: [
                const Text(
                  'Experimental Composite Index',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(0xFF5E5875),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  analysis.compositeScore
                      .toStringAsFixed(1),
                  style:
                      const TextStyle(
                    fontSize: 44,
                    fontWeight:
                        FontWeight.w900,
                    color:
                        Color(0xFF7B61C9),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'For software-based tracking only',
                  style:
                      TextStyle(
                    fontSize: 11.5,
                    color:
                        Color(0xFF7A8499),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          _sectionTitle(
            'Voice characteristics',
          ),

          const SizedBox(height: 10),

          _metricGrid([
            _metricData(
              Icons.timer_outlined,
              'Duration',
              '${analysis.totalDuration.toStringAsFixed(1)} s',
            ),
            _metricData(
              Icons.pause_circle_outline_rounded,
              'Pauses',
              '${analysis.pauseCount}',
            ),
            _metricData(
              Icons.speed_rounded,
              'Speech rate',
              '${analysis.speechRate.toStringAsFixed(1)} peaks/s',
            ),
            _metricData(
              Icons.graphic_eq_rounded,
              'Pitch variation',
              analysis.pitchVariation.toStringAsFixed(3),
            ),
            _metricData(
              Icons.volume_up_rounded,
              'Loudness',
              '${analysis.averageLoudnessDb.toStringAsFixed(1)} dB',
            ),
            _metricData(
              Icons.multiline_chart_rounded,
              'Speech activity',
              '${(analysis.speechActivityRatio * 100).toStringAsFixed(1)}%',
            ),
          ]),

          const SizedBox(height: 16),

          _metricCard(
            Icons.air_rounded,
            'Breathiness indicator',
            analysis.breathiness
                .toStringAsFixed(1),
          ),

          const SizedBox(height: 10),

          _metricCard(
            Icons.graphic_eq_rounded,
            'Voice stability',
            '${analysis.voiceStability.toStringAsFixed(1)}%',
          ),

          const SizedBox(height: 10),

          _metricCard(
            Icons.multiline_chart_rounded,
            'Pitch stability',
            '${analysis.pitchStability.toStringAsFixed(1)}%',
          ),

          const SizedBox(height: 10),

          _metricCard(
            Icons.pause_circle_outline_rounded,
            'Average pause',
            '${analysis.averagePauseDuration.toStringAsFixed(2)} s',
          ),

          const SizedBox(height: 22),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(18),
            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(19),
              border: Border.all(
                color:
                    const Color(0xFFE2E7F0),
              ),
            ),
            child: const Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color:
                          Color(0xFF7B61C9),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'How to interpret this',
                      style:
                          TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(0xFF303C52),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'The displayed values are acoustic measurements calculated from the recorded samples. Changes over repeated assessments may be useful for tracking, but the values are not diagnostic by themselves.',
                  style:
                      TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color:
                        Color(0xFF69758A),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 52,
            child:
                ElevatedButton.icon(
              onPressed:
                  _isSaving
                      ? null
                      : _saveResult,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.cloud_upload_outlined,
                    ),
              label: Text(
                _isSaving
                    ? 'Saving...'
                    : 'Save Assessment',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF7B61C9),
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(17),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 52,
            child:
                OutlinedButton.icon(
              onPressed: _isSaving
                  ? null
                  : _restartAssessment,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Take Assessment Again',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    const Color(0xFF7B61C9),
                side:
                    const BorderSide(
                  color:
                      Color(0xFF7B61C9),
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(17),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'This assessment is a software-based screening and progress-tracking feature. It is not a standalone medical diagnosis.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color:
                  Color(0xFF8A94A5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    String title,
  ) {
    return Align(
      alignment:
          Alignment.centerLeft,
      child: Text(
        title,
        style:
            const TextStyle(
          fontSize: 17,
          fontWeight:
              FontWeight.w800,
          color:
              Color(0xFF303C52),
        ),
      ),
    );
  }

  Widget _metricGrid(
    List<MetricData> metrics,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.65,
      ),
      itemBuilder:
          (context, index) {
        final metric =
            metrics[index];

        return _metricCard(
          metric.icon,
          metric.label,
          metric.value,
        );
      },
    );
  }

  MetricData _metricData(
    IconData icon,
    String label,
    String value,
  ) {
    return MetricData(
      icon: icon,
      label: label,
      value: value,
    );
  }

  Widget _metricCard(
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color:
              const Color(0xFFE2E7F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFF0EDFF),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color:
                  const Color(0xFF7B61C9),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 10.5,
                    color:
                        Color(0xFF7A8499),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 15,
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
}

class MetricData {
  final IconData icon;
  final String label;
  final String value;

  const MetricData({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class WavData {
  final int sampleRate;
  final List<double> samples;

  const WavData({
    required this.sampleRate,
    required this.samples,
  });
}

class SpeechPhaseResult {
  final double duration;
  final double activeRatio;
  final int pauseCount;
  final double averagePauseDuration;
  final double averageLoudnessDb;
  final double pitchMean;
  final double pitchVariation;
  final double pitchStability;
  final double voiceStability;
  final double breathiness;
  final double speechRate;

  const SpeechPhaseResult({
    required this.duration,
    required this.activeRatio,
    required this.pauseCount,
    required this.averagePauseDuration,
    required this.averageLoudnessDb,
    required this.pitchMean,
    required this.pitchVariation,
    required this.pitchStability,
    required this.voiceStability,
    required this.breathiness,
    required this.speechRate,
  });
}

class SpeechAnalysisResult {
  final double compositeScore;
  final double totalDuration;
  final double speechActivityRatio;
  final int pauseCount;
  final double averagePauseDuration;
  final double speechRate;
  final double pitchMean;
  final double pitchVariation;
  final double pitchStability;
  final double averageLoudnessDb;
  final double voiceStability;
  final double breathiness;

  const SpeechAnalysisResult({
    required this.compositeScore,
    required this.totalDuration,
    required this.speechActivityRatio,
    required this.pauseCount,
    required this.averagePauseDuration,
    required this.speechRate,
    required this.pitchMean,
    required this.pitchVariation,
    required this.pitchStability,
    required this.averageLoudnessDb,
    required this.voiceStability,
    required this.breathiness,
  });

  factory SpeechAnalysisResult.fromPhases({
    required SpeechPhaseResult vowel,
    required SpeechPhaseResult sentence,
    required SpeechPhaseResult syllable,
  }) {
    final totalDuration =
        vowel.duration +
            sentence.duration +
            syllable.duration;

    final activity =
        (vowel.activeRatio +
                sentence.activeRatio +
                syllable.activeRatio) /
            3;

    final pauseCount =
        vowel.pauseCount +
            sentence.pauseCount +
            syllable.pauseCount;

    final totalPauseDuration =
        vowel.averagePauseDuration *
                vowel.pauseCount +
            sentence.averagePauseDuration *
                sentence.pauseCount +
            syllable.averagePauseDuration *
                syllable.pauseCount;

    final averagePause =
        pauseCount == 0
            ? 0.0
            : totalPauseDuration /
                pauseCount;

    final speechRate =
        (sentence.speechRate +
                syllable.speechRate) /
            2;

    final pitchValues = [
      if (vowel.pitchMean > 0)
        vowel.pitchMean,
      if (sentence.pitchMean > 0)
        sentence.pitchMean,
      if (syllable.pitchMean > 0)
        syllable.pitchMean,
    ];

    final pitchMean =
        pitchValues.isEmpty
            ? 0.0
            : pitchValues.reduce(
                  (a, b) => a + b,
                ) /
                pitchValues.length;

    final pitchVariation =
        (vowel.pitchVariation +
                sentence.pitchVariation +
                syllable.pitchVariation) /
            3;

    final pitchStability =
        (vowel.pitchStability +
                sentence.pitchStability +
                syllable.pitchStability) /
            3;

    final loudness =
        (vowel.averageLoudnessDb +
                sentence.averageLoudnessDb +
                syllable.averageLoudnessDb) /
            3;

    final voiceStability =
        (vowel.voiceStability +
                sentence.voiceStability +
                syllable.voiceStability) /
            3;

    final breathiness =
        (vowel.breathiness +
                sentence.breathiness +
                syllable.breathiness) /
            3;

    final activityScore =
        activity.clamp(0.0, 1.0) * 100;

    final stabilityScore =
        voiceStability.clamp(
          0.0,
          100.0,
        );

    final pitchScore =
        pitchStability.clamp(
          0.0,
          100.0,
        );

    final speechRateScore =
        (100 -
                ((speechRate - 4).abs() *
                    12))
            .clamp(0.0, 100.0);

    final pauseScore =
        (100 -
                (averagePause * 40))
            .clamp(0.0, 100.0);

    final composite =
        activityScore * 0.20 +
            stabilityScore * 0.20 +
            pitchScore * 0.20 +
            speechRateScore * 0.15 +
            pauseScore * 0.10 +
            (100 - breathiness).clamp(
              0.0,
              100.0,
            ) *
                0.15;

    return SpeechAnalysisResult(
      compositeScore:
          composite.clamp(0.0, 100.0),
      totalDuration: totalDuration,
      speechActivityRatio: activity,
      pauseCount: pauseCount,
      averagePauseDuration:
          averagePause,
      speechRate: speechRate,
      pitchMean: pitchMean,
      pitchVariation:
          pitchVariation,
      pitchStability:
          pitchStability,
      averageLoudnessDb:
          loudness,
      voiceStability:
          voiceStability,
      breathiness:
          breathiness,
    );
  }
}
