import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  File? _selectedImage;
  String _searchQuery = '';
  bool _isKannada = false; // Language toggle
  
  // Weather data
  Map<String, dynamic>? _weatherData;
  bool _isLoadingWeather = true;
  String _weatherError = '';

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  // ---------- Translation Map ----------
  Map<String, String> _translate(String key) {
    final translations = {
      'appTitle': _isKannada ? 'ಪೆಸ್ಟ್‌ವಿಷನ್' : 'PestVision',
      'tagline': _isKannada ? 'ನಿಮ್ಮ ಸ್ಮಾರ್ಟ್ ಕೃಷಿ ಸಹಾಯಕ' : 'Your smart farming companion',
      'tipText': _isKannada ? 'ಕೀಟಗಳನ್ನು ಪತ್ತೆ ಮಾಡಿ, ಗುರುತಿಸಿ ಮತ್ತು ನಿರ್ವಹಿಸಿ' : 'Detect, identify, and manage pests',
      'searchHint': _isKannada ? 'ಕೀಟಗಳನ್ನು ಹುಡುಕಿ...' : 'Search pests...',
      'crops': _isKannada ? 'ಬೆಳೆಗಳು' : 'Crops',
      'tapForInfo': _isKannada ? 'ಮಾಹಿತಿಗಾಗಿ ಟ್ಯಾಪ್ ಮಾಡಿ' : 'Tap for info',
      'commonPests': _isKannada ? 'ಸಾಮಾನ್ಯ ಕೀಟಗಳು' : 'Common Pests',
      'tapForDetails': _isKannada ? 'ವಿವರಗಳಿಗಾಗಿ ಟ್ಯಾಪ್ ಮಾಡಿ' : 'Tap for details',
      'home': _isKannada ? 'ಮುಖಪುಟ' : 'Home',
      'detect': _isKannada ? 'ಪತ್ತೆ ಮಾಡಿ' : 'Detect',
      'settings': _isKannada ? 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು' : 'Settings',
      'about': _isKannada ? 'ಬಗ್ಗೆ' : 'About',
      'treatment': _isKannada ? 'ಚಿಕಿತ್ಸೆ' : 'Treatment',
      'detailedInfo': _isKannada ? 'ವಿವರವಾದ ಮಾಹಿತಿ' : 'Detailed Information',
      'commonPestsTitle': _isKannada ? 'ಸಾಮಾನ್ಯ ಕೀಟಗಳು' : 'Common Pests',
      'humidity': _isKannada ? 'ತೇವಾಂಶ' : 'Humidity',
      'wind': _isKannada ? 'ಗಾಳಿ' : 'Wind',
      'feelsLike': _isKannada ? 'ಅನುಭವವಾಗುತ್ತಿದೆ' : 'Feels like',
      'retry': _isKannada ? 'ಮರುಪ್ರಯತ್ನಿಸಿ' : 'Retry',
    };
    return translations;
  }

  // ---------- Weather Functions ----------
  Future<void> _fetchWeather() async {
    try {
      setState(() {
        _isLoadingWeather = true;
        _weatherError = '';
      });

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _weatherError = _isKannada ? 'ಸ್ಥಳ ಅನುಮತಿ ನಿರಾಕರಿಸಲಾಗಿದೆ' : 'Location permission denied';
            _isLoadingWeather = false;
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=${position.latitude}&longitude=${position.longitude}&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m&timezone=auto',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        final geoUrl = Uri.parse(
          'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${position.latitude}&longitude=${position.longitude}&localityLanguage=en',
        );
        
        final geoResponse = await http.get(geoUrl);
        String locationName = _isKannada ? 'ಪ್ರಸ್ತುತ ಸ್ಥಳ' : 'Current Location';
        
        if (geoResponse.statusCode == 200) {
          final geoData = json.decode(geoResponse.body);
          locationName = geoData['city'] ?? geoData['locality'] ?? geoData['principalSubdivision'] ?? locationName;
        }

        setState(() {
          _weatherData = {
            'location': locationName,
            'temp': data['current']['temperature_2m'],
            'feels_like': data['current']['apparent_temperature'],
            'humidity': data['current']['relative_humidity_2m'],
            'wind_speed': data['current']['wind_speed_10m'],
            'weather_code': data['current']['weather_code'],
          };
          _isLoadingWeather = false;
        });
      } else {
        setState(() {
          _weatherError = _isKannada ? 'ಹವಾಮಾನ ಡೇಟಾ ಲೋಡ್ ಮಾಡಲು ವಿಫಲವಾಗಿದೆ' : 'Failed to load weather data';
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      setState(() {
        _weatherError = _isKannada ? 'ದೋಷ: ${e.toString()}' : 'Error: ${e.toString()}';
        _isLoadingWeather = false;
      });
    }
  }

  String _getWeatherDescription(int code) {
    if (!_isKannada) {
      if (code == 0) return 'Clear sky';
      if (code <= 3) return 'Partly cloudy';
      if (code <= 48) return 'Foggy';
      if (code <= 67) return 'Rainy';
      if (code <= 77) return 'Snowy';
      if (code <= 82) return 'Rain showers';
      if (code <= 86) return 'Snow showers';
      if (code <= 99) return 'Thunderstorm';
      return 'Unknown';
    } else {
      if (code == 0) return 'ಸ್ಪಷ್ಟ ಆಕಾಶ';
      if (code <= 3) return 'ಭಾಗಶಃ ಮೋಡ';
      if (code <= 48) return 'ಮಂಜು';
      if (code <= 67) return 'ಮಳೆ';
      if (code <= 77) return 'ಹಿಮ';
      if (code <= 82) return 'ಮಳೆಯ ಸುರಿಮಳೆ';
      if (code <= 86) return 'ಹಿಮದ ಸುರಿಮಳೆ';
      if (code <= 99) return 'ಗುಡುಗು ಸಹಿತ ಮಳೆ';
      return 'ಅಜ್ಞಾತ';
    }
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code <= 3) return Icons.wb_cloudy;
    if (code <= 48) return Icons.cloud;
    if (code <= 67) return Icons.water_drop;
    if (code <= 77) return Icons.ac_unit;
    if (code <= 82) return Icons.umbrella;
    if (code <= 86) return Icons.snowing;
    if (code <= 99) return Icons.thunderstorm;
    return Icons.wb_sunny;
  }

  // List of pests with detailed information
  final List<Map<String, dynamic>> _pestsData = [
    {
      "name": {"en": "Aphid", "kn": "ಗಿಡಹೇನು"},
      "desc": {"en": "Tiny green insects that suck sap from leaves.", "kn": "ಎಲೆಗಳಿಂದ ರಸವನ್ನು ಹೀರುವ ಚಿಕ್ಕ ಹಸಿರು ಕೀಟಗಳು."},
      "img": "assets/images/aphid.jpg",
      "details": {"en": "Aphids are small, soft-bodied insects that feed on plant sap. They reproduce rapidly and can cause significant damage to crops. Look for curled leaves, yellowing, and sticky residue.", "kn": "ಗಿಡಹೇನುಗಳು ಸಣ್ಣ, ಮೃದು ದೇಹದ ಕೀಟಗಳಾಗಿದ್ದು ಸಸ್ಯದ ರಸವನ್ನು ತಿನ್ನುತ್ತವೆ. ಅವು ವೇಗವಾಗಿ ಸಂತಾನೋತ್ಪತ್ತಿ ಮಾಡುತ್ತವೆ ಮತ್ತು ಬೆಳೆಗಳಿಗೆ ಗಮನಾರ್ಹ ಹಾನಿ ಮಾಡಬಹುದು."},
      "treatment": {"en": "Use neem oil spray or introduce natural predators like ladybugs.", "kn": "ಬೇವಿನ ಎಣ್ಣೆ ಸಿಂಪಡಿಸಿ ಅಥವಾ ಹೆಣಕೀಟಗಳಂತಹ ನೈಸರ್ಗಿಕ ಪರಭಕ್ಷಕಗಳನ್ನು ಪರಿಚಯಿಸಿ."}
    },
    {
      "name": {"en": "Whitefly", "kn": "ಬಿಳಿ ನೊಣ"},
      "desc": {"en": "Small white pests that feed on the undersides of leaves.", "kn": "ಎಲೆಗಳ ಕೆಳಭಾಗದಲ್ಲಿ ಆಹಾರಿಸುವ ಸಣ್ಣ ಬಿಳಿ ಕೀಟಗಳು."},
      "img": "assets/images/whitefly.jpg",
      "details": {"en": "Whiteflies are tiny flying insects that cluster on leaf undersides. They weaken plants by sucking sap and can transmit viral diseases.", "kn": "ಬಿಳಿ ನೊಣಗಳು ಎಲೆಗಳ ಕೆಳಭಾಗದಲ್ಲಿ ಗುಂಪುಗೂಡುವ ಸಣ್ಣ ಹಾರುವ ಕೀಟಗಳಾಗಿವೆ. ಅವು ರಸವನ್ನು ಹೀರುವ ಮೂಲಕ ಸಸ್ಯಗಳನ್ನು ದುರ್ಬಲಗೊಳಿಸುತ್ತವೆ."},
      "treatment": {"en": "Apply insecticidal soap or yellow sticky traps to control populations.", "kn": "ಕೀಟನಾಶಕ ಸೋಪ್ ಅಥವಾ ಹಳದಿ ಅಂಟುವ ಬಲೆಗಳನ್ನು ಬಳಸಿ."}
    },
    {
      "name": {"en": "Thrips", "kn": "ಥ್ರಿಪ್ಸ್"},
      "desc": {"en": "Slender insects causing silver patches on leaves.", "kn": "ಎಲೆಗಳ ಮೇಲೆ ಬೆಳ್ಳಿ ತೇಪೆಗಳನ್ನು ಉಂಟುಮಾಡುವ ತೆಳ್ಳಗಿನ ಕೀಟಗಳು."},
      "img": "assets/images/thrips.jpg",
      "details": {"en": "Thrips are minute insects that cause silvery scarring on leaves and flowers. They can spread plant viruses and affect crop quality.", "kn": "ಥ್ರಿಪ್ಸ್ ಎಲೆಗಳು ಮತ್ತು ಹೂವುಗಳ ಮೇಲೆ ಬೆಳ್ಳಿಯ ಗಾಯವನ್ನು ಉಂಟುಮಾಡುವ ಸೂಕ್ಷ್ಮ ಕೀಟಗಳಾಗಿವೆ."},
      "treatment": {"en": "Use blue sticky traps and spray with spinosad-based pesticides.", "kn": "ನೀಲಿ ಅಂಟುವ ಬಲೆಗಳನ್ನು ಬಳಸಿ ಮತ್ತು ಸ್ಪಿನೋಸಾಡ್ ಆಧಾರಿತ ಕೀಟನಾಶಕಗಳನ್ನು ಸಿಂಪಡಿಸಿ."}
    },
    {
      "name": {"en": "Beetle", "kn": "ಜಿರಳೆ"},
      "desc": {"en": "Beetles chew holes in leaves and stems.", "kn": "ಜಿರಳೆಗಳು ಎಲೆಗಳು ಮತ್ತು ಕಾಂಡಗಳಲ್ಲಿ ರಂಧ್ರಗಳನ್ನು ಕಚ್ಚುತ್ತವೆ."},
      "img": "assets/images/beetle.jpg",
      "details": {"en": "Beetles are hard-shelled insects that feed on various plant parts. They create visible holes in foliage and can defoliate plants rapidly.", "kn": "ಜಿರಳೆಗಳು ಗಟ್ಟಿಯಾದ ಚಿಪ್ಪಿನ ಕೀಟಗಳಾಗಿದ್ದು ವಿವಿಧ ಸಸ್ಯ ಭಾಗಗಳನ್ನು ತಿನ್ನುತ್ತವೆ."},
      "treatment": {"en": "Handpick beetles and use neem oil or pyrethrin-based sprays.", "kn": "ಜಿರಳೆಗಳನ್ನು ಕೈಯಿಂದ ತೆಗೆಯಿರಿ ಮತ್ತು ಬೇವಿನ ಎಣ್ಣೆ ಬಳಸಿ."}
    },
    {
      "name": {"en": "Caterpillar", "kn": "ಕಂಬಳಿ ಹುಳು"},
      "desc": {"en": "Larvae that chew through leaves and fruits.", "kn": "ಎಲೆಗಳು ಮತ್ತು ಹಣ್ಣುಗಳನ್ನು ಕಚ್ಚುವ ಲಾರ್ವಾಗಳು."},
      "img": "assets/images/caterpillar.jpg",
      "details": {"en": "Caterpillars are the larval stage of moths and butterflies. They feed heavily on leaves, causing holes and defoliation. Some species also bore into fruits and stems.", "kn": "ಕಂಬಳಿ ಹುಳುಗಳು ಪತಂಗಗಳು ಮತ್ತು ಚಿಟ್ಟೆಗಳ ಲಾರ್ವಾ ಹಂತವಾಗಿದೆ. ಅವು ಎಲೆಗಳನ್ನು ಹೆಚ್ಚಾಗಿ ತಿನ್ನುತ್ತವೆ."},
      "treatment": {"en": "Use Bacillus thuringiensis (Bt) spray or handpick visible larvae during early stages.", "kn": "ಬ್ಯಾಸಿಲಸ್ ತುರಿಂಜೆನ್ಸಿಸ್ (Bt) ಸಿಂಪಡಿಸಿ ಅಥವಾ ಆರಂಭಿಕ ಹಂತದಲ್ಲಿ ಲಾರ್ವಾಗಳನ್ನು ಕೈಯಿಂದ ತೆಗೆಯಿರಿ."}
    },
    {
      "name": {"en": "Mealybug", "kn": "ಹೊಟ್ಟೆ ಹುಳು"},
      "desc": {"en": "White cottony pests found on stems and leaves.", "kn": "ಕಾಂಡಗಳು ಮತ್ತು ಎಲೆಗಳ ಮೇಲೆ ಕಂಡುಬರುವ ಬಿಳಿ ಹತ್ತಿಯಂತಹ ಕೀಟಗಳು."},
      "img": "assets/images/mealybug.jpg",
      "details": {"en": "Mealybugs are soft-bodied insects covered in a white waxy coating. They suck plant sap and excrete honeydew, leading to sooty mold growth.", "kn": "ಹೊಟ್ಟೆ ಹುಳುಗಳು ಬಿಳಿ ಮೇಣದ ಲೇಪನದಿಂದ ಆವೃತವಾದ ಮೃದು ದೇಹದ ಕೀಟಗಳಾಗಿವೆ."},
      "treatment": {"en": "Apply neem oil or rubbing alcohol on affected parts. Encourage ladybugs as natural predators.", "kn": "ಬೇವಿನ ಎಣ್ಣೆ ಅಥವಾ ಆಲ್ಕೋಹಾಲ್ ಅನ್ನು ಪೀಡಿತ ಭಾಗಗಳಿಗೆ ಅನ್ವಯಿಸಿ."}
    },
    {
      "name": {"en": "Spider Mite", "kn": "ಜೇಡ ಹುಳು"},
      "desc": {"en": "Tiny red or yellow mites forming webs on leaves.", "kn": "ಎಲೆಗಳ ಮೇಲೆ ಜಾಲಗಳನ್ನು ರೂಪಿಸುವ ಸಣ್ಣ ಕೆಂಪು ಅಥವಾ ಹಳದಿ ಹುಳುಗಳು."},
      "img": "assets/images/spidermite.jpg",
      "details": {"en": "Spider mites are microscopic arachnids that thrive in hot, dry conditions. They cause stippling and yellowing of leaves, often leaving fine webbing on plants.", "kn": "ಜೇಡ ಹುಳುಗಳು ಬಿಸಿ, ಶುಷ್ಕ ಪರಿಸ್ಥಿತಿಗಳಲ್ಲಿ ಬೆಳೆಯುವ ಸೂಕ್ಷ್ಮ ಜೀವಿಗಳಾಗಿವೆ."},
      "treatment": {"en": "Spray water to wash off mites, use miticides, or apply neem oil regularly.", "kn": "ಹುಳುಗಳನ್ನು ತೊಳೆಯಲು ನೀರನ್ನು ಸಿಂಪಡಿಸಿ, ಅಥವಾ ಬೇವಿನ ಎಣ್ಣೆ ನಿಯಮಿತವಾಗಿ ಅನ್ವಯಿಸಿ."}
    },
    {
      "name": {"en": "Grasshopper", "kn": "ಮಿಡತೆ"},
      "desc": {"en": "Large jumping insects that chew leaves and stems.", "kn": "ಎಲೆಗಳು ಮತ್ತು ಕಾಂಡಗಳನ್ನು ಕಚ್ಚುವ ದೊಡ್ಡ ಜಿಗಿಯುವ ಕೀಟಗಳು."},
      "img": "assets/images/grasshopper.jpg",
      "details": {"en": "Grasshoppers feed on a wide range of crops, chewing holes in leaves and stems. Heavy infestations can completely defoliate plants.", "kn": "ಮಿಡತೆಗಳು ವ್ಯಾಪಕ ಶ್ರೇಣಿಯ ಬೆಳೆಗಳನ್ನು ತಿನ್ನುತ್ತವೆ, ಎಲೆಗಳು ಮತ್ತು ಕಾಂಡಗಳಲ್ಲಿ ರಂಧ್ರಗಳನ್ನು ಕಚ್ಚುತ್ತವೆ."},
      "treatment": {"en": "Use neem-based repellents or cover crops with protective nets.", "kn": "ಬೇವು ಆಧಾರಿತ ನಿವಾರಕಗಳನ್ನು ಬಳಸಿ ಅಥವಾ ರಕ್ಷಣಾತ್ಮಕ ಬಲೆಗಳಿಂದ ಬೆಳೆಗಳನ್ನು ಮುಚ್ಚಿ."}
    },
    {
      "name": {"en": "Leaf Miner", "kn": "ಎಲೆ ಗಣಿಗಾರ"},
      "desc": {"en": "Larvae that tunnel within leaves forming visible trails.", "kn": "ಎಲೆಗಳೊಳಗೆ ಸುರಂಗ ಮಾಡುವ ಲಾರ್ವಾಗಳು ಗೋಚರ ಹಾದಿಗಳನ್ನು ರೂಪಿಸುತ್ತವೆ."},
      "img": "assets/images/leafminer.jpg",
      "details": {"en": "Leaf miners are larvae of flies or moths that burrow between leaf layers, creating white, winding trails. Severe infestations reduce photosynthesis.", "kn": "ಎಲೆ ಗಣಿಗಾರರು ಎಲೆ ಪದರಗಳ ನಡುವೆ ಕೊರೆಯುವ ನೊಣಗಳು ಅಥವಾ ಪತಂಗಗಳ ಲಾರ್ವಾಗಳಾಗಿವೆ."},
      "treatment": {"en": "Remove and destroy affected leaves, and use systemic insecticides if needed.", "kn": "ಪೀಡಿತ ಎಲೆಗಳನ್ನು ತೆಗೆದುಹಾಕಿ ಮತ್ತು ನಾಶಪಡಿಸಿ, ಅಗತ್ಯವಿದ್ದರೆ ವ್ಯವಸ್ಥಿತ ಕೀಟನಾಶಕಗಳನ್ನು ಬಳಸಿ."}
    },
    {
      "name": {"en": "Armyworm", "kn": "ಸೇನಾ ಹುಳು"},
      "desc": {"en": "Striped caterpillars that attack crops in groups.", "kn": "ಗುಂಪುಗಳಲ್ಲಿ ಬೆಳೆಗಳ ಮೇಲೆ ದಾಳಿ ಮಾಡುವ ಪಟ್ಟೆ ಕಂಬಳಿ ಹುಳುಗಳು."},
      "img": "assets/images/armyworm.jpg",
      "details": {"en": "Armyworms are nocturnal feeders that attack grains, maize, and vegetables. They move in masses, eating leaves, stems, and even young shoots.", "kn": "ಸೇನಾ ಹುಳುಗಳು ರಾತ್ರಿಯಲ್ಲಿ ಆಹಾರಿಸುವವು, ಧಾನ್ಯಗಳು, ಜೋಳ ಮತ್ತು ತರಕಾರಿಗಳ ಮೇಲೆ ದಾಳಿ ಮಾಡುತ್ತವೆ."},
      "treatment": {"en": "Use pheromone traps or Bt-based biopesticides during early larval stages.", "kn": "ಆರಂಭಿಕ ಲಾರ್ವಾ ಹಂತದಲ್ಲಿ ಫೆರೋಮೋನ್ ಬಲೆಗಳನ್ನು ಅಥವಾ Bt-ಆಧಾರಿತ ಜೈವಿಕ ಕೀಟನಾಶಕಗಳನ್ನು ಬಳಸಿ."}
    },
    {
      "name": {"en": "Scale Insect", "kn": "ಪರೆ ಕೀಟ"},
      "desc": {"en": "Small immobile pests forming hard shells on stems.", "kn": "ಕಾಂಡಗಳ ಮೇಲೆ ಗಟ್ಟಿಯಾದ ಚಿಪ್ಪುಗಳನ್ನು ರೂಪಿಸುವ ಸಣ್ಣ ಚಲನರಹಿತ ಕೀಟಗಳು."},
      "img": "assets/images/scale.jpg",
      "details": {"en": "Scale insects attach to stems and leaves, sucking plant juices. They weaken the plant and cause yellowing or stunted growth.", "kn": "ಪರೆ ಕೀಟಗಳು ಕಾಂಡಗಳು ಮತ್ತು ಎಲೆಗಳಿಗೆ ಅಂಟಿಕೊಳ್ಳುತ್ತವೆ, ಸಸ್ಯದ ರಸವನ್ನು ಹೀರುತ್ತವೆ."},
      "treatment": {"en": "Prune infested parts and apply horticultural oil sprays.", "kn": "ಸೋಂಕಿತ ಭಾಗಗಳನ್ನು ಕತ್ತರಿಸಿ ಮತ್ತು ತೋಟಗಾರಿಕೆ ಎಣ್ಣೆ ಸಿಂಪಡಿಸಿ."}
    },
    {
      "name": {"en": "Stem Borer", "kn": "ಕಾಂಡ ಕೊರೆಯುವ ಹುಳು"},
      "desc": {"en": "Larvae that bore into plant stems, causing wilting.", "kn": "ಸಸ್ಯದ ಕಾಂಡಗಳನ್ನು ಕೊರೆಯುವ ಲಾರ್ವಾಗಳು, ಬಾಡುವಿಕೆಯನ್ನು ಉಂಟುಮಾಡುತ್ತವೆ."},
      "img": "assets/images/stemborer.jpg",
      "details": {"en": "Stem borers are caterpillars that tunnel inside stems, cutting off nutrient flow. Commonly attack rice, maize, and sugarcane crops.", "kn": "ಕಾಂಡ ಕೊರೆಯುವ ಹುಳುಗಳು ಕಾಂಡಗಳ ಒಳಗೆ ಸುರಂಗ ಮಾಡುವ ಕಂಬಳಿ ಹುಳುಗಳಾಗಿವೆ."},
      "treatment": {"en": "Remove infested stems and use pheromone traps or Trichogramma egg parasitoids.", "kn": "ಸೋಂಕಿತ ಕಾಂಡಗಳನ್ನು ತೆಗೆದುಹಾಕಿ ಮತ್ತು ಫೆರೋಮೋನ್ ಬಲೆಗಳನ್ನು ಬಳಸಿ."}
    },
    {
      "name": {"en": "Cutworm", "kn": "ಕಟ್ ವರ್ಮ್"},
      "desc": {"en": "Nocturnal larvae that cut seedlings at the base.", "kn": "ಮೊಳಕೆಗಳನ್ನು ತಳದಲ್ಲಿ ಕತ್ತರಿಸುವ ರಾತ್ರಿಯ ಲಾರ್ವಾಗಳು."},
      "img": "assets/images/cutworm.jpg",
      "details": {"en": "Cutworms hide in the soil during the day and feed at night by cutting young seedlings at ground level. They cause serious losses in nurseries and fields.", "kn": "ಕಟ್‌ವರ್ಮ್‌ಗಳು ಹಗಲಿನಲ್ಲಿ ಮಣ್ಣಿನಲ್ಲಿ ಅಡಗಿಕೊಳ್ಳುತ್ತವೆ ಮತ್ತು ರಾತ್ರಿಯಲ್ಲಿ ಆಹಾರಿಸುತ್ತವೆ."},
      "treatment": {"en": "Plow fields before planting and use biological control with nematodes or Bt.", "kn": "ನೆಟ್ಟ ಮೊದಲು ಹೊಲಗಳನ್ನು ಉಳುಮೆ ಮಾಡಿ ಮತ್ತು ನೆಮಟೋಡ್‌ಗಳು ಅಥವಾ Bt ನೊಂದಿಗೆ ಜೈವಿಕ ನಿಯಂತ್ರಣ ಬಳಸಿ."}
    },
    {
      "name": {"en": "Fruit Fly", "kn": "ಹಣ್ಣಿನ ನೊಣ"},
      "desc": {"en": "Small flies that lay eggs inside fruits.", "kn": "ಹಣ್ಣುಗಳ ಒಳಗೆ ಮೊಟ್ಟೆಗಳನ್ನು ಇಡುವ ಸಣ್ಣ ನೊಣಗಳು."},
      "img": "assets/images/fruitfly.jpg",
      "details": {"en": "Fruit flies puncture fruits to lay eggs, and larvae feed on the pulp causing rot and early fruit drop. They affect mango, guava, and tomato crops.", "kn": "ಹಣ್ಣಿನ ನೊಣಗಳು ಮೊಟ್ಟೆಗಳನ್ನು ಇಡಲು ಹಣ್ಣುಗಳನ್ನು ಚುಚ್ಚುತ್ತವೆ, ಮತ್ತು ಲಾರ್ವಾಗಳು ತಿರುಳನ್ನು ತಿನ್ನುತ್ತವೆ."},
      "treatment": {"en": "Use pheromone traps, destroy infested fruits, and apply protein bait sprays.", "kn": "ಫೆರೋಮೋನ್ ಬಲೆಗಳನ್ನು ಬಳಸಿ, ಸೋಂಕಿತ ಹಣ್ಣುಗಳನ್ನು ನಾಶಪಡಿಸಿ, ಮತ್ತು ಪ್ರೋಟೀನ್ ಬೆಟ್ ಸಿಂಪಡಿಸಿ."}
    },
  ];

  // Get pests in current language
  List<Map<String, String>> get _pests {
    return _pestsData.map((pest) {
      return {
        "name": pest["name"][_isKannada ? "kn" : "en"] as String,
        "desc": pest["desc"][_isKannada ? "kn" : "en"] as String,
        "img": pest["img"] as String,
        "details": pest["details"][_isKannada ? "kn" : "en"] as String,
        "treatment": pest["treatment"][_isKannada ? "kn" : "en"] as String,
      };
    }).toList();
  }

  // Crop information
  final List<Map<String, dynamic>> _cropsData = [
    {
      'icon': Icons.grass,
      'name': {'en': 'Jute', 'kn': 'ಸೆಣಬು'},
      'color': const Color(0xFF8BC34A),
      'info': {'en': 'Jute is a natural fiber crop used for making burlap, hessian, and rope. It grows best in warm, humid climates.', 'kn': 'ಸೆಣಬು ಬರ್ಲ್ಯಾಪ್, ಹೆಸ್ಸಿಯನ್ ಮತ್ತು ಹಗ್ಗವನ್ನು ತಯಾರಿಸಲು ಬಳಸುವ ನೈಸರ್ಗಿಕ ನಾರು ಬೆಳೆಯಾಗಿದೆ.'},
      'pests': {'en': 'Common pests: Stem weevil, semilooper, Bihar hairy caterpillar', 'kn': 'ಸಾಮಾನ್ಯ ಕೀಟಗಳು: ಕಾಂಡ ಜೀರುಂಡೆ, ಸೆಮಿಲೂಪರ್, ಬಿಹಾರ್ ಕೂದಲು ಕಂಬಳಿ ಹುಳು'}
    },
    {
      'icon': Icons.agriculture,
      'name': {'en': 'Paddy', 'kn': 'ಭತ್ತ'},
      'color': const Color(0xFF66BB6A),
      'info': {'en': 'Rice (Paddy) is a staple food crop for half the world\'s population. It requires flooded conditions for optimal growth.', 'kn': 'ಭತ್ತ (ಧಾನ್ಯ) ಪ್ರಪಂಚದ ಅರ್ಧದಷ್ಟು ಜನಸಂಖ್ಯೆಗೆ ಮುಖ್ಯ ಆಹಾರ ಬೆಳೆಯಾಗಿದೆ.'},
      'pests': {'en': 'Common pests: Brown planthopper, stem borer, leaf folder', 'kn': 'ಸಾಮಾನ್ಯ ಕೀಟಗಳು: ಕಂದು ಪ್ಲ್ಯಾಂಟ್‌ಹಾಪರ್, ಕಾಂಡ ಕೊರೆಯುವ ಹುಳು, ಎಲೆ ಮಡಿಸುವವರು'}
    },
    {
      'icon': Icons.grass,
      'name': {'en': 'Cotton', 'kn': 'ಹತ್ತಿ'},
      'color': const Color(0xFFB0BEC5),
      'info': {'en': 'Cotton is a soft, fluffy fiber grown in warm climates. It requires plenty of sunlight and well-drained soil.', 'kn': 'ಹತ್ತಿ ಬೆಚ್ಚಗಿನ ವಾತಾವರಣದಲ್ಲಿ ಬೆಳೆಯುವ ಮೃದುವಾದ, ತುಪ್ಪುಳಿನಂತಿರುವ ನಾರು.'},
      'pests': {'en': 'Common pests: Bollworm, aphids, whitefly, jassids', 'kn': 'ಸಾಮಾನ್ಯ ಕೀಟಗಳು: ಬೊಲ್‌ವರ್ಮ್, ಗಿಡಹೇನು, ಬಿಳಿ ನೊಣ, ಜಾಸಿಡ್‌ಗಳು'}
    },
    {
      'icon': Icons.emoji_nature,
      'name': {'en': 'Tomato', 'kn': 'ಟೊಮೇಟೊ'},
      'color': const Color(0xFFEF5350),
      'info': {'en': 'Tomatoes are nutrient-rich fruits grown worldwide. They require warm temperatures and consistent watering.', 'kn': 'ಟೊಮೇಟೊಗಳು ಪ್ರಪಂಚದಾದ್ಯಂತ ಬೆಳೆಯುವ ಪೋಷಕಾಂಶ-ಸಮೃದ್ಧ ಹಣ್ಣುಗಳಾಗಿವೆ.'},
      'pests': {'en': 'Common pests: Whitefly, aphids, fruit borer, leaf miner', 'kn': 'ಸಾಮಾನ್ಯ ಕೀಟಗಳು: ಬಿಳಿ ನೊಣ, ಗಿಡಹೇನು, ಹಣ್ಣು ಕೊರೆಯುವ ಹುಳು, ಎಲೆ ಗಣಿಗಾರ'}
    },
    {
      'icon': Icons.eco,
      'name': {'en': 'Cashew', 'kn': 'ಗೋಡಂಬಿ'},
      'color': const Color(0xFF81C784),
      'info': {'en': 'Cashew is a tropical tree crop producing both nuts and apples. It grows well in coastal regions with moderate rainfall.', 'kn': 'ಗೋಡಂಬಿ ಬೀಜಗಳು ಮತ್ತು ಸೇಬುಗಳನ್ನು ಉತ್ಪಾದಿಸುವ ಉಷ್ಣವಲಯದ ಮರದ ಬೆಳೆಯಾಗಿದೆ.'},
      'pests': {'en': 'Common pests: Tea mosquito bug, stem borer, leaf miner', 'kn': 'ಸಾಮಾನ್ಯ ಕೀಟಗಳು: ಚಹಾ ಸೊಳ್ಳೆ ಬಗ್, ಕಾಂಡ ಕೊರೆಯುವ ಹುಳು, ಎಲೆ ಗಣಿಗಾರ'}
    },
  ];

  // Get crops in current language
  List<Map<String, dynamic>> get _crops {
    return _cropsData.map((crop) {
      return {
        'icon': crop['icon'],
        'name': crop['name'][_isKannada ? 'kn' : 'en'],
        'color': crop['color'],
        'info': crop['info'][_isKannada ? 'kn' : 'en'],
        'pests': crop['pests'][_isKannada ? 'kn' : 'en'],
      };
    }).toList();
  }

  // ---------- Navigation ----------
  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 1) {
      _openDetect();
    } else if (index == 2) {
      Navigator.pushNamed(context, '/settings');
    }
  }

  void _openDetect() {
    Navigator.pushNamed(context, '/detect');
  }

  // ---------- Image Picker ----------
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  // ---------- Show Crop Info Dialog ----------
  void _showCropInfo(Map<String, dynamic> crop) {
    final color = crop['color'] as Color;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.8), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        crop['icon'] as IconData,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        crop['name'] as String,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: color, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _translate('about')['about']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      crop['info'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.bug_report, color: color, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _translate('commonPestsTitle')['commonPestsTitle']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Text(
                        crop['pests'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Show Pest Info Dialog ----------
  void _showPestInfo(Map<String, String> pest) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Image.asset(
                      pest["img"]!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.bug_report, size: 64, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            pest["name"]!,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      pest["desc"]!,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _translate('detailedInfo')['detailedInfo']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      pest["details"]!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.medical_services_outlined, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _translate('treatment')['treatment']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              pest["treatment"]!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Weather Card ----------
  Widget _buildWeatherCard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1E3A5F), const Color(0xFF2E5984)]
                : [const Color(0xFF42A5F5), const Color(0xFF64B5F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: _isLoadingWeather
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            : _weatherError.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          _weatherError,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _fetchWeather,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                          ),
                          child: Text(_translate('retry')['retry']!),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _weatherData!['location'] ?? 'Unknown',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_weatherData!['temp'].round()}°',
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 8),
                                        Text(
                                          _getWeatherDescription(_weatherData!['weather_code'])
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_translate('feelsLike')['feelsLike']!} ${_weatherData!['feels_like'].round()}°',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [_buildWeatherDetail(
                                    Icons.water_drop,
                                    '${_weatherData!['humidity']}%',
                                    _translate('humidity')['humidity']!,
                                  ),
                                  const SizedBox(width: 20),
                                  _buildWeatherDetail(
                                    Icons.air,
                                    '${_weatherData!['wind_speed'].toStringAsFixed(1)} km/h',
                                    _translate('wind')['wind']!,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _getWeatherIcon(_weatherData!['weather_code']),
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------- UI BUILD ----------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0E0A) : const Color(0xFFF8FBF8);

    final filteredPests = _pests.where((pest) {
      final name = pest["name"]!.toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(isDark),
              const SizedBox(height: 24),
              _buildWeatherCard(isDark),
              const SizedBox(height: 24),
              _buildSearchBar(isDark),
              const SizedBox(height: 24),
              _buildCropSectionHeader(isDark),
              const SizedBox(height: 16),
              _buildCropList(isDark),
              const SizedBox(height: 32),
              _buildPestSectionHeader(isDark),
              const SizedBox(height: 16),
              _buildPestDetailsList(filteredPests, isDark),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  // ---------- Header ----------
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
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    height: 32,
                    width: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.eco,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _translate('appTitle')['appTitle']!,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _translate('tagline')['tagline']!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Language Toggle Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _isKannada = !_isKannada;
                    });
                  },
                  icon: Icon(
                    _isKannada ? Icons.language : Icons.translate,
                    color: Colors.white,
                    size: 24,
                  ),
                  tooltip: _isKannada ? 'Switch to English' : 'ಕನ್ನಡಕ್ಕೆ ಬದಲಿಸಿ',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _translate('tipText')['tipText']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Search Bar ----------
  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: _translate('searchHint')['searchHint']!,
            hintStyle: TextStyle(
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.green.shade600,
              size: 24,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Crop Section Header ----------
  Widget _buildCropSectionHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade100, Colors.green.shade50],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.agriculture,
              color: Colors.green.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _translate('crops')['crops']!,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          Text(
            _translate('tapForInfo')['tapForInfo']!,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Crop List ----------
  Widget _buildCropList(bool isDark) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _crops.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = _crops[index];
          final color = item['color'] as Color;

          return GestureDetector(
            onTap: () => _showCropInfo(item),
            child: SizedBox(
              width: 85,
              child: Column(
                children: [
                  Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.8), color],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['name'] as String,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------- Pest Section ----------
  Widget _buildPestSectionHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade100, Colors.red.shade50],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.bug_report,
              color: Colors.red.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _translate('commonPests')['commonPests']!,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          Text(
            _translate('tapForDetails')['tapForDetails']!,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPestDetailsList(List<Map<String, String>> pests, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: pests.map((pest) {
          return GestureDetector(
            onTap: () => _showPestInfo(pest),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.green.shade100.withOpacity(0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    pest["img"]!,
                    height: 65,
                    width: 65,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 65,
                      width: 65,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.bug_report, color: Colors.grey, size: 32),
                    ),
                  ),
                ),
                title: Text(
                  pest["name"]!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    pest["desc"]!,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.green.shade600,
                  size: 18,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------- Bottom Navigation ----------
  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color:
                isDark ? Colors.black.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: NavigationBar(
        selectedIndex: (_selectedIndex >= 0 && _selectedIndex < 3)
            ? _selectedIndex
            : 0,
        onDestinationSelected: _onTabTapped,
        height: 70,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        indicatorColor: Colors.green.shade100,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home, color: Colors.green),
            label: _translate('home')['home']!,
          ),
          NavigationDestination(
            icon: const Icon(Icons.camera_alt_outlined),
            selectedIcon: const Icon(Icons.camera_alt, color: Colors.green),
            label: _translate('detect')['detect']!,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings, color: Colors.green),
            label: _translate('settings')['settings']!,
          ),
        ],
      ),
    );
  }
}