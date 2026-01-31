import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'auth_service.dart';

class ApiService {
  // 1. Upload Document for OCR
  static Future<Map<String, dynamic>> scanDocument(String filePath) async {
    var request = http.MultipartRequest('POST', Uri.parse(Config.scanDoc));

    // Attach the file
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    // Send
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('OCR Failed: ${response.body}');
    }
  }

  // 2. Fetch Dashboard Data (Aggregator)
  static Future<Map<String, dynamic>> getDashboardData() async {
    final userId = AuthService().userId;
    if (userId.isEmpty) throw Exception('User not logged in');

    final response = await http.get(
      Uri.parse('${Config.dashboard}?userId=$userId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load dashboard');
    }
  }

  // 3. Submit Lead (Cash Back / Refinance)
  static Future<void> submitLead(
    String type,
    Map<String, dynamic> payload,
  ) async {
    final userId = AuthService().userId;

    final response = await http.post(
      Uri.parse(Config.submitLead),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'type': type, // 'trade_in', 'cash_back', 'refinance'
        'payload': payload,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit lead');
    }
  }

  // 4. Fetch Inventory
  static Future<List<dynamic>> getInventory() async {
    final response = await http.get(Uri.parse(Config.inventory));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return []; // Return empty list on failure for now
    }
  }

  // 5. Fetch Vehicle Options (Cascading Dropdowns)
  static Future<List<String>> getVehicleOptions({
    required String type, // 'years', 'makes', 'models', 'trims'
    String? year,
    String? make,
    String? model,
  }) async {
    // Build the query string
    String url = '${Config.baseUrl}/api/vehicle-options?type=$type';
    if (year != null) url += '&year=$year';
    if (make != null) url += '&make=$make';
    if (model != null) url += '&model=$model';

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        // Convert [2023, 2022] to ["2023", "2022"]
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e.toString()).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("Error fetching vehicle options: $e");
      return [];
    }
  }

  // 6. Get Market Value Estimate
  static Future<Map<String, dynamic>> getEstimate({
    required int year,
    required String make,
    required String model,
    String? trim,
    int? mileage,
  }) async {
    final response = await http.post(
      Uri.parse(Config.estimateValue),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'year': year,
        'make': make,
        'model': model,
        'trim': trim,
        'mileage': mileage,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get estimate: ${response.body}');
    }
  }
}
