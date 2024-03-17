import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'model_manager.dart';
import 'package:flutter/rendering.dart';


class DrawingArea {
  Offset point;
  Paint areaPaint;

  DrawingArea({required this.point, required this.areaPaint});
}

class DrawingCanvas extends StatefulWidget {
  @override
  _DrawingCanvasState createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  List<DrawingArea> points = [];
  double brushSize = 5.0;
  double eraserSize = 5.0;
  bool isEraser = false;
  final GlobalKey _repaintKey = GlobalKey();
  final modelManager = ModelManager(); 

  @override
  void initState() {
    super.initState();
    modelManager.loadModel(); 
  }

  Future<void> captureCanvas() async {
    RenderRepaintBoundary boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

  // Call runInference and handle the results
    var inferenceResults = await modelManager.runInference(pngBytes);
    if (inferenceResults != null) {
      print("Top 3 Predictions:");
      for (int i = 0; i < 3; i++) {
        print("  - Index: ${inferenceResults[i]["index"]}, Confidence: ${inferenceResults[i]["confidence"]}");
      }
    } else {
      print("Error getting inference results.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Drawing Canvas'),
      ),
      body: Stack(
        children: [
          RepaintBoundary(
            key: _repaintKey,
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  points.add(DrawingArea(
                    point: details.localPosition,
                    areaPaint: Paint()
                      ..color = isEraser ? Colors.white : Colors.black
                      ..strokeWidth = isEraser ? eraserSize : brushSize
                      ..isAntiAlias = true
                      ..strokeCap = StrokeCap.round,
                  ));
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  points.add(DrawingArea(
                    point: details.localPosition,
                    areaPaint: Paint()
                      ..color = isEraser ? Colors.white : Colors.black
                      ..strokeWidth = isEraser ? eraserSize : brushSize
                      ..isAntiAlias = true
                      ..strokeCap = StrokeCap.round,
                  ));
                });
              },
              onPanEnd: (details) {
                setState(() {
                  points.add(DrawingArea(point: Offset.infinite, areaPaint: Paint()));
                });
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: DrawingPainter(points: points),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 10,
            child: Slider(
              min: 1.0,
              max: 10.0,
              value: isEraser ? eraserSize : brushSize,
              onChanged: (val) => setState(() => isEraser ? eraserSize = val : brushSize = val),
              label: "${isEraser ? eraserSize : brushSize}",
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: FloatingActionButton(
              onPressed: () => setState(() => isEraser = !isEraser),
              backgroundColor: isEraser ? Colors.blue : Colors.red,
              child: Icon(isEraser ? Icons.brush : Icons.delete),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: captureCanvas,
        label: const Text('GENERATE'),
        icon: const Icon(Icons.send),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingArea> points;

  DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].point != Offset.infinite && points[i + 1].point != Offset.infinite) {
        canvas.drawLine(points[i].point, points[i + 1].point, points[i].areaPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
