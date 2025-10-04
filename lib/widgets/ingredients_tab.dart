// lib/widgets/ingredients_tab.dart
import 'package:flutter/material.dart';

class IngredientsTab extends StatelessWidget {
  final List<Map<String, String>> ingredients;

  const IngredientsTab({super.key, required this.ingredients});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ingredients.length,
      itemBuilder: (context, index) {
        final item = ingredients[index];
        final ingredientName = item['ingredient'] ?? "";
        final measure = item['measure'] ?? "";

        // generate image url dari TheMealDB
        final imageUrl =
            "https://www.themealdb.com/images/ingredients/${Uri.encodeComponent(ingredientName)}-Small.png";

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Image.network(
              imageUrl,
              width: 40,
              height: 40,
              errorBuilder: (_, __, ___) {
                return const Icon(Icons.fastfood, color: Colors.grey);
              },
            ),
            title: Text(ingredientName),
            trailing: Text(measure),
          ),
        );
      },
    );
  }
}
