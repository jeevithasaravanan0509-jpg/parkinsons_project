import 'package:flutter/material.dart';

import 'finger_tapping_screen.dart';
import 'line_tracing_screen.dart';
import 'motor_assessment_screen.dart';
import 'speech_assessment_screen.dart';
import 'writing_test_screen.dart';

class MotorAssessmentHomeScreen extends StatelessWidget {
  const MotorAssessmentHomeScreen({super.key});

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
          'Motor Assessment',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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

              const SizedBox(height: 22),

              const Text(
                'Choose an assessment',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF25324A),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Complete these short movement and speech tests '
                'to track performance over time.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Color(0xFF7A8499),
                ),
              ),

              const SizedBox(height: 18),

              // =====================================================
              // SPIRAL TRACE
              // =====================================================

              _buildAssessmentCard(
                context: context,
                icon: Icons.gesture_rounded,
                iconColor: const Color(0xFF6C63FF),
                iconBackground: const Color(0xFFEEF2FF),
                title: 'Spiral Trace',
                description:
                    'Trace a guided spiral while the app '
                    'records path deviation and movement smoothness.',
                tag: 'Hand movement',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MotorAssessmentScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // =====================================================
              // LINE TRACING
              // =====================================================

              _buildAssessmentCard(
                context: context,
                icon: Icons.linear_scale_rounded,
                iconColor: const Color(0xFF55A88A),
                iconBackground: const Color(0xFFEAF8F2),
                title: 'Line Tracing',
                description:
                    'Follow a guided line to assess the steadiness '
                    'and consistency of your hand movement.',
                tag: 'Precision',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LineTracingScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // =====================================================
              // WRITING TEST
              // =====================================================

              _buildAssessmentCard(
                context: context,
                icon: Icons.edit_rounded,
                iconColor: const Color(0xFF4D8EDC),
                iconBackground: const Color(0xFFEAF2FF),
                title: 'Writing Test',
                description:
                    'Write a short phrase naturally while the app '
                    'records writing movement and smoothness.',
                tag: 'Handwriting',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WritingTestScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // =====================================================
              // FINGER TAPPING
              // =====================================================

              _buildAssessmentCard(
                context: context,
                icon: Icons.touch_app_rounded,
                iconColor: const Color(0xFFD86B78),
                iconBackground: const Color(0xFFFFEEF0),
                title: 'Finger Tapping',
                description:
                    'Perform repeated finger taps to measure '
                    'movement speed and consistency.',
                tag: 'Movement speed',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FingerTappingTestScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // =====================================================
              // SPEECH ASSESSMENT
              // =====================================================

              _buildAssessmentCard(
                context: context,
                icon: Icons.record_voice_over_rounded,
                iconColor: const Color(0xFF7B61C9),
                iconBackground: const Color(0xFFF0EDFF),
                title: 'Speech Assessment',
                description:
                    'Record a short speech sample to observe '
                    'basic speech characteristics and performance.',
                tag: 'Speech',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SpeechAssessmentScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 22),

              _buildInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // HEADER
  // ===============================================================

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.accessibility_new_rounded,
            size: 36,
            color: Color(0xFF6C63FF),
          ),

          SizedBox(height: 14),

          Text(
            'Motor Function Assessment',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF25324A),
            ),
          ),

          SizedBox(height: 8),

          Text(
            'Use simple software-based tests to observe '
            'hand movement, coordination, precision, '
            'writing, tapping and speech performance.',
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

  // ===============================================================
  // ASSESSMENT CARD
  // ===============================================================

  Widget _buildAssessmentCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String title,
    required String description,
    required String tag,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: const Color(0xFFE3E8F2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 27,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF25324A),
                            ),
                          ),
                        ),

                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 15,
                          color: Color(0xFF9AA3B3),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: Color(0xFF7A8499),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: iconBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // INFORMATION CARD
  // ===============================================================

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9ED),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFF0DFB8),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 21,
            color: Color(0xFFB58532),
          ),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'These assessments are software-based screening '
              'tools. They are intended for tracking and '
              'observation, not for diagnosing Parkinson’s '
              'disease or any other medical condition.',
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
}