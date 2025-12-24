import 'package:eagles/pages/HomePage.dart';
import 'package:eagles/pages/home_binding.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

//Hossein Abdollahi
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'APK Av',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      initialBinding: HomeBinding(),
      home: const HomePage(),
    );
  }
}
