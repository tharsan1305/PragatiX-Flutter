import 'package:flutter/material.dart';

class MarksPage extends StatelessWidget {
  const MarksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Marks"),
      ),
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.school,
                  size: 80,
                ),

                SizedBox(height: 10),

                Text(
                  "Marks Details",
                  style: TextStyle(fontSize: 24),
                ),

                SizedBox(height: 10),

                Text(
                  "OOPS : 90",
                  style: TextStyle(fontSize: 18),
                ),

                Text(
                  "DSA : 85",
                  style: TextStyle(fontSize: 18),
                ),

                Text(
                  "DBMS : 88",
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