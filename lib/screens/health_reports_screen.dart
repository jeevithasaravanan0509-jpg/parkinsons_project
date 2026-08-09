import 'package:flutter/material.dart';

class HealthReportsScreen extends StatelessWidget {
  const HealthReportsScreen({super.key});


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "Health Reports",
        ),

      ),


      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),


        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,


          children: [


            const Text(

              "Patient Health Summary",

              style: TextStyle(

                fontSize: 24,

                fontWeight:
                    FontWeight.bold,

              ),

            ),


            const SizedBox(height: 10),


            const Text(

              "Track your overall progress and daily activities.",

              style: TextStyle(

                fontSize: 16,

                color: Colors.grey,

              ),

            ),



            const SizedBox(height: 25),



            _reportCard(

              icon: Icons.monitor_heart,

              title: "Symptom Progress",

              value: "Improving",

              description:
                  "Symptoms recorded regularly",

              color: Colors.blue,

            ),



            _reportCard(

              icon: Icons.medication,

              title: "Medication Adherence",

              value: "90%",

              description:
                  "Medicine schedule followed",

              color: Colors.green,

            ),



            _reportCard(

              icon: Icons.directions_run,

              title: "Physiotherapy Progress",

              value: "75%",

              description:
                  "Exercise completion rate",

              color: Colors.orange,

            ),



            _reportCard(

              icon: Icons.health_and_safety,

              title: "Overall Health Status",

              value: "Good",

              description:
                  "Based on recent activity",

              color: Colors.purple,

            ),



            const SizedBox(height: 25),



            SizedBox(

              width: double.infinity,


              child: ElevatedButton(

                onPressed: () {


                  ScaffoldMessenger.of(context)
                      .showSnackBar(

                    const SnackBar(

                      content: Text(

                        "Report generated successfully",

                      ),

                    ),

                  );


                },


                child: const Text(

                  "Generate Report",

                ),

              ),

            ),


          ],

        ),

      ),

    );

  }



  Widget _reportCard({

    required IconData icon,

    required String title,

    required String value,

    required String description,

    required Color color,

  }) {


    return Card(

      elevation: 3,

      margin: const EdgeInsets.only(

        bottom: 15,

      ),


      child: ListTile(

        leading: CircleAvatar(

          backgroundColor: color,

          child: Icon(

            icon,

            color: Colors.white,

          ),

        ),


        title: Text(

          title,

          style: const TextStyle(

            fontWeight:
                FontWeight.bold,

          ),

        ),


        subtitle: Text(

          description,

        ),


        trailing: Text(

          value,

          style: const TextStyle(

            fontSize: 16,

            fontWeight:
                FontWeight.bold,

          ),

        ),

      ),

    );

  }

}