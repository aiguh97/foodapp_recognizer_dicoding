import 'package:flutter/material.dart';
import '../services/recipe_service.dart';

class ResultProvider extends ChangeNotifier {
  final RecipeService _service = RecipeService();

  bool isLoading = false;
  String? error;
  Map<String, dynamic>? recipe;

  Future<void> fetchRecipe(String name) async {
    isLoading = true;
    error = null;
    recipe = null;
    notifyListeners();

    try {
      final data = await _service.fetchRecipeByName(name);
      recipe = data;
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }
}
