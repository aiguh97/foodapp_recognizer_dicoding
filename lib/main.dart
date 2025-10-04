import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:foodapp_recognizer/firebase_options.dart';
import 'package:foodapp_recognizer/provider/home_provider.dart';
import 'package:foodapp_recognizer/screens/food_notfound.dart';
import 'package:foodapp_recognizer/screens/home_screen.dart';
import 'package:foodapp_recognizer/screens/recipe_detail_screen.dart';
import 'package:foodapp_recognizer/screens/result_screen.dart';
import 'package:foodapp_recognizer/services/firebase_ml_service.dart';
import 'package:foodapp_recognizer/services/lite_rt_service.dart';
import 'package:foodapp_recognizer/services/recipe_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const RecipeApp());
}

class RecipeApp extends StatelessWidget {
  const RecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        Provider(create: (_) => RecipeService()),
        Provider(create: (_) => FirebaseMlService()),
        ChangeNotifierProvider(
          create: (context) =>
              LiteRtService(context.read<FirebaseMlService>())..initModel(),
        ),
      ],
      child: MaterialApp(
        title: 'Recipe UI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          primarySwatch: Colors.green,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            elevation: 0,
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
            bodySmall: TextStyle(fontSize: 12, color: Colors.grey),
            titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        // ✅ Langsung ke HomeScreen
        home: const HomeScreen(),
        // home: const HomePage(),
        // home: const FoodNotFound(),
      ),
    );
  }
}
