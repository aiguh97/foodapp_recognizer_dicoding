// lib/pages/recipe_detail_page.dart

import 'package:flutter/material.dart';
import '../services/recipe_service.dart';
import '../widgets/ingredients_tab.dart';
import '../widgets/procedure_tab.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeName;
  const RecipeDetailScreen({super.key, required this.recipeName});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Future<Map<String, dynamic>> _futureRecipe;
  int _activeTab = 0; // 0 = ingredients, 1 = procedure

  @override
  void initState() {
    super.initState();
    _futureRecipe = RecipeService().fetchRecipeByName(widget.recipeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _futureRecipe,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            final recipe = snapshot.data!;
            final title = recipe['strMeal'] ?? "";
            final imageUrl = recipe['strMealThumb'] ?? "";

            // instructions safe cast
            final instructionsRaw = recipe['strInstructions'];
            final instructions = instructionsRaw is String
                ? instructionsRaw
                : "";
            final steps = instructions
                .split(RegExp(r'[\r\n]+'))
                .where((s) => s.trim().isNotEmpty)
                .toList();

            // parse ingredients
            final ingredients = <Map<String, String>>[];
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

            return Column(
              children: [
                // Gambar header
                imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : const SizedBox.shrink(),

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

                // Custom Tab Bar (pill style)
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
                          onTap: () => setState(() => _activeTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _activeTab == 0
                                  ? Colors.green
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Ingredients",
                              style: TextStyle(
                                color: _activeTab == 0
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
                          onTap: () => setState(() => _activeTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _activeTab == 1
                                  ? Colors.green
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Procedure",
                              style: TextStyle(
                                color: _activeTab == 1
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

                // Content
                Expanded(
                  child: _activeTab == 0
                      ? IngredientsTab(ingredients: ingredients)
                      : ProcedureTab(steps: steps),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
