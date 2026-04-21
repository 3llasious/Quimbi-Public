class LocationModel {
  final int id;
  final String label;
  final String? address;
  final double? latitude;
  final double? longitude;

  const LocationModel({
    required this.id,
    required this.label,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      id: map['id'] as int,
      label: map['label'] as String,
      address: map['address'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
