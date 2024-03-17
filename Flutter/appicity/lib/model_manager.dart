import 'dart:typed_data';
import 'dart:async';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ModelManager {
  Interpreter? _interpreter;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('/model.tflite');
      print('Model loaded successfully.');
    } catch (e) {
      print('Failed to load model: $e');
    }
  }

  Future<Uint8List> preprocessImage(Uint8List imageData) async {
    // Decoding the image to a format that can be resized and converted
    img.Image? originalImg = img.decodeImage(imageData);
    if (originalImg == null) {
      throw Exception('Unable to decode image');
    }

    // Resize the image to 224x224
    img.Image resizedImg = img.copyResize(originalImg, width: 224, height: 224);
    
    // Convert the image to a normalized Float32List for input into the TFLite model
    Float32List floatList = Float32List(1 * 224 * 224 * 3);
    var buffer = Float32List.view(floatList.buffer);
    int pixelIndex = 0;
    for (var y = 0; y < 224; y++) {
      for (var x = 0; x < 224; x++) {
        var pixel = resizedImg.getPixel(x, y);
        buffer[pixelIndex++] = (img.getRed(pixel) / 255.0);
        buffer[pixelIndex++] = (img.getGreen(pixel) / 255.0);
        buffer[pixelIndex++] = (img.getBlue(pixel) / 255.0);
      }
    }
    return floatList.buffer.asUint8List();
  }

  Future<List<Map<String, dynamic>>?> runInference(Uint8List inputData) async {
    if (_interpreter == null) {
      print('Interpreter not initialized.');
      return null;
    }

    try {
      Uint8List preprocessedData = await preprocessImage(inputData);

      // Create a buffer for the model's outputs
      var outputBuffer = List.filled(1 * 1000, 0.0).reshape([1, 1000]); // Adjust based on your model's output shape
      _interpreter!.run(preprocessedData, outputBuffer);

      // Postprocess to get top results
      var results = postProcessPredictions(outputBuffer[0]);
      return results;
    } catch (e) {
      print('Error running model inference: $e');
      return null;
    }
  }

  List<Map<String, dynamic>> postProcessPredictions(List<dynamic> predictions) {
    List<Map<String, dynamic>> results = [];

    for (int i = 0; i < predictions.length; i++) {
      results.add({"index": i, "confidence": predictions[i]});
    }

    // Sort the results based on confidence
    results.sort((a, b) => b["confidence"].compareTo(a["confidence"]));

    // Return the top 3 predictions
    return results.take(3).toList();
  }
}
