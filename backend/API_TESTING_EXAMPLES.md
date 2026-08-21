# 🧪 API Testing Examples

## 📍 Location API Testing

### 1. Get Active Location
```bash
# Test dengan curl
curl -X GET "http://localhost:8000/api/location/active"

# Atau dengan browser
http://localhost:8000/api/location/active
```

**Expected Response:**
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

### 2. Check Location (POST Method)
```bash
# Test dengan curl
curl -X POST "http://localhost:8000/api/location/check" \
  -H "Content-Type: application/json" \
  -d '{
    "latitude": -6.753417,
    "longitude": 110.843639
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "is_within_radius": true,
    "distance_meters": 0,
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

### 3. Check Location (GET Method - untuk testing)
```bash
# Test dengan curl
curl -X GET "http://localhost:8000/api/location/check/-6.753417/110.843639"

# Atau dengan browser
http://localhost:8000/api/location/check/-6.753417/110.843639
```

**Expected Response:** (sama dengan POST method)

### 4. Test dengan koordinat yang jauh (di luar radius)
```bash
# Test dengan koordinat Jakarta (jauh dari Semarang)
curl -X GET "http://localhost:8000/api/location/check/-6.2088/106.8456"

# Atau dengan POST
curl -X POST "http://localhost:8000/api/location/check" \
  -H "Content-Type: application/json" \
  -d '{
    "latitude": -6.2088,
    "longitude": 106.8456
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "is_within_radius": false,
    "distance_meters": 432500.25,
    "allowed_radius_meters": 50,
    "user_coordinates": {
      "latitude": -6.2088,
      "longitude": 106.8456
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

## 🔧 JavaScript Testing (untuk Flutter simulation)

```javascript
// Test dengan fetch API
async function testLocationAPI() {
  try {
    // 1. Get active location
    const locationResponse = await fetch('http://localhost:8000/api/location/active');
    const locationData = await locationResponse.json();
    console.log('Active Location:', locationData);
    
    // 2. Check location (POST)
    const checkResponse = await fetch('http://localhost:8000/api/location/check', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        latitude: -6.753417,
        longitude: 110.843639
      })
    });
    const checkData = await checkResponse.json();
    console.log('Location Check:', checkData);
    
    // 3. Check location (GET)
    const checkGetResponse = await fetch('http://localhost:8000/api/location/check/-6.753417/110.843639');
    const checkGetData = await checkGetResponse.json();
    console.log('Location Check (GET):', checkGetData);
    
  } catch (error) {
    console.error('Error:', error);
  }
}

// Run test
testLocationAPI();
```

## 📱 Flutter Testing

```dart
// Test dengan http package
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationAPITest {
  static const String baseUrl = 'http://localhost:8000/api';
  
  // Test get active location
  static Future<Map<String, dynamic>> getActiveLocation() async {
    final response = await http.get(Uri.parse('$baseUrl/location/active'));
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load location');
    }
  }
  
  // Test check location (POST)
  static Future<Map<String, dynamic>> checkLocation(double lat, double lng) async {
    final response = await http.post(
      Uri.parse('$baseUrl/location/check'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'latitude': lat,
        'longitude': lng,
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to check location');
    }
  }
  
  // Test check location (GET)
  static Future<Map<String, dynamic>> checkLocationGet(double lat, double lng) async {
    final response = await http.get(
      Uri.parse('$baseUrl/location/check/$lat/$lng'),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to check location');
    }
  }
}

// Usage
void main() async {
  try {
    // Test get active location
    final location = await LocationAPITest.getActiveLocation();
    print('Active Location: $location');
    
    // Test check location (POST)
    final checkPost = await LocationAPITest.checkLocation(-6.753417, 110.843639);
    print('Check Location (POST): $checkPost');
    
    // Test check location (GET)
    final checkGet = await LocationAPITest.checkLocationGet(-6.753417, 110.843639);
    print('Check Location (GET): $checkGet');
    
  } catch (e) {
    print('Error: $e');
  }
}
```

## 🚨 Common Issues & Solutions

### 1. "The GET method is not supported for route api/location/check"
**Problem:** Mencoba akses `/api/location/check` dengan GET method
**Solution:** 
- Gunakan POST method: `POST /api/location/check`
- Atau gunakan GET method: `GET /api/location/check/{lat}/{lng}`

### 2. "Route not found"
**Problem:** Route belum terdaftar
**Solution:** 
```bash
php artisan route:clear
php artisan route:cache
```

### 3. "Database connection error"
**Problem:** Database belum di-migrate
**Solution:**
```bash
php artisan migrate
php artisan db:seed --class=LocationSettingSeeder
```

### 4. "CORS error" (untuk testing dari browser)
**Problem:** CORS policy blocking request
**Solution:** Install CORS package atau test dengan Postman/curl

## ✅ Testing Checklist

- [ ] Get active location endpoint working
- [ ] Check location (POST) endpoint working  
- [ ] Check location (GET) endpoint working
- [ ] Coordinates validation working
- [ ] Distance calculation accurate
- [ ] Radius check working correctly
- [ ] Error handling working
- [ ] Response format correct

## 🎯 Test Coordinates

**Office Location (Semarang):**
- Latitude: -6.753417
- Longitude: 110.843639
- Radius: 50 meters

**Test Coordinates:**
1. **Exact office location:** -6.753417, 110.843639 (should be within radius)
2. **Near office (within 50m):** -6.753500, 110.843700 (should be within radius)
3. **Far from office:** -6.2088, 106.8456 (Jakarta - should be outside radius)
4. **Invalid coordinates:** 999, 999 (should return error)

