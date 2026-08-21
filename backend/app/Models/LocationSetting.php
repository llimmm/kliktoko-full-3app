<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LocationSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'latitude',
        'longitude',
        'radius_meters',
        'is_active',
        'address',
        'city',
        'province'
    ];

    protected $casts = [
        'latitude' => 'decimal:8',
        'longitude' => 'decimal:8',
        'radius_meters' => 'integer',
        'is_active' => 'boolean'
    ];

    /**
     * Get the active location setting
     */
    public static function getActive()
    {
        return self::where('is_active', true)->first() ?? self::create([
            'name' => 'Office Location',
            'description' => 'Main office location for attendance',
            'latitude' => -6.753417,
            'longitude' => 110.843639,
            'radius_meters' => 50,
            'is_active' => true,
            'address' => 'Jl. Contoh No. 123',
            'city' => 'Semarang',
            'province' => 'Jawa Tengah'
        ]);
    }

    /**
     * Set as active location
     */
    public function setActive()
    {
        // Deactivate all other location settings
        self::where('id', '!=', $this->id)->update(['is_active' => false]);
        
        // Activate this location setting
        $this->update(['is_active' => true]);
    }

    /**
     * Calculate distance between two coordinates using Haversine formula
     */
    public function calculateDistance($lat2, $lon2)
    {
        $lat1 = (float) $this->latitude;
        $lon1 = (float) $this->longitude;
        
        $earthRadius = 6371000; // Earth's radius in meters
        
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);
        
        $a = sin($dLat/2) * sin($dLat/2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLon/2) * sin($dLon/2);
             
        $c = 2 * atan2(sqrt($a), sqrt(1-$a));
        
        return $earthRadius * $c; // Distance in meters
    }

    /**
     * Check if coordinates are within the allowed radius
     */
    public function isWithinRadius($latitude, $longitude)
    {
        $distance = $this->calculateDistance($latitude, $longitude);
        return $distance <= $this->radius_meters;
    }

    /**
     * Get coordinates in DMS format
     */
    public function getCoordinatesInDMS()
    {
        $lat = $this->latitude;
        $lon = $this->longitude;
        
        $latDirection = $lat >= 0 ? 'N' : 'S';
        $lonDirection = $lon >= 0 ? 'E' : 'W';
        
        $lat = abs($lat);
        $lon = abs($lon);
        
        $latDegrees = floor($lat);
        $latMinutes = floor(($lat - $latDegrees) * 60);
        $latSeconds = (($lat - $latDegrees) * 60 - $latMinutes) * 60;
        
        $lonDegrees = floor($lon);
        $lonMinutes = floor(($lon - $lonDegrees) * 60);
        $lonSeconds = (($lon - $lonDegrees) * 60 - $lonMinutes) * 60;
        
        return [
            'latitude_dms' => sprintf('%d°%d\'%.1f"%s', $latDegrees, $latMinutes, $latSeconds, $latDirection),
            'longitude_dms' => sprintf('%d°%d\'%.1f"%s', $lonDegrees, $lonMinutes, $lonSeconds, $lonDirection),
            'latitude_decimal' => $this->latitude,
            'longitude_decimal' => $this->longitude
        ];
    }

    /**
     * Get Google Maps URL
     */
    public function getGoogleMapsUrl()
    {
        return "https://www.google.com/maps?q={$this->latitude},{$this->longitude}";
    }

    /**
     * Get formatted address
     */
    public function getFormattedAddress()
    {
        $parts = array_filter([$this->address, $this->city, $this->province]);
        return implode(', ', $parts);
    }
}