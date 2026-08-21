import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../APIService/ApiService.dart';

class LocationService {
  // Fallback koordinat kantor (6°45'12.3"S 110°50'37.1"E)
  static const double _fallbackOfficeLatitude = -6.753417; // 6°45'12.3"S
  static const double _fallbackOfficeLongitude = 110.843639; // 110°50'37.1"E
  static const double _fallbackRadiusInMeters = 50.0; // 50 meter radius

  // Dynamic values from API
  double _officeLatitude = _fallbackOfficeLatitude;
  double _officeLongitude = _fallbackOfficeLongitude;
  double _radiusInMeters = _fallbackRadiusInMeters;
  String _locationName = 'Kantor';
  String _locationAddress = 'Jl. Raya Kudus-Pati, Kudus, Jawa Tengah';
  bool _isApiDataLoaded = false;

  final ApiService _apiService = ApiService();

  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Getters for current values
  double get officeLatitude => _officeLatitude;
  double get officeLongitude => _officeLongitude;
  double get radiusInMeters => _radiusInMeters;
  String get locationName => _locationName;
  String get locationAddress => _locationAddress;
  bool get isApiDataLoaded => _isApiDataLoaded;

  // Load location data from API
  Future<void> loadLocationFromAPI() async {
    try {
      print('📍 Loading location data from API...');

      final response = await _apiService.getActiveLocation();

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];

        // Update location data from API
        _officeLatitude =
            (data['latitude'] ?? _fallbackOfficeLatitude).toDouble();
        _officeLongitude =
            (data['longitude'] ?? _fallbackOfficeLongitude).toDouble();
        _radiusInMeters =
            (data['radius_meters'] ?? _fallbackRadiusInMeters).toDouble();
        _locationName = data['name'] ?? 'Kantor';
        _locationAddress = data['formatted_address'] ??
            data['address'] ??
            'Jl. Raya Kudus-Pati, Kudus, Jawa Tengah';
        _isApiDataLoaded = true;

        print('✅ Location data loaded from API:');
        print('   📍 Name: $_locationName');
        print('   📍 Coordinates: $_officeLatitude, $_officeLongitude');
        print('   📍 Radius: $_radiusInMeters meters');
        print('   📍 Address: $_locationAddress');
      } else {
        print('⚠️ Failed to load location from API, using fallback values');
        _useFallbackValues();
      }
    } catch (e) {
      print('❌ Error loading location from API: $e');
      _useFallbackValues();
    }
  }

  // Use fallback values when API fails
  void _useFallbackValues() {
    _officeLatitude = _fallbackOfficeLatitude;
    _officeLongitude = _fallbackOfficeLongitude;
    _radiusInMeters = _fallbackRadiusInMeters;
    _locationName = 'Kantor';
    _locationAddress = 'Jl. Raya Kudus-Pati, Kudus, Jawa Tengah';
    _isApiDataLoaded = false;
  }

  // Check if location permission is granted
  Future<bool> checkLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location service is disabled');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        print('📍 Requesting location permission...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permission denied forever');
        return false;
      }

      print('✅ Location permission granted');
      return true;
    } catch (e) {
      print('❌ Error checking location permission: $e');
      return false;
    }
  }

  // Get current location with force fresh and better error handling
  Future<Position?> getCurrentLocation() async {
    try {
      if (!await checkLocationPermission()) {
        return null;
      }

      print('📍 Getting current location (FORCE FRESH)...');

      // Force fresh location by using best accuracy and longer timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 20),
        forceAndroidLocationManager: false, // Use GPS for better accuracy
      );

      print('✅ Current location: ${position.latitude}, ${position.longitude}');
      print('📍 Accuracy: ${position.accuracy.toStringAsFixed(2)} meters');
      print(
          '📍 Timestamp: ${DateTime.fromMillisecondsSinceEpoch(position.timestamp.millisecondsSinceEpoch)}');

      return position;
    } catch (e) {
      print('❌ Error getting current location: $e');
      return null;
    }
  }

  // Check if user is within radius with improved logic and detailed logging
  Future<bool> isWithinRadius() async {
    try {
      print('🎯 Checking radius with detailed logging...');
      print('🏢 Office coordinates: $_officeLatitude, $_officeLongitude');
      print('🎯 Radius limit: $_radiusInMeters meters');
      print('📍 Location name: $_locationName');

      final currentPosition = await getCurrentLocation();

      if (currentPosition == null) {
        print('❌ Cannot get current position');
        return false;
      }

      final distance = Geolocator.distanceBetween(
        _officeLatitude,
        _officeLongitude,
        currentPosition.latitude,
        currentPosition.longitude,
      );

      print(
          '📍 Current location: ${currentPosition.latitude}, ${currentPosition.longitude}');
      print('📏 Calculated distance: ${distance.toStringAsFixed(2)} meters');
      print('🎯 Radius limit: $_radiusInMeters meters');
      print('✅ Within radius: ${distance <= _radiusInMeters}');
      print(
          '📊 Distance difference: ${(distance - _radiusInMeters).toStringAsFixed(2)} meters');

      // Additional validation
      if (distance < 0) {
        print(
            '⚠️ Warning: Negative distance calculated, this might indicate an error');
        return false;
      }

      if (distance > 10000) {
        // More than 10km - likely error
        print(
            '⚠️ Warning: Distance too large (${distance.toStringAsFixed(2)}m), might be GPS error');
        return false;
      }

      return distance <= _radiusInMeters;
    } catch (e) {
      print('❌ Error checking radius: $e');
      return false;
    }
  }

  // Get distance to office in meters with validation
  Future<double?> getDistanceToOffice() async {
    try {
      final currentPosition = await getCurrentLocation();
      if (currentPosition == null) {
        return null;
      }

      final distance = Geolocator.distanceBetween(
        _officeLatitude,
        _officeLongitude,
        currentPosition.latitude,
        currentPosition.longitude,
      );

      print('📏 Distance to office: ${distance.toStringAsFixed(2)} meters');
      return distance;
    } catch (e) {
      print('❌ Error getting distance: $e');
      return null;
    }
  }

  // Get formatted address from coordinates
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.subLocality}, ${place.locality}';
      }
      return 'Unknown location';
    } catch (e) {
      print('❌ Error getting address: $e');
      return 'Unknown location';
    }
  }

  // Get office address
  String getOfficeAddress() {
    return _locationAddress;
  }

  // Get radius info for display
  Map<String, dynamic> getRadiusInfo() {
    return {
      'officeLatitude': _officeLatitude,
      'officeLongitude': _officeLongitude,
      'radiusInMeters': _radiusInMeters,
      'officeAddress': _locationAddress,
      'locationName': _locationName,
      'isApiDataLoaded': _isApiDataLoaded,
    };
  }

  // Test method untuk debugging dengan detail lengkap
  Future<void> testLocation() async {
    print('🧪 Testing location service with detailed info...');
    print('🏢 Office: $_officeLatitude, $_officeLongitude');
    print('🎯 Radius: $_radiusInMeters meters');
    print('📍 Location: $_locationName');
    print('📍 Address: $_locationAddress');
    print('📍 API Data Loaded: $_isApiDataLoaded');
    print('⏰ Test time: ${DateTime.now()}');

    final hasPermission = await checkLocationPermission();
    print('📍 Has permission: $hasPermission');

    if (hasPermission) {
      final position = await getCurrentLocation();
      if (position != null) {
        final distance = await getDistanceToOffice();
        print('📏 Distance to office: ${distance?.toStringAsFixed(2)} meters');

        final isWithin = await isWithinRadius();
        print('✅ Is within radius: $isWithin');

        // Additional info
        print(
            '📍 Position accuracy: ${position.accuracy.toStringAsFixed(2)} meters');
        print(
            '📍 Position timestamp: ${DateTime.fromMillisecondsSinceEpoch(position.timestamp.millisecondsSinceEpoch)}');
        print(
            '📍 Position altitude: ${position.altitude.toStringAsFixed(2)} meters');
        print('📍 Position speed: ${position.speed.toStringAsFixed(2)} m/s');
      }
    }
  }

  // Debug method untuk memeriksa status permission dan location
  Future<Map<String, dynamic>> debugLocationStatus() async {
    try {
      print('🔍 Debugging location status with detailed info...');
      print('⏰ Debug time: ${DateTime.now()}');

      // Check location service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('📍 Location service enabled: $serviceEnabled');

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      print('🔐 Current permission: $permission');

      // Check if we can get location
      Position? position;
      try {
        print('📍 Attempting to get fresh position...');
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 15),
          forceAndroidLocationManager: false,
        );
        print(
            '✅ Successfully got position: ${position.latitude}, ${position.longitude}');
        print(
            '📍 Position accuracy: ${position.accuracy.toStringAsFixed(2)} meters');
        print(
            '📍 Position timestamp: ${DateTime.fromMillisecondsSinceEpoch(position.timestamp.millisecondsSinceEpoch)}');
      } catch (e) {
        print('❌ Failed to get position: $e');
      }

      // Calculate distance if position available
      double? distance;
      if (position != null) {
        distance = Geolocator.distanceBetween(
          _officeLatitude,
          _officeLongitude,
          position.latitude,
          position.longitude,
        );
        print('📏 Distance to office: ${distance.toStringAsFixed(2)} meters');
        print('🎯 Radius limit: $_radiusInMeters meters');
        print('✅ Within radius: ${distance <= _radiusInMeters}');
      }

      return {
        'serviceEnabled': serviceEnabled,
        'permission': permission.toString(),
        'hasPosition': position != null,
        'position': position != null
            ? {
                'latitude': position.latitude,
                'longitude': position.longitude,
                'accuracy': position.accuracy,
                'timestamp': position.timestamp.millisecondsSinceEpoch,
              }
            : null,
        'distance': distance,
        'isWithinRadius':
            distance != null ? distance <= _radiusInMeters : false,
        'radiusLimit': _radiusInMeters,
        'officeCoordinates': {
          'latitude': _officeLatitude,
          'longitude': _officeLongitude,
        },
        'locationName': _locationName,
        'locationAddress': _locationAddress,
        'isApiDataLoaded': _isApiDataLoaded,
      };
    } catch (e) {
      print('❌ Error in debugLocationStatus: $e');
      return {
        'error': e.toString(),
      };
    }
  }
}
