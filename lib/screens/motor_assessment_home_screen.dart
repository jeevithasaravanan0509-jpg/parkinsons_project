import 'package:flutter/material.dart';

import 'finger_tapping_screen.dart';
import 'line_tracing_screen.dart';
import 'motor_assessment_screen.dart';
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),

            const SizedBox(height: 24),

            const Text(
              'Choose a test',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF25324A),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Complete a guided activity and let the app '
              'analyze your movement automatically.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: Color(0xFF7A8499),
              ),
            ),

            const SizedBox(height: 20),

            // -------------------------------------------------
            // 1. SPIRAL TRACE
            // -------------------------------------------------
            _buildTestCard(
              context,
              icon: Icons.gesture_rounded,
              title: 'Spiral Trace',
              description:
                  'Trace the spiral while the app measures '
                  'movement and path variation.',
              color: const Color(0xFF6C63FF),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const MotorAssessmentScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            // -------------------------------------------------
            // 2. WRITING TEST
            // -------------------------------------------------
            _buildTestCard(
              context,
              icon: Icons.edit_rounded,
              title: 'Writing Test',
              description:
                  'Write a guided phrase naturally for '
                  'handwriting movement analysis.',
              color: const Color(0xFF4D8EDC),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const WritingTestScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            // -------------------------------------------------
            // 3. LINE TRACING
            // -------------------------------------------------
            _buildTestCard(
              context,
              icon: Icons.timeline_rounded,
              title: 'Line Tracing',
              description:
                  'Follow a target line while the app '
                  'measures your tracing accuracy.',
              color: const Color(0xFF55A88A),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const LineTracingScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            // -------------------------------------------------
            // 4. FINGER TAPPING
            // -------------------------------------------------
            _buildTestCard(
              context,
              icon: Icons.touch_app_rounded,
              title: 'Finger Tapping',
              description:
                  'Tap repeatedly while the app measures '
                  'your tapping rhythm and consistency.',
              color: const Color(0xFF8B78D9),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const FingerTappingScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            _buildInfoCard(),
          ],
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
            Icons.psychology_alt_rounded,
            size: 38,
            color: Color(0xFF6C63FF),
          ),
          SizedBox(height: 14),
          Text(
            'Movement Screening',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: Color(0xFF25324A),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Perform simple guided activities while '
            'Parkinson Care analyzes your movement.',
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
  // TEST CARD
  // =========================================================

  Widget _buildTestCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: const Color(0xFFE4E9F2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 29,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF303C52),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: Color(0xFF7A8499),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFA2ABBA),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // INFORMATION CARD
  // =========================================================

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9ED),
        borderRadius: BorderRadius.circular(18),
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
            color: Color(0xFFB58532),
            size: 21,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'These activities are intended for movement '
              'screening and tracking. They are not a '
              'standalone medical diagnosis.',
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