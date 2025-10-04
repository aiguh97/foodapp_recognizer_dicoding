import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class HomeProvider extends ChangeNotifier {
  File? selectedImage;
  final ImagePicker _picker = ImagePicker();

  File? get image => selectedImage;

  Future<void> pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        selectedImage = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Gagal memilih gambar: $e");
    }
  }

  // ✅ Tambahkan ini
  void setImage(File imageFile) {
    selectedImage = imageFile;
    notifyListeners();
  }

  void clearImage() {
    selectedImage = null;
    notifyListeners();
  }
}
