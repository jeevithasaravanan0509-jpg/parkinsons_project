import 'package:flutter/material.dart';

class PhysiotherapyScreen extends StatefulWidget {
  const PhysiotherapyScreen({super.key});

  @override
  State<PhysiotherapyScreen> createState() =>
      _PhysiotherapyScreenState();
}

class _PhysiotherapyScreenState
    extends State<PhysiotherapyScreen> {

  List<Map<String, dynamic>> exercises = [

    {
      "name": "Hand Movement Exercise",
      "duration": "10 minutes",
      "completed": false,
    },

    {
      "name": "Balance Training",
      "duration": "15 minutes",
      "completed": false,
    },

    {
      "name": "Walking Practice",
      "duration": "20 minutes",
      "completed": false,
    },

    {
      "name": "Stretching Exercise",
      "duration": "10 minutes",
      "completed": false,
    },

  ];


  int get completedCount {

    return exercises
        .where((exercise) => exercise["completed"] == true)
        .length;

  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "Physiotherapy",
        ),

      ),


      body: Padding(

        padding: const EdgeInsets.all(20),


        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,


          children: [


            const Text(

              "Daily Exercise Plan",

              style: TextStyle(

                fontSize: 24,

                fontWeight:
                    FontWeight.bold,

              ),

            ),


            const SizedBox(height: 10),


            Text(

              "Completed: $completedCount/${exercises.length}",

              style: const TextStyle(

                fontSize: 16,

                color: Colors.grey,

              ),

            ),


            const SizedBox(height: 20),


            Expanded(

              child: ListView.builder(

                itemCount: exercises.length,


                itemBuilder: (context, index) {


                  return Card(

                    elevation: 3,


                    child: CheckboxListTile(

                      title: Text(

                        exercises[index]["name"],

                        style: const TextStyle(

                          fontWeight:
                              FontWeight.bold,

                        ),

                      ),


                      subtitle: Text(

                        exercises[index]["duration"],

                      ),


                      value: exercises[index]
                          ["completed"],


                      onChanged: (value) {


                        setState(() {


                          exercises[index]
                              ["completed"] = value;


                        });


                      },

                    ),

                  );

                },

              ),

            ),


            SizedBox(

              width: double.infinity,


              child: ElevatedButton(

                onPressed: () {


                  ScaffoldMessenger.of(context)
                      .showSnackBar(

                    SnackBar(

                      content: Text(

                        "Great! You completed $completedCount exercises today.",

                      ),

                    ),

                  );


                },


                child: const Text(

                  "Save Progress",

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }
}