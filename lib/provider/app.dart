import 'package:flutter/foundation.dart';
import 'package:foodapp_recognizer/services/firebase_ml_service.dart';
import 'package:foodapp_recognizer/services/image_classification_service.dart';
import 'package:foodapp_recognizer/services/recipe_service.dart';

class AppInitializer extends ChangeNotifier {
  bool isReady = false;
  bool isLoading = true;
  String? error;

  // late FirebaseMlService firebaseMlService;
  late ImageClassificationService imageClassificationService;
  late RecipeService recipeService;

  AppInitializer() {
    _init();
  }

  Future<void> _init() async {
    try {
      // ✅ 1. Inisialisasi Firebase (jika diperlukan)
      // await FirebaseMlService.initFirebaseIfNeeded();

      // // ✅ 2. Buat instance service
      // firebaseMlService = FirebaseMlService();
      recipeService = RecipeService();
      imageClassificationService = ImageClassificationService();

      // ✅ 3. Load model + labels di background
      await imageClassificationService.initHelper();

      // ✅ 4. Tandai siap digunakan
      isReady = true;
    } catch (e, st) {
      error = e.toString();
      if (kDebugMode) {
        print("❌ Gagal inisialisasi AppInitializer: $e\n$st");
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
