import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'auth_service.dart';

class ApiService {
  // 1. Upload Document for OCR
  static Future<Map<String, dynamic>> scanDocument(
    String filePath, {
    String? userId,
    String? loanId,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse(Config.scanDoc));

    // Attach the file
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    // Attach IDs if available
    if (userId != null) request.fields['userId'] = userId;
    if (loanId != null) request.fields['loanId'] = loanId;

    debugPrint("[SCAN] Uploading for OCR: $filePath");
    debugPrint("[SCAN] IDs: userId=$userId, loanId=$loanId");

    // Send
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    debugPrint("[SCAN] Response Code: ${response.statusCode}");

    if (response.statusCode == 200) {
      debugPrint("[SCAN] Success: ${response.body}");
      return jsonDecode(response.body);
    } else {
      debugPrint("[SCAN] Failed: ${response.body}");
      throw Exception('OCR Failed: ${response.body}');
    }
  }

  // 1b. Decode VIN using NHTSA vPIC
  static Future<Map<String, String>> decodeVin(String vin) async {
    final normalized = vin
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    if (normalized.length != 17) {
      return {};
    }

    final url = Uri.parse(
      'https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVinValuesExtended/$normalized?format=json',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        return {};
      }

      final data = jsonDecode(response.body);
      final results = data['Results'];
      if (results is! List || results.isEmpty) {
        return {};
      }

      final first = results.first as Map<String, dynamic>;
      final year = (first['ModelYear'] ?? '').toString().trim();
      final make = (first['Make'] ?? '').toString().trim();
      final model = (first['Model'] ?? '').toString().trim();

      if (year.isEmpty && make.isEmpty && model.isEmpty) {
        return {};
      }

      return {'year': year, 'make': make, 'model': model};
    } catch (e) {
      debugPrint("VIN decode error: $e");
      return {};
    }
  }

  // 1c. Mark loan verification status in PocketBase
  static Future<void> setLoanVerification({required bool isVerified}) async {
    final auth = AuthService();
    if (!auth.isAuthenticated) return;

    final userId = auth.userId;
    if (userId.isEmpty) return;

    try {
      final vehicles = await auth.pb
          .collection('vehicles')
          .getList(page: 1, perPage: 1, filter: 'user_id = "$userId"');
      if (vehicles.items.isEmpty) return;

      final vehicleId = vehicles.items.first.id;
      final loans = await auth.pb
          .collection('loans')
          .getList(page: 1, perPage: 1, filter: 'vehicle_id = "$vehicleId"');
      if (loans.items.isEmpty) return;

      final loanId = loans.items.first.id;
      await auth.pb
          .collection('loans')
          .update(loanId, body: {'is_verified': isVerified});
    } catch (e) {
      debugPrint("Error updating loan verification: $e");
    }
  }

  // 1d. Sync all onboarding data (Vehicle + Loan) to PocketBase
  static Future<void> syncOnboardingData({
    required Map<String, String> carDetails,
    required Map<String, dynamic> scanData,
    required double estimatedValue,
    required bool isVerified,
    String? documentId,
  }) async {
    final auth = AuthService();
    if (!auth.isAuthenticated) return;

    final userId = auth.userId;
    if (userId.isEmpty) return;

    debugPrint("[SYNC] Starting Onboarding Data Sync...");
    debugPrint("[SYNC] Car Details: $carDetails");
    debugPrint("[SYNC] Scan Data: $scanData");

    try {
      // 1. Check/Create Vehicle
      final vehicles = await auth.pb
          .collection('vehicles')
          .getList(page: 1, perPage: 1, filter: 'user_id = "$userId"');

      String vehicleId;
      final vehicleBody = {
        'user_id': userId,
        'year': int.tryParse(carDetails['year'] ?? '') ?? 0,
        'make': carDetails['make'] ?? '',
        'model': carDetails['model'] ?? '',
        'trim': carDetails['trim'] ?? '',
        'vin': carDetails['vin'] ?? scanData['vin'] ?? '',
        'current_market_value': estimatedValue,
        'status': 'active',
      };

      if (vehicles.items.isEmpty) {
        final record = await auth.pb
            .collection('vehicles')
            .create(body: vehicleBody);
        vehicleId = record.id;
        debugPrint("[SYNC] Created new vehicle: $vehicleId");
      } else {
        vehicleId = vehicles.items.first.id;
        await auth.pb
            .collection('vehicles')
            .update(vehicleId, body: vehicleBody);
        debugPrint("[SYNC] Updated existing vehicle: $vehicleId");
      }

      // 2. Check/Create Loan
      final loans = await auth.pb
          .collection('loans')
          .getList(page: 1, perPage: 1, filter: 'vehicle_id = "$vehicleId"');

      final loanBody = {
        'vehicle_id': vehicleId,
        'lender_name': scanData['lender_name'] ?? '',
        'interest_rate': (scanData['interest_rate'] ?? 0.0).toDouble(),
        'original_balance': (scanData['current_balance'] ?? 0.0).toDouble(),
        'current_balance': (scanData['current_balance'] ?? 0.0).toDouble(),
        'monthly_payment':
            (scanData['monthly_payment'] ??
                    (scanData['bi_weekly_payment'] ?? 0.0) * 2.16)
                .toDouble(),
        'term_months': (scanData['term_months'] ?? 0).toInt(),
        'start_date':
            scanData['contract_date'] ?? DateTime.now().toIso8601String(),
        'is_verified': isVerified,
      };

      String loanId;
      if (loans.items.isEmpty) {
        final record = await auth.pb.collection('loans').create(body: loanBody);
        loanId = record.id;
        debugPrint("[SYNC] Created new loan for vehicle: $vehicleId");
      } else {
        loanId = loans.items.first.id;
        await auth.pb.collection('loans').update(loanId, body: loanBody);
        debugPrint("[SYNC] Updated existing loan: $loanId");
      }

      // 3. Link Document if provided
      if (documentId != null && documentId.isNotEmpty) {
        try {
          await auth.pb
              .collection('documents')
              .update(
                documentId,
                body: {
                  'loan_id': loanId,
                  'status': 'verified',
                  'user_id': userId, // Ensure user_id is set/consistent
                },
              );
          debugPrint("[SYNC] Linked document $documentId to loan $loanId");
        } catch (docErr) {
          debugPrint("[SYNC] Error linking document: $docErr");
        }
      }
      debugPrint("[SYNC] Sync Complete Success.");
    } catch (e) {
      debugPrint("[SYNC] Error syncing onboarding data: $e");
      rethrow;
    }
  }

  // 1e. Simple vehicle detail update
  static Future<void> updateVehicleDetails(Map<String, String> updates) async {
    final auth = AuthService();
    if (!auth.isAuthenticated) return;
    final userId = auth.userId;
    try {
      final vehicles = await auth.pb
          .collection('vehicles')
          .getList(page: 1, perPage: 1, filter: 'user_id = "$userId"');
      if (vehicles.items.isEmpty) return;
      final vehicleId = vehicles.items.first.id;
      final Map<String, dynamic> body = Map<String, dynamic>.from(updates);
      if (updates.containsKey('year')) {
        body['year'] = int.tryParse(updates['year']!) ?? 0;
      }
      await auth.pb.collection('vehicles').update(vehicleId, body: body);
    } catch (e) {
      debugPrint("Error updating vehicle details: $e");
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
  static Future<List<dynamic>> getInventory({
    double? equity,
    String? city,
    String? province,
  }) async {
    final userId = AuthService().userId;
    String url = '${Config.inventory}?userId=$userId';

    if (equity != null) url += '&equity=$equity';
    if (city != null) url += '&city=$city';
    if (province != null) url += '&province=$province';

    final response = await http.get(Uri.parse(url));

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
      rethrow;
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

  // 7. Calculate Loan Equity (Time Travel)
  static Future<Map<String, dynamic>> calculateLoanEquity({
    required double originalBalance,
    required double interestRate,
    required int termMonths,
    required String startDate,
    required double monthlyPayment,
  }) async {
    final response = await http.post(
      Uri.parse(Config.calculateEquity),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'original_balance': originalBalance,
        'interest_rate': interestRate,
        'term_months': termMonths,
        'start_date': startDate,
        'monthly_payment': monthlyPayment,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to calculate equity: ${response.body}');
    }
  }

  // 8. Update Loan Balance
  static Future<void> updateLoanBalance(double newBalance) async {
    final auth = AuthService();
    if (!auth.isAuthenticated) return;
    final userId = auth.userId;

    try {
      final vehicles = await auth.pb
          .collection('vehicles')
          .getList(page: 1, perPage: 1, filter: 'user_id = "$userId"');
      if (vehicles.items.isEmpty) return;
      final vehicleId = vehicles.items.first.id;

      final loans = await auth.pb
          .collection('loans')
          .getList(page: 1, perPage: 1, filter: 'vehicle_id = "$vehicleId"');
      if (loans.items.isEmpty) return;
      final loanId = loans.items.first.id;

      await auth.pb
          .collection('loans')
          .update(loanId, body: {'current_balance': newBalance});
      debugPrint("[API] Loan balance updated in DB: $newBalance");
    } catch (e) {
      debugPrint("Error updating loan balance: $e");
    }
  }
}
