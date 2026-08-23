import 'package:flutter/material.dart';

import 'device_connection_screen.dart';
import 'history_screen.dart';
import 'medication_screen.dart';
import 'motor_progress_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';
import 'symptom_tracking_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FE),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F9FE),
        centerTitle: true,

        title: const Text(
          'Parkinson Care',
          style: TextStyle(
            color: Color(0xFF25324A),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'My Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
              icon: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF6385E5),
                  size: 23,
                ),
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting section
            const Text(
              'Welcome 👋',
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w700,
                color: Color(0xFF25324A),
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Monitor your health every day.',
              style: TextStyle(
                color: Color(0xFF7A8499),
                fontSize: 15.5,
              ),
            ),

            const SizedBox(height: 26),

            // Quick overview card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFEAF2FF),
                    Color(0xFFF2EEFF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFF6385E5),
                      size: 27,
                    ),
                  ),

                  const SizedBox(width: 15),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your care journey',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF303C52),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Stay consistent with your daily tracking.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Care Tools',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF25324A),
              ),
            ),

            const SizedBox(height: 14),

            // Dashboard cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.05,
              children: [
                _dashboardCard(
                  context,
                  title: 'Symptom\nTracker',
                  icon: Icons.monitor_heart_rounded,
                  color: const Color(0xFF6385E5),
                  page: const SymptomTrackingScreen(),
                ),

                _dashboardCard(
                  context,
                  title: 'Assessment\nHistory',
                  icon: Icons.history_rounded,
                  color: const Color(0xFF67B99A),
                  page: const HistoryScreen(),
                ),

                _dashboardCard(
                  context,
                  title: 'Medication',
                  icon: Icons.medication_rounded,
                  color: const Color(0xFFE9A45B),
                  page: const MedicationScreen(),
                ),

                _dashboardCard(
                  context,
                  title: 'Reports',
                  icon: Icons.bar_chart_rounded,
                  color: const Color(0xFF9A7EDB),
                  page: const ReportsScreen(),
                ),

                _dashboardCard(
                  context,
                  title: 'Motor\nProgress',
                  icon: Icons.insights_rounded,
                  color: const Color(0xFF4D8EDC),
                  page: const MotorProgressScreen(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Device connection
            SizedBox(
              width: double.infinity,
              height: 68,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const DeviceConnectionScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.watch_outlined,
                  size: 25,
                ),
                label: const Text(
                  'Device & Tracking Mode',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6E78C9),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(19),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 26),

            // Daily tip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Color(0xFFE3A34B),
                        size: 24,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Daily Tip',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF25324A),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  Text(
                    'Keep track of your symptoms and medication regularly. Consistent tracking can help you and your healthcare team understand changes over time.',
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.55,
                      color: Color(0xFF68758A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => page,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 31,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15.5,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
