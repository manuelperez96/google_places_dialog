import 'package:flutter/foundation.dart';

@immutable
class GoogleSingleAddress {
  const GoogleSingleAddress({
    required this.reference,
    required this.name,
  });

  final String name;
  final String reference;

  @override
  bool operator ==(Object other) =>
      other is GoogleSingleAddress &&
      other.runtimeType == runtimeType &&
      other.reference == reference &&
      other.name == name;

  @override
  int get hashCode => reference.hashCode + name.hashCode;
}

class GoogleAddress extends GoogleSingleAddress {
  const GoogleAddress({
    required super.reference,
    required super.name,
    required this.lat,
    required this.lng,
    required this.geohash,
  });

  final double lat;
  final double lng;
  final String geohash;

  @override
  bool operator ==(Object other) =>
      other is GoogleAddress &&
      other.runtimeType == runtimeType &&
      other.reference == reference &&
      other.name == name &&
      other.lat == lat &&
      other.lng == lng &&
      other.geohash == geohash;

  @override
  int get hashCode =>
      reference.hashCode +
      name.hashCode +
      lat.hashCode +
      lng.hashCode +
      geohash.hashCode;

  @override
  String toString() {
    return 'reference: $reference\nName: $name\nlat: $lat\n'
        'lng: $lng\ngeohash: $geohash';
  }
}
