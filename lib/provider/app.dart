import 'package:flutter/foundation.dart';
import 'package:foodapp_recognizer/services/firebase_ml_service.dart';
import 'package:foodapp_recognizer/services/lite_rt_service.dart';
import 'package:foodapp_recognizer/services/recipe_service.dart';

class AppInitializer extends ChangeNotifier {
  bool isReady = false;
  bool isLoading = true;
  String? error;

  late FirebaseMlService firebaseMlService;
  late LiteRtService liteRtService;
  late RecipeService recipeService;

  AppInitializer() {
    _init();
  }

  Future<void> _init() async {
    try {
      await FirebaseMlService.initFirebaseIfNeeded();
      firebaseMlService = FirebaseMlService();
      recipeService = RecipeService();
      liteRtService = LiteRtService(firebaseMlService);
      await liteRtService.initModel();

      isReady = true;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
