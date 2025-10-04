import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';

class FirebaseMlService {
  static bool _isInitialized = false;

  /// 🔹 Pastikan Firebase sudah ready (hanya sekali)
  static Future<void> initFirebaseIfNeeded() async {
    if (!_isInitialized) {
      await Firebase.initializeApp();
      _isInitialized = true;
    }
  }

  /// 🔹 Load model dari Firebase ML
  Future<File> loadModel() async {
    final instance = FirebaseModelDownloader.instance;
    final model = await instance.getModel(
      "food_classifier",
      FirebaseModelDownloadType.latestModel,
      FirebaseModelDownloadConditions(
        androidWifiRequired: false,
        androidChargingRequired: false,
        androidDeviceIdleRequired: false,
      ),
    );

    return model.file;
  }
}
