import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:foodapp_recognizer/provider/home_provider.dart';
import 'package:foodapp_recognizer/screens/food_notfound.dart';
import 'package:foodapp_recognizer/screens/result_screen.dart';
import 'package:foodapp_recognizer/services/image_classification_service.dart';
import 'package:foodapp_recognizer/services/recipe_service.dart';

const Color kPrimaryColor = Colors.green;
const double kHorizontalPadding = 16.0;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ImageClassificationService _classifier;

  @override
  void initState() {
    super.initState();
    _classifier = ImageClassificationService();
    _initModel();
  }

  Future<void> _initModel() async {
    try {
      await _classifier.initHelper();
      context.read<HomeProvider>().setModelReady(true);
    } catch (e) {
      debugPrint("❌ Gagal inisialisasi model: $e");
    }
  }

  void _showPicker(BuildContext context) {
    final homeProvider = context.read<HomeProvider>();

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera, color: kPrimaryColor),
              title: const Text("Take Photo"),
              onTap: () {
                Navigator.pop(ctx);
                homeProvider.pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: kPrimaryColor),
              title: const Text("Gallery"),
              onTap: () {
                Navigator.pop(ctx);
                homeProvider.pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<File?> _cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.green,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: Colors.green,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop Image'),
      ],
    );
    if (croppedFile == null) return null;
    return File(croppedFile.path);
  }

  Future<void> _analyzeImage(BuildContext context) async {
    final homeProvider = context.read<HomeProvider>();
    final imageFile = homeProvider.image;

    if (imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first.')),
      );
      return;
    }

    if (!homeProvider.modelReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ML Model is still loading...')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: kPrimaryColor)),
    );

    try {
      final rawBytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) throw Exception("❌ Failed to decode image.");

      final result = await _classifier.inferenceSingleImage(decoded);

      Navigator.pop(context); // Tutup dialog

      if (result.isEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const FoodNotFound(label: "No recognizable food found."),
          ),
        );
        return;
      }

      // Ambil label & confidence tertinggi
      final bestEntry = result.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      final label = bestEntry.key;
      final confidence = bestEntry.value;

      // 🔍 Ambil detail dari USDA API
      final recipeService = context.read<RecipeService>();
      try {
        await recipeService.fetchRecipeByName(label);

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              label: label,
              confidence: confidence,
              imageFile: homeProvider.image!,
            ),
          ),
        );
      } catch (_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FoodNotFound(label: label)),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      debugPrint("❌ Error analyze image: $e");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FoodNotFound(label: e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final image = homeProvider.image;
    final modelReady = homeProvider.modelReady;

    return Scaffold(
      appBar: AppBar(title: const Text("Food Recognizer"), elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kHorizontalPadding,
            vertical: 20,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _showPicker(context),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                  ),
                  child: image == null
                      ? const Center(
                          child: Text(
                            "Tap to select an image",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                image,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => homeProvider.clearImage(),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: const Icon(
                                    Icons.delete_forever_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: (image == null || !modelReady)
                    ? null
                    : () => _analyzeImage(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  "ANALYZE RECIPE",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: (image == null || !modelReady)
                    ? null
                    : () async {
                        final cropped = await _cropImage(image!);
                        if (cropped != null) {
                          homeProvider.setImage(cropped);
                          await _analyzeImage(context);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 55,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  "Crop & Analyze",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (!modelReady)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(
                    child: Text(
                      'Loading ML model... Please wait.',
                      style: TextStyle(color: kPrimaryColor),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
