import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class DetectPage extends StatefulWidget {
  const DetectPage({super.key});

  @override
  State<DetectPage> createState() => _DetectPageState();
}

class _DetectPageState extends State<DetectPage>
    with SingleTickerProviderStateMixin {
  File? _image;
  String _label = '';
  double _confidence = 0.0;
  String _solution = '';
  bool _isDetecting = false;
  int _selectedIndex = 1;
  late LanguageProvider _languageProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _languageProvider = Provider.of<LanguageProvider>(context);
  }

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _cropController = TextEditingController();
  final List<String> _cropOptions = ['Jute', 'Paddy', 'Cotton', 'Tomato', 'Cashew'];
  // Kannada display labels for the dropdown (internal values remain English for API)
  final Map<String, String> _cropLabelsKannada = {
    'Jute': 'ಜ್ಯೂಟ್',
    'Paddy': 'ಭತ್ತ',
    'Cotton': 'ಹತ್ತಿ',
    'Tomato': 'ಟೊಮೆಟೊ',
    'Cashew': 'ಕಾಜು',
  };
  final translator = GoogleTranslator();
  final FlutterTts _flutterTts = FlutterTts();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _cropController.addListener(() => setState(() {}));

    // 🎙️ Initialize Text-to-Speech
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setPitch(1.0);
    _flutterTts.setVolume(1.0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cropController.dispose();
    super.dispose();
  }

  // 🌍 Translation helper
  Future<String> _translateToKannada(String text) async {
    try {
      final translated = await translator.translate(text, to: 'kn');
      return translated.text;
    } catch (e) {
      debugPrint('Translation failed: $e');
      return text;
    }
  }

  // 🎧 Speak out pest detection result
  Future<void> _speakDetectionResult() async {
    if (_label.isEmpty || _solution.isEmpty) return;

    String message = _languageProvider.isKannada
        ? "ಕೀಟ: $_label. ವಿಶ್ವಾಸದ ಮಟ್ಟ ${_confidence.toStringAsFixed(1)} ಶೇಕಡಾ. ಪರಿಹಾರ: $_solution"
        : "Detected pest: $_label. Confidence level: ${_confidence.toStringAsFixed(1)} percent. Solution: $_solution";

  await _flutterTts.setLanguage(_languageProvider.isKannada ? "kn-IN" : "en-IN");
    await _flutterTts.speak(message);
  }

  void _onTabTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);

    final route = index == 0 ? '/' : (index == 1 ? '/detect' : '/settings');
    final current = ModalRoute.of(context)?.settings.name;
    if (current == route) return;

    Navigator.pushReplacementNamed(context, route);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file =
          await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1200);
      if (file == null) return;
      if (!mounted) return;
      setState(() {
        _image = File(file.path);
        _label = '';
        _solution = '';
        _confidence = 0.0;
      });
    } catch (e) {
      debugPrint('Failed to pick image: $e');
    }
  }

  Future<void> _runDetection() async {
    if (_image == null || _cropController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an image and enter crop name'),
          backgroundColor: Colors.orange.shade600,
        ),
      );
      return;
    }

    setState(() => _isDetecting = true);

    try {
      final uri = Uri.parse(
          "https://manavishetty-pest-detection-api.hf.space/predict");
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', _image!.path));
      request.fields['crop_type'] = _cropController.text.trim();

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        String pest = data['predicted_pest'] ?? 'Unknown';
        double confidence = (data['confidence'] ?? 0.0).toDouble();
        String solution = data['solution'] ?? 'No solution found.';

        // ❌ Invalid case (confidence < 70)
        if (data['predicted_pest'] == null || confidence < 70) {
          setState(() => _isDetecting = false);
          _showInvalidResultDialog(
        _languageProvider.isKannada
          ? "ಚಿತ್ರವು ಯಾವುದೇ ತಿಳಿದಿರುವ ಕೀಟಕ್ಕೆ ಹೊಂದಿಕೆಯಾಗುವುದಿಲ್ಲ."
          : "The image does not clearly match any known pest.",
          );
          return;
        }

        // 🌐 Translate if Kannada mode
        if (_languageProvider.isKannada) {
          pest = await _translateToKannada(pest);
          solution = await _translateToKannada(solution);
        }

        setState(() {
          _label = pest;
          _confidence = confidence;
          _solution = solution;
          _isDetecting = false;
        });

        _showResultsSheet(solution: solution);
        await _speakDetectionResult(); // 🎙️ Speak automatically
      } else {
        setState(() => _isDetecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => _isDetecting = false);
      debugPrint('Error: $e');
    }
  }

  // ❌ Invalid result popup
  void _showInvalidResultDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_languageProvider.isKannada ? "ಪತ್ತೆ ವಿಫಲವಾಗಿದೆ" : "Detection Failed"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_languageProvider.isKannada ? "ಸರಿ" : "OK"),
          ),
        ],
      ),
    );
  }

  // ✅ Bottom sheet with results
  void _showResultsSheet({required String solution}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF66BB6A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.check, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _languageProvider.isKannada ? "ಪತ್ತೆ ಪೂರ್ಣವಾಗಿದೆ" : "Detection Complete",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _label,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart, color: Colors.green[700], size: 20),
                      const SizedBox(width: 6),
                      Text(
                        _languageProvider.isKannada ? "ವಿಶ್ವಾಸದ ಮಟ್ಟ" : "Confidence Level",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${_confidence.toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green[700],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _languageProvider.isKannada ? "ಹೆಚ್ಚು" : "High",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Icon(Icons.medical_services,
                          color: Colors.blue[700], size: 20),
                      const SizedBox(width: 6),
                      Text(
                        _languageProvider.isKannada
                            ? "ಶಿಫಾರಸು ಮಾಡಿದ ಚಿಕಿತ್ಸೆ"
                            : "Recommended Treatment",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      solution,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 🔊 Speak Result Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _speakDetectionResult,
                      icon: const Icon(Icons.volume_up, color: Colors.white),
                      label: Text(
                        _languageProvider.isKannada ? "ಫಲಿತಾಂಶವನ್ನು ಕೇಳಿ" : "Hear Result",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Got It button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF66BB6A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _languageProvider.isKannada ? "ಅರ್ಥವಾಯಿತು!" : "GOT IT!",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔽 UI SECTIONS 🔽
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0E0A) : const Color(0xFFF8FBF8);


    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildHeader(isDark),
                const SizedBox(height: 32),
                _buildCropInput(isDark),
                const SizedBox(height: 24),
                _buildImagePreview(isDark),
                const SizedBox(height: 28),
                _buildDetectButton(isDark),
                const SizedBox(height: 24),
                _buildActionButtons(isDark),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
              : [const Color(0xFF66BB6A), const Color(0xFF81C784)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          const Icon(Icons.camera_alt, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _languageProvider.isKannada ? "ಹುಳು ಪತ್ತೆ" : "Pest Detection",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            tooltip: _languageProvider.isKannada ? "Switch to English" : "ಕನ್ನಡಕ್ಕೆ ಬದಲಿಸಿ",
            onPressed: () {
              setState(() {
                _languageProvider.toggleLanguage();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCropInput(bool isDark) {
    return DropdownButtonFormField<String>(
      value: _cropController.text.isEmpty ? null : _cropController.text,
      items: _cropOptions.map((crop) {
        final display = _languageProvider.isKannada
            ? (_cropLabelsKannada[crop] ?? crop)
            : crop;
        return DropdownMenuItem(
          value: crop,
          child: Text(display),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _cropController.text = value ?? '';
        });
      },
      decoration: InputDecoration(
        hintText: _languageProvider.isKannada
            ? "ಬೆಳೆ ಆಯ್ಕೆ ಮಾಡಿ (ಉದಾ: ಟೊಮೆಟೊ, ಹತ್ತಿ)"
            : "Select crop (e.g., Tomato, Cotton)",
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
    );
  }

  Widget _buildImagePreview(bool isDark) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: _image == null
          ? const Center(child: Text("No Image Selected"))
          : Image.file(_image!, fit: BoxFit.cover),
    );
  }

  Widget _buildDetectButton(bool isDark) {
    final isEnabled =
        _image != null && !_isDetecting && _cropController.text.trim().isNotEmpty;

    return GestureDetector(
      onTap: isEnabled ? _runDetection : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEnabled
                ? [Colors.green.shade500, Colors.green.shade700]
                : [Colors.grey.shade400, Colors.grey.shade300],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: _isDetecting
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  _languageProvider.isKannada ? "ಹುಳು ಪತ್ತೆ" : "Detect Pest",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(_languageProvider.isKannada ? "ಗ್ಯಾಲರಿ" : "Gallery"),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(_languageProvider.isKannada ? "ಕ್ಯಾಮೆರಾ" : "Camera"),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onTabTapped,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      indicatorColor: Colors.green.shade100,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home, color: Colors.green),
          label: _languageProvider.isKannada ? 'ಮುಖಪುಟ' : 'Home',
        ),
        NavigationDestination(
          icon: const Icon(Icons.camera_alt_outlined),
          selectedIcon: const Icon(Icons.camera_alt, color: Colors.green),
          label: _languageProvider.isKannada ? 'ಪತ್ತೆ ಮಾಡಿ' : 'Detect',
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings, color: Colors.green),
          label: _languageProvider.isKannada ? 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು' : 'Settings',
        ),
      ],
    );
  }
}
