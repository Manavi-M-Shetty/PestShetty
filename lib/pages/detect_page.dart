// lib/pages/detect_page_with_tflite.dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
// Simple local stub of TFLiteService to avoid missing-package compile error.
// In your production app replace this with the real implementation that
// loads and runs your TensorFlow Lite model (for example using tflite_flutter
// or tflite plugin).
//
// The stub provides:
// - loadModel({modelPath, labelsPath})
// - Future<Prediction?> predict(File image)
// - void close()
//
// Prediction contains label and confidence.
class Prediction {
  final String label;
  final double confidence;

  Prediction({required this.label, required this.confidence});
}

class TFLiteService {
  List<String> _labels = [];

  Future<void> loadModel({required String modelPath, String? labelsPath}) async {
    // No-op stub: in a real implementation load the TFLite model and labels here.
    // If a labelsPath is provided you may load them from assets.
    try {
      if (labelsPath != null) {
        // attempt to read labels from asset bundle if available
        final raw = await rootBundle.loadString(labelsPath);
        _labels = raw.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
    } catch (_) {
      // ignore: keep stub resilient
      _labels = [];
    }
  }

  Future<Prediction?> predict(File image) async {
    // Very small heuristic stub: return a fake prediction based on image bytes.
    try {
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) return null;
      // Simple pseudo-confidence from byte sum
      final sum = bytes.fold<int>(0, (p, e) => p + e);
      final confidence = ((sum % 100) / 100.0).clamp(0.0, 1.0);
      final label = _labels.isNotEmpty ? _labels[sum % _labels.length] : 'unknown';
      return Prediction(label: label, confidence: confidence);
    } catch (_) {
      return null;
    }
  }

  void close() {
    // no resources in stub
  }
}

/// DetectPage with TFLite integration
class DetectPage extends StatefulWidget {
  const DetectPage({super.key});

  @override
  State<DetectPage> createState() => _DetectPageState();
}

class _DetectPageState extends State<DetectPage> with SingleTickerProviderStateMixin {
  File? _image;
  String _label = '';
  double _confidence = 0.0;
  final ImagePicker _picker = ImagePicker();
  bool _isDetecting = false;

  // Animation controller for glowing detect button
  late final AnimationController _pulseController;

  // TFLite service instance
  final _tfliteService = TFLiteService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);

    // Load the model (fire-and-forget). Errors will be logged and shown if mounted.
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      await _tfliteService.loadModel(
        modelPath: 'assets/models/model_quant.tflite',
        labelsPath: 'assets/models/labels.txt', // optional
      );
      if (mounted) {
        // optional debug:
        // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Model loaded')));
      }
    } catch (e) {
      // Log error and show SnackBar only if still mounted
      debugPrint('Failed to load model: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Model load failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tfliteService.close();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (file == null) return;
      if (!mounted) return;
      setState(() {
        _image = File(file.path);
        _label = '';
        _confidence = 0.0;
      });
    } catch (e) {
      debugPrint('Failed to pick image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _runDetection() async {
    if (_image == null) return;

    // disable button
    if (!mounted) return;
    setState(() => _isDetecting = true);

    try {
      final pred = await _tfliteService.predict(_image!);
      if (!mounted) return;

      if (pred != null) {
        setState(() {
          _label = pred.label;
          _confidence = pred.confidence;
          _isDetecting = false;
        });

        _showResultsSheet();
      } else {
        setState(() => _isDetecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No prediction returned')),
        );
      }
    } catch (e) {
      debugPrint('Inference failed: $e');
      if (mounted) {
        setState(() => _isDetecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inference failed: $e')),
        );
      }
    }
  }

  void _showResultsSheet() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade900.withOpacity(0.95)
                : Colors.white.withOpacity(0.95),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _capitalize(_label),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Chip(
                  label: Text(
                    'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                  ),
                  backgroundColor: Colors.green.shade100,
                  labelStyle: TextStyle(
                    color: Colors.green.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Leaf scorch can be frustrating, but it’s often manageable. Focus on proper watering, removing infected leaves, and ensuring good airflow between plants.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text('GOT IT!',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: _image != null
                ? Image.file(_image!, fit: BoxFit.cover)
                : Image.asset('assets/images/sample_leaf.jpg', fit: BoxFit.cover),
          ),

          // Blur Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: isDark
                    ? Colors.black.withOpacity(0.4)
                    : Colors.white.withOpacity(0.2),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header with App Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Disease Detection 🌿",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 2, 2, 2),
                          shadows: [
                            Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2))
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            Colors.white.withOpacity(isDark ? 0.1 : 0.9),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: ClipOval(
                            child: Image.asset('assets/images/icon_leaf.png'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Image Preview Card
                  Container(
                    height: MediaQuery.of(context).size.width * 0.7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _image == null
                        ? Container(
                            color: Colors.white.withOpacity(0.1),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.photo_camera_back_outlined,
                                      size: 60, color: Colors.white70),
                                  SizedBox(height: 12),
                                  Text(
                                    'Select an image to start',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Image.file(_image!, fit: BoxFit.cover),
                  ),

                  const SizedBox(height: 30),

                  // Detect Button with Glow
                  ScaleTransition(
                    scale: _pulseController,
                    child: GestureDetector(
                      onTap: (_image == null || _isDetecting) ? null : _runDetection,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: _image != null
                              ? const LinearGradient(
                                  colors: [Color(0xFF00B86B), Color(0xFF2ECC71)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.grey.shade400,
                                    Colors.grey.shade300
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: _image != null
                              ? [
                                  BoxShadow(
                                    color:
                                        const Color(0xFF00B86B).withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isDetecting)
                              const Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            const Icon(Icons.eco_rounded,
                                color: Colors.white, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              _isDetecting ? "DETECTING..." : "DETECT",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Camera + Gallery Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton(
                        icon: Icons.photo_library_outlined,
                        label: 'Gallery',
                        onTap: () => _pickImage(ImageSource.gallery),
                        color: Colors.teal,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 20),
                      _buildActionButton(
                        icon: Icons.camera_alt_outlined,
                        label: 'Camera',
                        onTap: () => _pickImage(ImageSource.camera),
                        color: Colors.green,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      splashColor: color.withOpacity(0.2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.15)]
                : [Colors.white.withOpacity(0.4), Colors.white.withOpacity(0.15)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (rect) => LinearGradient(
                colors: [color, color.withOpacity(0.6)],
              ).createShader(rect),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
