import 'dart:io';
import 'dart:isolate';
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class IsolateImageInference {
  static List<List<List<num>>> _imagePreProcessing(
    Image image,
    List<int> inputShape,
  ) {
    Image? img;
    img = image;

    Image imageInput = copyResize(
      img,
      width: inputShape[1],
      height: inputShape[2],
    );

    if (Platform.isAndroid) {
      imageInput = copyRotate(imageInput, angle: 0);
    }

    final imageMatrix = List.generate(
      imageInput.height,
      (y) => List.generate(imageInput.width, (x) {
        final pixel = imageInput.getPixel(x, y);
        return [pixel.r, pixel.g, pixel.b];
      }),
    );
    return imageMatrix;
  }

  static List<int> _runInference(
    List<List<List<List<num>>>> input,
    List<List<int>> output,
    int interpreterAddress,
  ) {
    Interpreter interpreter = Interpreter.fromAddress(interpreterAddress);
    interpreter.run(input, output);
    final result = output.first;
    return result;
  }

  static Future<Map<String, double>> runOnce(
    InferenceImageModel isolateModel,
  ) async {
    return await Isolate.run(() {
      final image = isolateModel.image!;
      final inputShape = isolateModel.inputShape;
      final imageMatrix = _imagePreProcessing(image, inputShape);

      final input = [imageMatrix];
      final output = [List<int>.filled(isolateModel.outputShape[1], 0)];
      final address = isolateModel.interpreterAddress;

      final result = _runInference(input, output, address);

      int maxScore = result.reduce((a, b) => a + b);
      final keys = isolateModel.labels;
      final values = result
          .map((e) => e.toDouble() / maxScore.toDouble())
          .toList();

      var classification = Map.fromIterables(keys, values);
      classification.removeWhere((key, value) => value < 0.5);

      return classification.cast<String, double>();
    });
  }
}

class InferenceImageModel {
  Image? image;
  int interpreterAddress;
  List<String> labels;
  List<int> inputShape;
  List<int> outputShape;
  late SendPort responsePort;

  InferenceImageModel(
    this.image,
    this.interpreterAddress,
    this.labels,
    this.inputShape,
    this.outputShape,
  );
}
