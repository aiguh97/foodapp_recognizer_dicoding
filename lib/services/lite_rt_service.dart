import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:foodapp_recognizer/services/firebase_ml_service.dart';

class LiteRtService extends ChangeNotifier {
  final FirebaseMlService _mlService;

  LiteRtService(this._mlService);

  File? modelFile;
  Interpreter? interpreter;
  bool isReady = false;

  final List<String> labels = [
    "Nasi Goreng",
    "Mie Goreng",
    "Sate Ayam",
    // tambahkan semua kelas sesuai model
  ];

  Future<void> initModel() async {
    try {
      log("🔄 Mulai load model dari Firebase...");
      modelFile = await _mlService.loadModel();

      if (modelFile == null || !modelFile!.existsSync()) {
        throw Exception("Model file tidak ditemukan / corrupt");
      }
      log("📂 Model berhasil diunduh: ${modelFile!.path}");

      final options = InterpreterOptions()
        ..useNnApiForAndroid = true
        ..useMetalDelegateForIOS = true;

      interpreter = Interpreter.fromFile(modelFile!, options: options);

      final inputTensors = interpreter!.getInputTensors();
      final outputTensors = interpreter!.getOutputTensors();
      log(
        "✅ Interpreter siap, Input: ${inputTensors.map((e) => e.shape).toList()}, "
        "Output: ${outputTensors.map((e) => e.shape).toList()}",
      );

      isReady = true;
      notifyListeners();
    } catch (e, st) {
      log("❌ Error loading model: $e", stackTrace: st);
      isReady = false;
      notifyListeners();
    }
  }

  /// Fungsi predict yang mengembalikan label string + confidence
  Future<Map<String, dynamic>> predict(File imageFile) async {
    if (!isReady || interpreter == null) {
      throw Exception("❌ Model belum siap. Pastikan initModel() selesai.");
    }

    // Ambil tensor shape
    final inputShape = interpreter!.getInputTensors().first.shape;
    final outputShape = interpreter!.getOutputTensors().first.shape;

    final int inputHeight = inputShape[1];
    final int inputWidth = inputShape[2];
    final int inputChannels = inputShape[3];
    final int numClasses = outputShape.last;

    // Load dan decode image
    final rawBytes = await imageFile.readAsBytes();
    final rawImage = img.decodeImage(rawBytes);
    if (rawImage == null) throw Exception("❌ Gagal membaca image");

    // Resize sesuai input model
    // final resized = img.copyResize(
    //   rawImage,
    //   width: inputWidth,
    //   height: inputHeight,
    // );
    final resized = img.copyResize(
      rawImage,
      width: inputWidth,
      height: inputHeight,
    );

    // Buat Float32List input
    final input = Float32List(1 * inputHeight * inputWidth * inputChannels);

    int pixelIndex = 0;
    // int pixelIndex = 0;
    for (var y = 0; y < inputHeight; y++) {
      for (var x = 0; x < inputWidth; x++) {
        final pixel = resized.getPixel(x, y);

        // Dapatkan RGB dari Pixel object
        final r = pixel.r / 255.0;
        final g = pixel.g / 255.0;
        final b = pixel.b / 255.0;

        input[pixelIndex++] = r;
        input[pixelIndex++] = g;
        input[pixelIndex++] = b;
      }
    }

    // Buat output tensor
    final output = List.filled(numClasses, 0.0).reshape([1, numClasses]);

    // Run inference
    interpreter!.run(input.reshape(inputShape), output);

    // Ambil hasil terbaik
    final results = (output[0] as List).cast<double>();
    double maxProb = 0;
    int maxIndex = 0;
    for (int i = 0; i < results.length; i++) {
      if (results[i] > maxProb) {
        maxProb = results[i];
        maxIndex = i;
      }
    }

    final label = (maxIndex < labels.length) ? labels[maxIndex] : "Unknown";

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
