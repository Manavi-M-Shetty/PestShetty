import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes.dart';
import 'providers/language_provider.dart'; // ✅ import this

class PlantCareApp extends StatelessWidget {
  const PlantCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LanguageProvider(), // 🌍 make provider available globally
      child: MaterialApp(
        title: 'PlantCare',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          scaffoldBackgroundColor: const Color(0xFFF6F7F9),
          useMaterial3: true,
        ),
        initialRoute: Routes.home,
        routes: Routes.getRoutes(),
      ),
    );
  }
}
