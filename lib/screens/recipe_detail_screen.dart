import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/ingredients_tab.dart';
import '../widgets/procedure_tab.dart';
import '../provider/recipe_provider.dart';

class RecipeDetailScreen extends StatelessWidget {
  final String recipeName;
  final File imageFile;

  const RecipeDetailScreen({
    super.key,
    required this.recipeName,
    required this.imageFile,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RecipeProvider(recipeName),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Ingredients & Procedure"),
          backgroundColor: const Color.fromARGB(255, 73, 158, 76),
        ),
        body: SafeArea(
          child: Consumer<RecipeProvider>(
            builder: (context, provider, _) {
              if (provider.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (provider.error != null) {
                return Center(child: Text("Error: ${provider.error}"));
              }

              final recipe = provider.recipe ?? {};
              final title = recipe['strMeal'] ?? "";
              final imageUrl = recipe['strMealThumb'] ?? "";

              // Instructions
              final instructionsRaw = recipe['strInstructions'];
              final instructions = instructionsRaw is String
                  ? instructionsRaw
                  : "";
              final steps = instructions
                  .split(RegExp(r'[\r\n]+'))
                  .where((s) => s.trim().isNotEmpty)
                  .toList();

              // Ingredients
              final ingredients = <Map<String, String>>[];

              if (recipe.containsKey("foodNutrients")) {
                final nutrients = recipe["foodNutrients"] as List;
                for (var n in nutrients) {
                  ingredients.add({
                    "ingredient": n["nutrientName"] ?? "",
                    "measure": "${n["value"] ?? ""} ${n["unitName"] ?? ""}"
                        .trim(),
                  });
                }
              } else {
                for (int i = 1; i <= 20; i++) {
                  final ingKey = 'strIngredient$i';
                  final measureKey = 'strMeasure$i';
                  final ing = recipe[ingKey];
                  final measure = recipe[measureKey];
                  if (ing != null && (ing as String).trim().isNotEmpty) {
                    ingredients.add({
                      'ingredient': ing.toString(),
                      'measure': (measure ?? "").toString(),
                    });
                  }
                }
              }

              return Column(
                children: [
                  // Tampilkan imageFile lokal dulu, kalau ada
                  if (imageFile.existsSync())
                    Image.file(
                      imageFile,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  else if (imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  else
                    const SizedBox(height: 200), // placeholder

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Tab bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => provider.setActiveTab(0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: provider.activeTab == 0
                                    ? Colors.green
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Ingredients",
                                style: TextStyle(
                                  color: provider.activeTab == 0
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => provider.setActiveTab(1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: provider.activeTab == 1
                                    ? Colors.green
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Procedure",
                                style: TextStyle(
                                  color: provider.activeTab == 1
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: provider.activeTab == 0
                        ? IngredientsTab(ingredients: ingredients)
                        : ProcedureTab(steps: steps),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
