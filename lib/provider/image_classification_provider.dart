import 'package:flutter/widgets.dart' hide Image;
import 'package:foodapp_recognizer/services/image_classification_service.dart';
import 'package:image/image.dart' as img;
// import 'package:submission/services/image_classification_service.dart';

class ImageClassificationViewmodel extends ChangeNotifier {
  final ImageClassificationService _service;

  Map<String, num> _classifications = {};
  bool _isClassificationRan = false;

  ImageClassificationViewmodel(this._service) {
    _service.initHelper();
  }

  bool get isClassificationRan => _isClassificationRan;

  Map<String, num> get classification => Map.fromEntries(
    (_classifications.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value)))
        .reversed
        .take(1),
  );

  Future<void> runImageClassification(img.Image image) async {
    final resized = img.copyResize(
      image,
      width: 224,
      height: 224,
      interpolation: img.Interpolation.linear,
    );

    resized.getBytes().map((px) => px / 255.0);

    _isClassificationRan = true;
    _classifications = await _service.inferenceSingleImage(image);
    notifyListeners();
  }

  Future<void> close() async {
    _isClassificationRan = false;
    _classifications.clear();
    await _service.close();
  }
}
