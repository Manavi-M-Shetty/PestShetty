// lib/services/tflite_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class Prediction {
  final String label;
  final double confidence;
  Prediction(this.label, this.confidence);
}

class TFLiteService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isQuantized = false;

  // Model input info
  int inputHeight = 0;
  int inputWidth = 0;
  int inputChannels = 3;
  // input tensor type is represented by TensorType from tflite_flutter

  // Helpers to extract R,G,B channels from a pixel value returned by the
  // image package. Depending on package version the pixel may be an int
  // (ARGB) or an object with r/g/b properties.
  int _pixelR(dynamic pixel) {
    if (pixel is int) return (pixel >> 16) & 0xFF;
    try {
      return (pixel as img.Pixel).r.toInt();
    } catch (_) {
      return 0;
    }
  }

  int _pixelG(dynamic pixel) {
    if (pixel is int) return (pixel >> 8) & 0xFF;
    try {
      return (pixel as img.Pixel).g.toInt();
    } catch (_) {
      return 0;
    }
  }

  int _pixelB(dynamic pixel) {
    if (pixel is int) return pixel & 0xFF;
    try {
      return (pixel as img.Pixel).b.toInt();
    } catch (_) {
      return 0;
    }
  }

  /// Load model and labels
  Future<void> loadModel({
    String modelPath = "assets/models/model_quant.tflite",
    String labelsPath = "assets/models/labels.txt",
  }) async {
    // Load interpreter
    _interpreter = await Interpreter.fromAsset(modelPath);

    // Load labels
    try {
      final rawLabels = await rootBundle.loadString(labelsPath);
      _labels = rawLabels
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      _labels = [];
    }

    // Inspect input tensor
    final inputTensor = _interpreter!.getInputTensors()[0];
    final shape = inputTensor.shape;
    if (shape.length == 4) {
      inputHeight = shape[1];
      inputWidth = shape[2];
      inputChannels = shape[3];
    } else if (shape.length == 3) {
      inputHeight = shape[0];
      inputWidth = shape[1];
      inputChannels = shape[2];
    } else {
      throw Exception("Unsupported input tensor shape: $shape");
    }

    final tensorType = inputTensor.type;
    _isQuantized = (tensorType == TensorType.uint8);
  }

  /// Preprocess image manually
  /// Returns either a [Uint8List] (quantized) or a [Float32List] (float model)
  Object _preprocessImage(img.Image image) {
    // Resize
    final resized = img.copyResize(image, width: inputWidth, height: inputHeight);

    if (_isQuantized) {
      // Uint8List for quantized models
      final buffer = Uint8List(inputHeight * inputWidth * inputChannels);
      int idx = 0;
      for (int y = 0; y < inputHeight; y++) {
        for (int x = 0; x < inputWidth; x++) {
          final pixel = resized.getPixel(x, y);
          final r = _pixelR(pixel);
          final g = _pixelG(pixel);
          final b = _pixelB(pixel);
          buffer[idx++] = r;
          buffer[idx++] = g;
          buffer[idx++] = b;
        }
      }
      return buffer;
    } else {
      // Float32List for float models (normalized 0..1)
      final buffer = Float32List(inputHeight * inputWidth * inputChannels);
      int idx = 0;
      for (int y = 0; y < inputHeight; y++) {
        for (int x = 0; x < inputWidth; x++) {
          final pixel = resized.getPixel(x, y);
          buffer[idx++] = _pixelR(pixel) / 255.0;
          buffer[idx++] = _pixelG(pixel) / 255.0;
          buffer[idx++] = _pixelB(pixel) / 255.0;
        }
      }
      return buffer;
    }
  }

  /// Run inference on a File image
  Future<Prediction?> predict(File imageFile) async {
    if (_interpreter == null) throw Exception("Interpreter not initialized");

    final bytes = await imageFile.readAsBytes();
    final oriImage = img.decodeImage(bytes);
    if (oriImage == null) return null;

  final inputBuffer = _preprocessImage(oriImage);

    // Prepare output
    final outputTensor = _interpreter!.getOutputTensors()[0];
    final outputShape = outputTensor.shape;
    final outputLen = outputShape.reduce((a, b) => a * b);

    List<double> scores = List.filled(outputLen, 0.0);

    if (outputTensor.type == TensorType.float32) {
      final output = List.filled(outputLen, 0.0).cast<double>();
      _interpreter!.run(inputBuffer, output);
      scores = output;
    } else if (outputTensor.type == TensorType.uint8) {
      final output = Uint8List(outputLen);
      _interpreter!.run(inputBuffer, output);
      for (int i = 0; i < outputLen; i++) {
        scores[i] = output[i] / 255.0;
      }
    } else {
      throw Exception("Unsupported output type: ${outputTensor.type}");
    }

    // Get top prediction
    int maxIdx = 0;
    double maxScore = scores[0];
    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        maxIdx = i;
      }
    }

    final label = (_labels.isNotEmpty && maxIdx < _labels.length)
        ? _labels[maxIdx]
        : 'Label #$maxIdx';

    return Prediction(label, maxScore.clamp(0.0, 1.0));
  }

  void close() {
    _interpreter?.close();
    _interpreter = null;
  }
}
