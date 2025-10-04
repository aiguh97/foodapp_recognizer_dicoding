import 'package:flutter/material.dart';
import 'package:foodapp_recognizer/provider/home_provider.dart';
import 'package:foodapp_recognizer/screens/food_notfound.dart';
import 'package:foodapp_recognizer/screens/result_screen.dart';
import 'package:foodapp_recognizer/services/recipe_service.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';

// import '../provider/home_provider.dart';
import '../services/lite_rt_service.dart';
import '../screens/recipe_detail_screen.dart';

const Color kPrimaryColor = Colors.green;
const double kHorizontalPadding = 16.0;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
      // aspectRatioPresets: [
      //   CropAspectRatioPreset.square,
      //   CropAspectRatioPreset.ratio4x3,
      //   CropAspectRatioPreset.original,
      // ],
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
    final liteRtService = context.read<LiteRtService>();
    final homeProvider = context.read<HomeProvider>();
    final File? image = homeProvider.image;

    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first.')),
      );
      return;
    }

    if (!liteRtService.isReady) {
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
      final result = await liteRtService.predict(image);

      final String label = result['label'] as String;
      final double confidence = result['confidence'] as double;

      if (!context.mounted) return;
      Navigator.pop(context);

      // 💡 TAMBAH FILTER UNTUK __BACKGROUND__
      if (label.trim().toLowerCase() == "__background__") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const FoodNotFound(
              label: "Object detected, but not a recognized food item.",
            ),
          ),
        );
        return; // Hentikan proses jika background
      }
      // -----------------------------------------------------------------

      if (confidence > 0.5) {
        try {
          // ... (sisa logika pencarian resep dan navigasi)
          final recipe = await context.read<RecipeService>().fetchRecipeByName(
            label.trim(),
          );

          if (recipe != null) {
            // ... (Navigasi ke RecipeDetailScreen)
          } else {
            // ... (Navigasi ke FoodNotFound)
          }
        } catch (e) {
          // ... (Logika navigasi ResultScreen/FoodNotFound jika pencarian resep gagal)
        }
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FoodNotFound(label: label)),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(
        context,
      ); // tutup dialog / halaman sebelumnya (biasanya loading)
      print("skkfjskjskfjs $e"); // debug print error

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              FoodNotFound(label: e.toString()), // tampilkan halaman error
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isModelReady = context.watch<LiteRtService>().isReady;
    final image = context.watch<HomeProvider>().image;

    return Scaffold(
      appBar: AppBar(title: const Text("Food Recognizer"), elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kHorizontalPadding,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            image,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: (image == null || !isModelReady)
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 9),

                  ElevatedButton(
                    onPressed: (image == null || !isModelReady)
                        ? null
                        : () async {
                            final cropped = await _cropImage(image!);
                            if (cropped != null) {
                              // update ke provider biar image diganti hasil crop
                              context.read<HomeProvider>().setImage(cropped);
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (!isModelReady)
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
