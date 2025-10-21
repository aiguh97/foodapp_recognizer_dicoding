import 'dart:convert';
import 'package:http/http.dart' as http;

class RecipeService {
  // Base API TheMealDB
  static const String _mealDbBase = "https://www.themealdb.com/api/json/v1/1";

  /// 🔹 Ambil 1 resep berdasarkan nama (TheMealDB)
  Future<Map<String, dynamic>> fetchRecipeByName(String name) async {
    // Hilangkan spasi atau karakter newline di awal/akhir
    final cleanedName = name.trim();

    final mealUrl = Uri.parse("$_mealDbBase/search.php?s=$cleanedName");
    final mealResponse = await http.get(mealUrl);

    if (mealResponse.statusCode == 200) {
      final data = json.decode(mealResponse.body);

      if (data['meals'] != null && (data['meals'] as List).isNotEmpty) {
        return data['meals'][0] as Map<String, dynamic>;
      }
    }

    throw Exception(
      "❌ Tidak ditemukan data makanan untuk '$cleanedName' ($mealUrl)",
    );
  }

  /// 🔹 Cari banyak resep berdasarkan query (TheMealDB)
  Future<List<Map<String, dynamic>>> searchRecipes(String query) async {
    final cleanedQuery = query.trim();

    final mealUrl = Uri.parse("$_mealDbBase/search.php?s=$cleanedQuery");
    final mealResponse = await http.get(mealUrl);

    if (mealResponse.statusCode == 200) {
      final data = json.decode(mealResponse.body);

      if (data['meals'] != null && (data['meals'] as List).isNotEmpty) {
        return (data['meals'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
    }

    return [];
  }
}
