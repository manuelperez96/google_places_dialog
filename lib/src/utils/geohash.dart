//ignore_for_file: parameter_assignments

/// A class that can convert a geohash String to [Longitude, Latitude] and back.
class GeoHasher {
  static const String _baseSequence = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Creates a reversed Map of available characters for a geohash
  final _base32MapR = <int, String>{
    for (var value in _baseSequence.split(''))
      _baseSequence.indexOf(value): value,
  };

  /// Converts a double value Longitude or Latitude to a List<int> of bits
  List<int> _doubleToBits({
    required double value,
    double lower = -90.0,
    double middle = 0.0,
    double upper = 90.0,
    int length = 15,
  }) {
    final ret = <int>[];

    for (var i = 0; i < length; i++) {
      if (value >= middle) {
        lower = middle;
        ret.add(1);
      } else {
        upper = middle;
        ret.add(0);
      }
      middle = (upper + lower) / 2;
    }

    return ret;
  }

  /// Converts a List<int> bits into a String geohash
  String _bitsToGeoHash(List<int> bitValue) {
    final geoHashList = <String>[];

    var remainingBits = List<int>.from(bitValue);
    var subBits = <int>[];
    StringBuffer subBitsAsString;
    for (var i = 0; i < bitValue.length / 5; i++) {
      subBits = remainingBits.sublist(0, 5);
      remainingBits = remainingBits.sublist(5);

      subBitsAsString = StringBuffer();
      for (final value in subBits) {
        subBitsAsString.write(value.toString());
      }

      final value = int.parse(
        int.parse(subBitsAsString.toString(), radix: 2).toRadixString(10),
      );
      geoHashList.add(_base32MapR[value]!);
    }

    return geoHashList.join();
  }

  /// Encodes a given Longitude and Latitude into a String geohash
  String encode(double longitude, double latitude, {int precision = 12}) {
    final originalPrecision = precision + 0;
    if (longitude < -180.0 || longitude > 180.0) {
      throw RangeError.range(longitude, -180, 180, 'Longitude');
    }
    if (latitude < -90.0 || latitude > 90.0) {
      throw RangeError.range(latitude, -90, 90, 'Latitude');
    }

    if ((precision % 2).isOdd) {
      precision = precision + 1;
    }
    if (precision != 1) {
      precision ~/= 2;
    }

    final longitudeBits = _doubleToBits(
      value: longitude,
      lower: -180,
      upper: 180,
      length: precision * 5,
    );
    final latitudeBits = _doubleToBits(
      value: latitude,
      length: precision * 5,
    );

    final ret = <int>[];
    for (var i = 0; i < longitudeBits.length; i++) {
      ret
        ..add(longitudeBits[i])
        ..add(latitudeBits[i]);
    }
    final geohashString = _bitsToGeoHash(ret);

    if (originalPrecision == 1) {
      return geohashString.substring(0, 1);
    }
    if ((originalPrecision % 2).isOdd) {
      return geohashString.substring(0, geohashString.length - 1);
    }
    return geohashString;
  }
}

/// A containing class for a geohash
abstract class GeoHash {
  /// Constructor given Longitude and Latitude
  static String fromCoordinates({
    required double longitude,
    required double latitude,
    int precision = 9,
  }) {
    return GeoHasher().encode(longitude, latitude, precision: precision);
  }
}
