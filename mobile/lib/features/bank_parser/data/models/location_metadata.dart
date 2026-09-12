class LocationMetadata {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime capturedAt;
  final String source;
  final String? placeName;
  final String? city;
  final String? district;
  final double? locationConfidence;

  LocationMetadata({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    DateTime? capturedAt,
    this.source = 'DEVICE',
    this.placeName,
    this.city,
    this.district,
    this.locationConfidence,
  }) : capturedAt = capturedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'capturedAt': capturedAt.toIso8601String(),
        'source': source,
        'placeName': placeName,
        'city': city,
        'district': district,
        'locationConfidence': locationConfidence,
      };

  factory LocationMetadata.fromJson(Map<String, dynamic> json) => LocationMetadata(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        capturedAt: DateTime.tryParse(json['capturedAt'] as String? ?? '') ?? DateTime.now(),
        source: json['source'] as String? ?? 'DEVICE',
        placeName: json['placeName'] as String?,
        city: json['city'] as String?,
        district: json['district'] as String?,
        locationConfidence: (json['locationConfidence'] as num?)?.toDouble(),
      );
}