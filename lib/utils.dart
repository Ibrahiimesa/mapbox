import 'dart:convert';

import 'package:http/http.dart' as http;

Future<List<dynamic>> fetchSearchResults(String query) async {
  final accessToken =
      "";

  final url =
      'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=$accessToken';

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['features'];
    } else {
      throw Exception("Failed to fetch search results: ${response.statusCode}");
    }
  } catch (e) {
    throw Exception("Error during search: $e");
  }
}
