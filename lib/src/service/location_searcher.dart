import 'dart:convert';

import 'package:google_places_dialog/google_places_dialog.dart';
import 'package:http/http.dart' as http;

class SearchAutocompleteException implements Exception {}

class SearchDetailException implements Exception {}

class SearchException implements Exception {}

class AddressSearcherClient {
  AddressSearcherClient({
    required String apiKey,
    required String language,
  })  : assert(
          apiKey.trim().isNotEmpty,
          'ApiKey can not be empty',
        ),
        _language = language,
        _apiKey = apiKey;

  final String _apiKey;
  final String _language;

  static const _authority = 'maps.googleapis.com';
  static const _autocompleteEndPoint = '/maps/api/place/autocomplete/json';
  static const _detailEndPoint = '/maps/api/place/details/json';

  Future<List<GoogleAddress>> searchAddressByQuery(String query) async {
    if (query.trim().isEmpty) return List.empty();
    final client = http.Client();
    try {
      final tinyAddressess = await _searchAutocompletePlaces(client, query);
      return await _getPlacesGeometry(client, tinyAddressess);
    } catch (_) {
      throw SearchException();
    } finally {
      client.close();
    }
  }

  Future<List<GoogleSingleAddress>> _searchAutocompletePlaces(
    http.Client client,
    String query,
  ) async {
    final url = _buildAutocompleteUrl(query);
    try {
      final response = await client.get(url);
      final decodedResponse =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      final predictions = decodedResponse['predictions'] as List;
      final castedPredictions = List.castFrom<dynamic, Map<String, dynamic>>(
        predictions,
      );

      return castedPredictions.map(
        (e) {
          return GoogleSingleAddress(
            reference: e['place_id'] as String,
            name: e['description'] as String,
          );
        },
      ).toList();
    } catch (_) {
      throw SearchAutocompleteException();
    }
  }

  Uri _buildAutocompleteUrl(String query) {
    return Uri.https(
      _authority,
      _autocompleteEndPoint,
      _buildQueryParameters(query),
    );
  }

  Map<String, dynamic> _buildQueryParameters(String query) {
    return <String, String>{
      'key': _apiKey,
      'language': _language,
      'input': query,
    };
  }

  Future<List<GoogleAddress>> _getPlacesGeometry(
    http.Client client,
    List<GoogleSingleAddress> places,
  ) async {
    try {
      final futureAddresses = places.map(
        (place) => _getPlaceGeometry(client, place),
      );
      return Future.wait(futureAddresses, eagerError: true);
    } catch (_) {
      throw SearchDetailException();
    }
  }

  Future<GoogleAddress> _getPlaceGeometry(
    http.Client client,
    GoogleSingleAddress place,
  ) async {
    final uri = _buildDetailQuery(place);

    final response = await client.get(uri);
    final decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
    final geometry = (decodedResponse['result'] as Map)['geometry'] as Map;
    final location = geometry['location'] as Map;
    final lat = double.parse(location['lat'].toString());
    final lng = double.parse(location['lng'].toString());
    return GoogleAddress(
      name: place.name,
      reference: place.reference,
      lat: lat,
      lng: lng,
      geohash: GeoHash.fromCoordinates(latitude: lat, longitude: lng),
    );
  }

  Uri _buildDetailQuery(GoogleSingleAddress place) {
    return Uri.https(
      _authority,
      _detailEndPoint,
      {
        'place_id': place.reference,
        'fields': 'geometry',
        'key': _apiKey,
      },
    );
  }
}
