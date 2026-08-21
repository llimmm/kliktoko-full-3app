# Location Management API

API untuk mengelola lokasi kantor dan radius attendance untuk Flutter app.

## 📍 Overview

Sistem ini memungkinkan konfigurasi lokasi kantor dan radius untuk attendance tracking. Berdasarkan hardcode Flutter yang ada:

```dart
// Koordinat kantor (6°45'12.3"S 110°50′37.1"E)
static const double officeLatitude = -6.753417;  // 6°45'12.3"S
static const double officeLongitude = 110.843639; // 110°50′37.1"E
static const double radiusInMeters = 50.0; // 50 meter radius
```

## 🚀 API Endpoints

### 1. Get Active Location (Public)
**GET** `/api/location/active`

Mendapatkan lokasi aktif untuk attendance.

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Office Location",
    "description": "Main office location for attendance tracking",
    "latitude": -6.753417,
    "longitude": 110.843639,
    "radius_meters": 50,
    "address": "Jl. Contoh No. 123",
    "city": "Semarang",
    "province": "Jawa Tengah",
    "coordinates_dms": {
      "latitude_dms": "6°45'12.3\"S",
      "longitude_dms": "110°50'37.1\"E",
      "latitude_decimal": -6.753417,
      "longitude_decimal": 110.843639
    },
    "google_maps_url": "https://www.google.com/maps?q=-6.753417,110.843639",
    "formatted_address": "Jl. Contoh No. 123, Semarang, Jawa Tengah"
  }
}
```

### 2. Check Location (Public)
**POST** `/api/location/check`

Memeriksa apakah koordinat user berada dalam radius yang diizinkan.

**Request Body:**
```json
{
  "latitude": -6.753417,
  "longitude": 110.843639
}
```

**Alternative GET Method (for testing):**
**GET** `/api/location/check/{latitude}/{longitude}`

Contoh: `/api/location/check/-6.753417/110.843639`

**Response:**
```json
{
  "success": true,
  "data": {
    "is_within_radius": true,
    "distance_meters": 25.5,
    "allowed_radius_meters": 50,
    "user_coordinates": {
      "latitude": -6.753417,
      "longitude": 110.843639
    },
    "office_coordinates": {
      "latitude": -6.753417,
      "longitude": 110.843639
    },
    "office_info": {
      "name": "Office Location",
      "address": "Jl. Contoh No. 123, Semarang, Jawa Tengah",
      "google_maps_url": "https://www.google.com/maps?q=-6.753417,110.843639"
    }
  }
}
```

### 3. Get All Locations (Protected)
**GET** `/api/location/all`

Mendapatkan semua lokasi yang dikonfigurasi.

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Office Location",
      "description": "Main office location for attendance tracking",
      "latitude": -6.753417,
      "longitude": 110.843639,
      "radius_meters": 50,
      "is_active": true,
      "address": "Jl. Contoh No. 123",
      "city": "Semarang",
      "province": "Jawa Tengah",
      "coordinates_dms": {
        "latitude_dms": "6°45'12.3\"S",
        "longitude_dms": "110°50'37.1\"E"
      },
      "google_maps_url": "https://www.google.com/maps?q=-6.753417,110.843639",
      "formatted_address": "Jl. Contoh No. 123, Semarang, Jawa Tengah",
      "created_at": "2025-09-12 07:06:23",
      "updated_at": "2025-09-12 07:06:23"
    }
  ]
}
```

### 4. Update Location (Protected)
**PUT** `/api/location/{id}/update`

Update lokasi tertentu.

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "name": "New Office Location",
  "description": "Updated office location",
  "latitude": -6.753417,
  "longitude": 110.843639,
  "radius_meters": 75,
  "address": "Jl. Baru No. 456",
  "city": "Semarang",
  "province": "Jawa Tengah",
  "is_active": true
}
```

**Response:**
```json
{
  "success": true,
  "message": "Location setting updated successfully",
  "data": {
    "id": 1,
    "name": "New Office Location",
    "description": "Updated office location",
    "latitude": -6.753417,
    "longitude": 110.843639,
    "radius_meters": 75,
    "is_active": true,
    "address": "Jl. Baru No. 456",
    "city": "Semarang",
    "province": "Jawa Tengah",
    "coordinates_dms": {
      "latitude_dms": "6°45'12.3\"S",
      "longitude_dms": "110°50'37.1\"E"
    },
    "google_maps_url": "https://www.google.com/maps?q=-6.753417,110.843639",
    "formatted_address": "Jl. Baru No. 456, Semarang, Jawa Tengah"
  }
}
```

## 🎯 Flutter Integration

### 1. Replace Hardcode dengan API Call

**Before (Hardcode):**
```dart
class LocationService {
  static const double officeLatitude = -6.753417;
  static const double officeLongitude = 110.843639;
  static const double radiusInMeters = 50.0;
  
