import 'package:flutter/material.dart';

import '../services/symptom_service.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = SymptomService.instance;

    final latest = service.getLatestAssessment();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Health Reports"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: latest == null
            ? const Center(
                child: Text(
                  "No Assessment Available",
                  style: TextStyle(fontSize: 18),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                      ),
                      title: const Text("Current Health Score"),
                      subtitle: Text(
                        "${latest.healthScore.toStringAsFixed(1)} %",
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.analytics),
                      title: const Text("Average Health Score"),
                      subtitle: Text(
                        "${service.getAverageHealthScore().toStringAsFixed(1)} %",
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text("Total Assessments"),
                      subtitle: Text(
                        service.totalAssessments.toString(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Latest Notes",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      latest.notes.isEmpty
                          ? "No Notes"
                          : latest.notes,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}