import 'package:flutter/services.dart';
import 'package:foodapp_recognizer/services/image_isolate_inference.dart';
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ImageClassificationService {
  final modelPath = 'assets/aiy.tflite';
  final labelsPath = 'assets/labels.txt';

  late final Interpreter interpreter;
  late final List<String> labels;
  late Tensor inputTensor;
  late Tensor outputTensor;

  Future<void> _loadModel() async {
    final options = InterpreterOptions()
      ..useNnApiForAndroid = true
      ..useMetalDelegateForIOS = true;

    interpreter = await Interpreter.fromAsset(modelPath, options: options);
    inputTensor = interpreter.getInputTensors().first;
    outputTensor = interpreter.getOutputTensors().first;
  }

  Future<void> _loadLabels() async {
    final labelTxt = await rootBundle.loadString(labelsPath);

    RegExp regex = RegExp(r',([^\n]+)');
    Iterable<RegExpMatch> matches = regex.allMatches(labelTxt);
    labels = matches.map((m) => m.group(1)!).toList();
  }

  Future<void> initHelper() async {
    _loadModel();
    _loadLabels();
  }

  Future<Map<String, double>> inferenceSingleImage(Image image) async {
    var isolateModel = InferenceImageModel(
      image,
      interpreter.address,
      labels,
      inputTensor.shape,
      outputTensor.shape,
    );

    final result = await IsolateImageInference.runOnce(isolateModel);
    return result;
  }

  Future<void> close() async {}
}
