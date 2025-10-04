import 'dart:convert';
import 'package:http/http.dart' as http;

class RecipeService {
  // Base API TheMealDB
  static const String _mealDbBase = "https://www.themealdb.com/api/json/v1/1";

  // Base API USDA
  static const String _usdaBase =
      "https://api.nal.usda.gov/fdc/v1/foods/search";
  static const String _usdaApiKey =
      "JAWCwYvW34LY9g1ZABD3qEVde8ruDt4yrBuXaQbt"; // 🔑 USDA API key

  /// 🔹 Fetch food data by name (TheMealDB dulu, kalau kosong → USDA)
  Future<Map<String, dynamic>> fetchRecipeByName(String name) async {
    // 1️⃣ Coba TheMealDB
    final mealUrl = Uri.parse("$_mealDbBase/search.php?s=$name");
    final mealResponse = await http.get(mealUrl);

    if (mealResponse.statusCode == 200) {
      final data = json.decode(mealResponse.body);
      if (data['meals'] != null && (data['meals'] as List).isNotEmpty) {
        return data['meals'][0] as Map<String, dynamic>;
      }
    }

    // 2️⃣ Kalau tidak ada, fallback ke USDA
    final usdaUrl = Uri.parse("$_usdaBase?api_key=$_usdaApiKey&query=$name");
    final usdaResponse = await http.get(usdaUrl);

    if (usdaResponse.statusCode == 200) {
      final data = json.decode(usdaResponse.body);

      if (data['foods'] != null && (data['foods'] as List).isNotEmpty) {
        final firstFood = data['foods'][0] as Map<String, dynamic>;

        return {
          "idMeal": firstFood["fdcId"].toString(),
          "strMeal": firstFood["description"],
          "strMealThumb":
              "https://cdn-icons-png.flaticon.com/512/857/857681.png",
          "strInstructions":
              "Data dari USDA.\nBrand: ${firstFood["brandOwner"] ?? "Unknown"}\nType: ${firstFood["dataType"] ?? "N/A"}",
          "foodNutrients": firstFood["foodNutrients"] ?? [],
        };
      }
    }

    throw Exception("❌ Tidak ditemukan data makanan untuk '$name'");
  }

  /// 🔹 Search multiple food items (TheMealDB dulu, lalu USDA fallback)
  Future<List<Map<String, dynamic>>> searchRecipes(String query) async {
    // 1️⃣ Coba TheMealDB
    final mealUrl = Uri.parse("$_mealDbBase/search.php?s=$query");
    final mealResponse = await http.get(mealUrl);

    if (mealResponse.statusCode == 200) {
      final data = json.decode(mealResponse.body);
      if (data['meals'] != null && (data['meals'] as List).isNotEmpty) {
        return (data['meals'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
    }

    // 2️⃣ Kalau tidak ada, coba USDA
    final usdaUrl = Uri.parse("$_usdaBase?api_key=$_usdaApiKey&query=$query");
    final usdaResponse = await http.get(usdaUrl);

    if (usdaResponse.statusCode == 200) {
      final data = json.decode(usdaResponse.body);

      if (data['foods'] != null && (data['foods'] as List).isNotEmpty) {
        return (data['foods'] as List)
            .map(
              (e) => {
                "idMeal": e["fdcId"].toString(),
                "strMeal": e["description"],
                "strMealThumb":
                    "https://cdn-icons-png.flaticon.com/512/857/857681.png",
                "strInstructions":
                    "Data dari USDA.\nBrand: ${e["brandOwner"] ?? "Unknown"}\nType: ${e["dataType"] ?? "N/A"}",
                "foodNutrients": e["foodNutrients"] ?? [],
              },
            )
            .toList();
      }
    }

    return [];
  }
}
