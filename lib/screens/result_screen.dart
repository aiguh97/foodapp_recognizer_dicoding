import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodapp_recognizer/services/recipe_service.dart';
import 'package:foodapp_recognizer/screens/recipe_detail_screen.dart';

class ResultScreen extends StatelessWidget {
  final String label;
  final double confidence;
  final File imageFile;

  const ResultScreen({
    super.key,
    required this.label,
    required this.confidence,
    required this.imageFile, // wajib kirim dari page sebelumnya
  });

  @override
  Widget build(BuildContext context) {
    final recipeService = Provider.of<RecipeService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recognition Result"),
        backgroundColor: const Color.fromARGB(255, 73, 158, 76),
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
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("No recipe data found."));
          }

          final recipe = snapshot.data!;
          final isMealDb = recipe.containsKey("strMeal");
          final isUsda =
              recipe.containsKey("name") && recipe.containsKey("dataType");

          final mealName = isMealDb
              ? recipe['strMeal']
              : recipe['name'] ?? label;

          final source = isMealDb ? "TheMealDB" : "USDA FoodData Central";

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🔹 Gambar utama dari kamera/galeri
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    imageFile,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(height: 12),

                const SizedBox(height: 16),

                // Nama + confidence
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        mealName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      "${(confidence * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Source: $source",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),

                const Divider(height: 30),

                // Info tambahan
                if (isUsda) ...[
                  Text(
                    "Brand: ${recipe['brand'] ?? 'Unknown'}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    "Data Type: ${recipe['dataType']}",
                    style: const TextStyle(fontSize: 16),
                  ),
                ] else ...[
                  const Text(
                    "Nutrition Facts (sample)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildNutritionRow("Calories", "450 kcal"),
                  _buildNutritionRow("Carbs", "50 g"),
                  _buildNutritionRow("Fat", "25 g"),
                  _buildNutritionRow("Protein", "10 g"),
                ],

                const Divider(height: 30),

                if (isMealDb)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipeDetailScreen(
                            recipeName: mealName,
                            imageFile: imageFile,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("View Full Recipe"),
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
