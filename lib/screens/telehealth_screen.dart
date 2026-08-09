import 'package:flutter/material.dart';

class TelehealthScreen extends StatelessWidget {
  const TelehealthScreen({super.key});


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "Telehealth",
        ),

      ),


      body: Padding(

        padding: const EdgeInsets.all(20),


        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,


          children: [


            const Text(

              "Healthcare Support",

              style: TextStyle(

                fontSize: 24,

                fontWeight:
                    FontWeight.bold,

              ),

            ),


            const SizedBox(height: 10),


            const Text(

              "Connect with healthcare professionals from anywhere.",

              style: TextStyle(

                fontSize: 16,

                color: Colors.grey,

              ),

            ),


            const SizedBox(height: 25),



            Card(

              elevation: 3,


              child: ListTile(

                leading: const CircleAvatar(

                  child: Icon(
                    Icons.person,
                  ),

                ),


                title: const Text(

                  "Dr. Arun Kumar",

                ),


                subtitle: const Text(

                  "Neurologist",

                ),


                trailing: IconButton(

                  icon: const Icon(

                    Icons.video_call,

                    color: Colors.blue,

                  ),


                  onPressed: () {


                    ScaffoldMessenger.of(context)
                        .showSnackBar(

                      const SnackBar(

                        content: Text(

                          "Starting video consultation...",

                        ),

                      ),

                    );


                  },

                ),

              ),

            ),



            Card(

              elevation: 3,


              child: ListTile(

                leading: const CircleAvatar(

                  child: Icon(
                    Icons.person,
                  ),

                ),


                title: const Text(

                  "Dr. Priya Sharma",

                ),


                subtitle: const Text(

                  "Physiotherapist",

                ),


                trailing: IconButton(

                  icon: const Icon(

                    Icons.video_call,

                    color: Colors.blue,

                  ),


                  onPressed: () {


                    ScaffoldMessenger.of(context)
                        .showSnackBar(

                      const SnackBar(

                        content: Text(

                          "Connecting with physiotherapist...",

                        ),

                      ),

                    );


                  },

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

                        "Appointment request sent",

                      ),

                    ),

                  );


                },


                child: const Text(

                  "Book Appointment",

                ),

              ),

            ),


          ],

        ),

      ),

    );

  }
}