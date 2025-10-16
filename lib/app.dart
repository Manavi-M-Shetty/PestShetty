import 'package:flutter/material.dart';
import 'routes.dart';


class PlantCareApp extends StatelessWidget {
const PlantCareApp({super.key});


@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'PlantCare',
debugShowCheckedModeBanner: false,
theme: ThemeData(
primarySwatch: Colors.green,
scaffoldBackgroundColor: const Color(0xFFF6F7F9),
useMaterial3: true,
),
initialRoute: Routes.home,
routes: Routes.getRoutes(),
);
}
}