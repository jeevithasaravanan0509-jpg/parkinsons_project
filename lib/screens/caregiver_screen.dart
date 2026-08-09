import 'package:flutter/material.dart';

class CaregiverScreen extends StatelessWidget {
  const CaregiverScreen({super.key});


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "Caregiver Support",
        ),

      ),


      body: Padding(

        padding: const EdgeInsets.all(20),


        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,


          children: [


            const Text(

              "Caregiver Dashboard",

              style: TextStyle(

                fontSize: 24,

                fontWeight:
                    FontWeight.bold,

              ),

            ),



            const SizedBox(height: 10),



            const Text(

              "Monitor patient activities and health updates.",

              style: TextStyle(

                fontSize: 16,

                color: Colors.grey,

              ),

            ),



            const SizedBox(height: 25),



            Card(

              elevation: 3,


              child: ListTile(

                leading: const Icon(

                  Icons.person,

                  color: Colors.blue,

                ),


                title: const Text(

                  "Patient Information",

                ),


                subtitle: const Text(

                  "View patient details and profile",

                ),

              ),

            ),



            Card(

              elevation: 3,


              child: ListTile(

                leading: const Icon(

                  Icons.medication,

                  color: Colors.green,

                ),


                title: const Text(

                  "Medication Status",

                ),


                subtitle: const Text(

                  "Check medicine schedule and completion",

                ),

              ),

            ),



            Card(

              elevation: 3,


              child: ListTile(

                leading: const Icon(

                  Icons.monitor_heart,

                  color: Colors.red,

                ),


                title: const Text(

                  "Health Updates",

                ),


                subtitle: const Text(

                  "View recent symptom reports",

                ),

              ),

            ),



            Card(

              elevation: 3,


              child: ListTile(

                leading: const Icon(

                  Icons.notifications,

                  color: Colors.orange,

                ),


                title: const Text(

                  "Alerts & Reminders",

                ),


                subtitle: const Text(

                  "Receive important notifications",

                ),

              ),

            ),



            const SizedBox(height: 20),



            SizedBox(

              width: double.infinity,


              child: ElevatedButton(

                onPressed: () {


                  ScaffoldMessenger.of(context)
                      .showSnackBar(

                    const SnackBar(

                      content: Text(

                        "Caregiver report shared",

                      ),

                    ),

                  );


                },


                child: const Text(

                  "Share Patient Report",

                ),

              ),

            ),


          ],

        ),

      ),

    );

  }
}