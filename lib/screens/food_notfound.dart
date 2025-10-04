import 'package:flutter/material.dart';

class FoodNotFound extends StatelessWidget {
  final String label;
  const FoodNotFound({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Result Page"),
        backgroundColor: Color(0XFF3DA0A7),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset("assets/images/food_notfound.png"),
            Text('$label'),
          ],
        ),
      ),
    );
  }
}
