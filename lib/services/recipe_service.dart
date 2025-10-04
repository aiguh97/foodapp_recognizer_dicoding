// lib/services/recipe_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class RecipeService {
  // Gunakan “1” sebagai API key test
  static const String _base = "https://www.themealdb.com/api/json/v1/1";

  Future<Map<String, dynamic>> fetchRecipeById(String id) async {
    final url = Uri.parse("$_base/lookup.php?i=$id");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] != null && (data['meals'] as List).isNotEmpty) {
        return data['meals'][0] as Map<String, dynamic>;
      } else {
        throw Exception("Recipe not found");
      }
    } else {
      throw Exception("Failed to load recipe (status ${response.statusCode})");
    }
  }

  /// Fetch recipe by Name (mengembalikan resep pertama yang cocok)
  Future<Map<String, dynamic>> fetchRecipeByName(String name) async {
    final url = Uri.parse("$_base/search.php?s=$name");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] != null && (data['meals'] as List).isNotEmpty) {
        return data['meals'][0] as Map<String, dynamic>;
      } else {
        throw Exception("Recipe not found for name '$name'");
      }
    } else {
      throw Exception("Failed to load recipe (status ${response.statusCode})");
    }
  }

  Future<List<Map<String, dynamic>>> searchRecipes(String query) async {
    final url = Uri.parse("$_base/search.php?s=$query");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] != null) {
        return (data['meals'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      } else {
        return []; // tidak ada resep
      }
    } else {
      throw Exception("Failed to search recipes");
    }
  }
}
