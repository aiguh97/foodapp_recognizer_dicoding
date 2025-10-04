import 'package:flutter/material.dart';
import '../services/recipe_service.dart';

class RecipeProvider extends ChangeNotifier {
  final String recipeName;
  Map<String, dynamic>? recipe;
  bool loading = true;
  String? error;
  int activeTab = 0; // 0 = ingredients, 1 = procedure

  RecipeProvider(this.recipeName) {
    fetchRecipe();
  }

  void fetchRecipe() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      recipe = await RecipeService().fetchRecipeByName(recipeName);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setActiveTab(int tabIndex) {
    activeTab = tabIndex;
    notifyListeners();
  }
}
