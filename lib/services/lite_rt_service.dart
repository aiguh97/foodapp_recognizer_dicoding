import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle; // 💡 TAMBAH INI
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:foodapp_recognizer/services/firebase_ml_service.dart';

class LiteRtService extends ChangeNotifier {
  final FirebaseMlService _mlService;

  LiteRtService(this._mlService);

  File? modelFile;
  Interpreter? interpreter;
  bool isReady = false;

  // 1. 💡 Hapus inisialisasi hardcoded. Biarkan kosong.
  List<String> labels = [];

  Future<void> _loadLabels() async {
    final labelContent = await rootBundle.loadString(
      'assets/probability-labels.txt',
    );
    labels = labelContent
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (labels.isEmpty) {
      throw Exception("Label file kosong atau gagal dimuat.");
    }

    log("✅ Label berhasil dimuat: ${labels.length} kelas");
  }

  Future<void> initModel() async {
    await _loadLabels();

    log("🔄 Load model...");
    modelFile = await _mlService.loadModel();
    if (modelFile == null || !modelFile!.existsSync()) {
      throw Exception("Model file tidak ditemukan");
    }

    final options = InterpreterOptions()
      ..useNnApiForAndroid = true
      ..useMetalDelegateForIOS = true;

    interpreter = Interpreter.fromFile(modelFile!, options: options);

    final numClassesModel = interpreter!.getOutputTensors().first.shape.last;
    log(
      "📊 Jumlah kelas model: $numClassesModel, Label file: ${labels.length}",
    );

    if (numClassesModel != labels.length) {
      throw Exception(
        "❌ Jumlah output model ($numClassesModel) ≠ label (${labels.length})",
      );
    }

    isReady = true;
    notifyListeners();
  }

  /// Fungsi predict yang mengembalikan label string + confidence
  Future<Map<String, dynamic>> predict(File imageFile) async {
    if (!isReady || interpreter == null) {
      throw Exception("❌ Model belum siap. Pastikan initModel() selesai.");
    }

    if (labels.isEmpty) {
      throw Exception("❌ Daftar label kosong. Gagal memuat label.");
    }

    final inputShape = interpreter!.getInputTensors().first.shape;
    final outputTensor = interpreter!.getOutputTensors().first;

    // 💡 TAMBAHKAN KODE INI UNTUK MENDAPATKAN DIMENSI INPUT
    final int inputHeight = inputShape[1];
    final int inputWidth = inputShape[2];
    final int inputChannels = inputShape[3];
    final int numClasses = outputTensor.shape.last;
    // --------------------------------------------------------

    if (numClasses != labels.length) {
      throw Exception(
        "❌ Jumlah output model ($numClasses) tidak sesuai dengan jumlah label (${labels.length}).",
      );
    }

    // 🔹 Load dan decode image
    final rawBytes = await imageFile.readAsBytes();
    final rawImage = img.decodeImage(rawBytes);
    if (rawImage == null) throw Exception("❌ Gagal membaca image");

    final resized = img.copyResize(
      rawImage,
      width: inputWidth,
      height: inputHeight,
    );

    // ... (kode pembentukan Uint8List input, yang sudah benar) ...
    final input = Uint8List(1 * inputHeight * inputWidth * inputChannels);
    // ... (loop pengisian input) ...

    // 🔹 SOLUSI: Buat buffer output sebagai List<List<int>>
    // Ini adalah struktur List<List<T>> yang paling stabil dan umum diterima oleh tflite_flutter.
    final output = List.generate(1, (_) => List<int>.filled(numClasses, 0));

    // 🔹 Jalankan inference
    // Input (Uint8List) perlu di-reshape ke [1, H, W, C]
    // Output (List<List<int>>) akan menerima hasil
    interpreter!.run(input.reshape(inputShape), output);

    // 🔹 Ambil hasil dan Normalisasi Output
    // Ambil baris pertama (index 0) dari List<List<int>>
    final outputValues = output[0];

    // Output uint8 harus dinormalisasi kembali ke 0.0-1.0 untuk mendapatkan probabilitas
    final results = outputValues.map((e) => e / 255.0).toList();

    // ... (Sisa kode untuk mencari maxProb, maxIndex, dan return) ...
    double maxProb = 0;
    int maxIndex = 0;
    for (int i = 0; i < results.length; i++) {
      if (results[i] > maxProb) {
        maxProb = results[i];
        maxIndex = i;
      }
    }

    final label = labels[maxIndex];
    log("📊 Prediksi: $label (${(maxProb * 100).toStringAsFixed(1)}%)");

    return {"label": label, "confidence": maxProb};
  }

  void close() {
    try {
      interpreter?.close();
      interpreter = null;
      isReady = false;
      log("🔒 Interpreter ditutup");
    } catch (e) {
      log("⚠️ Gagal menutup interpreter: $e");
    }
    notifyListeners();
  }
}
