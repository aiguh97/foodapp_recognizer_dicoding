import 'package:flutter/material.dart';
import 'package:foodapp_recognizer/screens/recipe_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:foodapp_recognizer/services/recipe_service.dart';

class ResultScreen extends StatelessWidget {
  final String label; // nama hasil prediksi (contoh: "Nasi Lemak")
  final double confidence; // confidence hasil prediksi (0.0 - 1.0)

  const ResultScreen({
    super.key,
    required this.label,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final recipeService = Provider.of<RecipeService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Result Page"),
        backgroundColor: Color(0XFF3DA0A7),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: recipeService.fetchRecipeByName(label),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("No recipe data found."));
          }

          final recipe = snapshot.data!;
          final mealName = recipe['strMeal'] ?? label;
          final mealThumb = recipe['strMealThumb'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Gambar utama
                if (mealThumb != null)
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipeDetailScreen(recipeName: label),
                          // builder: (_) =>
                          //     ResultScreen(label: "sushi", confidence: 0.8),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        mealThumb,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Nama + confidence
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      mealName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${(confidence * 100).toStringAsFixed(2)}%",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
                const Divider(height: 30),

                // Nutrition Facts (dummy data sementara)
                const Text(
                  "Nutrition Facts",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildNutritionRow("Calories", "450 g"),
                _buildNutritionRow("Carbs", "50 g"),
                _buildNutritionRow("Fat", "25 g"),
                _buildNutritionRow("Fiber", "3 g"),
                _buildNutritionRow("Protein", "10 g"),
                const Divider(height: 30),

                // Reference
                const Text(
                  "Reference",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(recipeName: label),
                        // builder: (_) =>
                        //     ResultScreen(label: "sushi", confidence: 0.8),
                      ),
                    );
                  },
                  child: ListTile(
                    leading: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RecipeDetailScreen(recipeName: label),
                            // builder: (_) =>
                            //     ResultScreen(label: "sushi", confidence: 0.8),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(mealThumb ?? ""),
                      ),
                    ),
                    title: Text(mealName),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