  static bool isWithinOfficeRadius(double userLat, double userLng) {
    // Hardcode calculation
  }
}
```

**After (Dynamic dari API):**
```dart
class LocationService {
  static OfficeLocation? _officeLocation;
  
  static Future<OfficeLocation> getActiveLocation() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/location/active'),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _officeLocation = OfficeLocation.fromJson(data['data']);
      return _officeLocation!;
    }
    throw Exception('Failed to load office location');
  }
  
  static Future<bool> checkLocation(double userLat, double userLng) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/location/check'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'latitude': userLat,
        'longitude': userLng,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']['is_within_radius'];
    }
    throw Exception('Failed to check location');
  }
}
```

### 2. Model Class untuk Flutter

```dart
class OfficeLocation {
  final int id;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final String? address;
  final String? city;
  final String? province;
  final bool isActive;
  
  OfficeLocation({
    required this.id,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.address,
    this.city,
    this.province,
    required this.isActive,
  });
  
  factory OfficeLocation.fromJson(Map<String, dynamic> json) {
    return OfficeLocation(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      radiusMeters: json['radius_meters'],
      address: json['address'],
      city: json['city'],
      province: json['province'],
      isActive: json['is_active'],
    );
  }
}
```

### 3. Attendance Check Implementation

```dart
class AttendanceService {
  static Future<bool> canCheckIn(LocationData userLocation) async {
    try {
      final isWithinRadius = await LocationService.checkLocation(
        userLocation.latitude!,
        userLocation.longitude!,
      );
      
      return isWithinRadius;
    } catch (e) {
      print('Error checking location: $e');
      return false;
    }
  }
  
  static Future<void> checkIn() async {
    final location = await LocationService.getCurrentLocation();
    final canCheckIn = await AttendanceService.canCheckIn(location);
    
    if (canCheckIn) {
      // Proceed with check-in
      await performCheckIn(location);
    } else {
      throw Exception('You are not within the office radius');
    }
  }
}
```

## 🔧 Web Admin Features

### 1. Location Management Page
- **URL:** `/location`
- **Features:**
  - View active location
  - Add new locations
  - Edit existing locations
  - Set active location
  - Delete inactive locations
  - View on Google Maps

### 2. Location Configuration
- **Coordinates:** Decimal degrees (-90 to 90 for latitude, -180 to 180 for longitude)
- **DMS Format:** Automatically converted and displayed
- **Radius:** 1 to 10,000 meters
- **Address:** Optional address information
- **Google Maps Integration:** Direct links to view locations

### 3. Real-time Updates
- Changes in web admin immediately affect Flutter app
- No need to update app for location changes
- Multiple location support for different offices

## 📊 Database Schema

```sql
CREATE TABLE location_settings (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) DEFAULT 'Office Location',
    description VARCHAR(255) NULL,
    latitude DECIMAL(10,8) DEFAULT -6.753417,
    longitude DECIMAL(11,8) DEFAULT 110.843639,
    radius_meters INT DEFAULT 50,
    is_active BOOLEAN DEFAULT TRUE,
    address VARCHAR(255) NULL,
    city VARCHAR(255) NULL,
    province VARCHAR(255) NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
);
```

## 🚀 Benefits

1. **Dynamic Configuration:** No more hardcode coordinates in Flutter
2. **Multiple Locations:** Support for multiple office locations
3. **Easy Management:** Web admin interface for non-technical users
4. **Real-time Updates:** Changes apply immediately
5. **Google Maps Integration:** Visual location management
6. **Flexible Radius:** Adjustable attendance radius
7. **Address Management:** Complete location information

## 🔒 Security

- Public endpoints for location checking (no authentication required)
- Protected endpoints for location management (authentication required)
- Input validation for coordinates and radius
- Error handling and logging

## 📱 Flutter App Flow

1. **App Start:** Fetch active location from API
2. **Location Check:** Before attendance, check if user is within radius
3. **Attendance:** Allow/deny based on location check result
4. **Error Handling:** Graceful fallback if API is unavailable

This system replaces the hardcoded location values in your Flutter app with a dynamic, web-manageable solution!
