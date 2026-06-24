import 'package:flutter/material.dart';

class DisciplinePage extends StatelessWidget {
  const DisciplinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Discipline"),
      ),
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.gavel,
                  size: 80,
                ),

                SizedBox(height: 10),

                Text(
                  "Discipline Status",
                  style: TextStyle(
                    fontSize: 24,
                  ),
                ),

                SizedBox(height: 10),

                Text(
                  "Warnings : 0",
                  style: TextStyle(fontSize: 18),
                ),

                Text(
                  "Complaints : 0",
                  style: TextStyle(fontSize: 18),
                ),

                Text(
                  "Status : Good",
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}