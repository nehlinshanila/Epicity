import 'package:flutter/material.dart';
import 'canvas.dart'; 
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Drawing App',
      theme: ThemeData(
        // Adjusted to use a Material 3 color scheme
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 172, 136, 255)),
        useMaterial3: true,
      ),
      home: const DrawingPage(title: 'Epicity.Pen'),
    );
  }
}

class DrawingPage extends StatelessWidget {
  const DrawingPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: DrawingCanvas(), // The DrawingCanvas widget is used as the body of the Scaffold
    );
  }
}
