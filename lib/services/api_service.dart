import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'auth_service.dart';

class LoanSnapshot {
  final String loanId;
  final double currentBalance;
  final double monthlyPayment;
  final double interestRate;
  final int termMonths;
  final String startDate;
  final double originalBalance;
  final double estimatedValue;

  const LoanSnapshot({
    required this.loanId,
    required this.currentBalance,
    required this.monthlyPayment,
    required this.interestRate,
    required this.termMonths,
    required this.startDate,
    required this.originalBalance,
    required this.estimatedValue,
  });
}

class NotificationFeedItem {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final String actionRoute;
  final String created;

  const NotificationFeedItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.actionRoute,
    required this.created,
  });

  factory NotificationFeedItem.fromJson(Map<String, dynamic> json) {
    return NotificationFeedItem(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      isRead: json['isRead'] == true,
      actionRoute: (json['actionRoute'] ?? '').toString(),
      created: (json['created'] ?? '').toString(),
    );
  }
}

class NotificationPage {
  final List<NotificationFeedItem> items;
  final bool hasMore;
  final String? nextCursor;
  final int unreadCount;

  const NotificationPage({
    required this.items,
    required this.hasMore,
    required this.nextCursor,
    required this.unreadCount,
  });
}

class ActivityFeedItem {
  final String id;
  final String actionType;
  final String title;
  final String description;
  final String created;
  final String iconType;
  final String color;

  const ActivityFeedItem({
    required this.id,
    required this.actionType,
    required this.title,
    required this.description,
    required this.created,
    required this.iconType,
    required this.color,
  });

  factory ActivityFeedItem.fromJson(Map<String, dynamic> json) {
    return ActivityFeedItem(
      id: (json['id'] ?? '').toString(),
      actionType: (json['actionType'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? json['desc'] ?? '').toString(),
      created: (json['created'] ?? json['date'] ?? '').toString(),
      iconType: (json['iconType'] ?? '').toString(),
      color: (json['color'] ?? '').toString(),
    );
  }
}

class ActivityPage {
  final List<ActivityFeedItem> items;
  final bool hasMore;
  final String? nextCursor;

  const ActivityPage({
    required this.items,
    required this.hasMore,
    required this.nextCursor,
  });
}

class ApiService {
  static double _toDouble(dynamic value, [double fallback = 0.0]) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static int _toInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static Map<String, dynamic> _sanitizeScanLogData(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);
    if (sanitized.containsKey('raw_ocr')) {
      sanitized['raw_ocr'] = '[TRUNCATED]';
    }
    return sanitized;
  }

  // 1. Upload Document for OCR
  static Future<Map<String, dynamic>> scanDocument(
    String filePath, {
    String? userId,
    String? loanId,
  }) async {
    final url = Config.scanDoc;
    debugPrint("[API] Calling: $url");
    var request = http.MultipartRequest('POST', Uri.parse(url));

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
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint("[SCAN] Success: ${_sanitizeScanLogData(decoded)}");
      return decoded;
    } else {
      debugPrint("[SCAN] Failed: ${response.body}");
      throw Exception('OCR Failed: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> parseLoanDetails({
    required String vehicleText,
    required String vinText,
    required String lenderText,
    required String contractDateText,
    required String termText,
    required String aprText,
    required String paymentText,
    required String financedAmountText,
  }) async {
    final response = await http.post(
      Uri.parse(Config.parseLoanDetails),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'vehicle_text': vehicleText,
        'vin_text': vinText,
        'lender_text': lenderText,
        'contract_date_text': contractDateText,
        'term_text': termText,
        'apr_text': aprText,
        'payment_text': paymentText,
        'financed_amount_text': financedAmountText,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to parse loan details: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected parse-loan-details response format');
    }
    return decoded;
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

  static Future<String> syncOnboardingData({
    required Map<String, String> carDetails,
    required Map<String, dynamic> scanData,
    required double estimatedValue,
    required bool isVerified,
    String? documentId,
  }) async {
    final auth = AuthService();
    if (!auth.isAuthenticated) return '';

    final userId = auth.userId;
    if (userId.isEmpty) return '';

    debugPrint("[SYNC] Starting Onboarding Data Sync...");
    debugPrint("[SYNC] Car Details: $carDetails");
    debugPrint("[SYNC] Scan Data: ${_sanitizeScanLogData(scanData)}");
    debugPrint("[SYNC] Estimated Value Input: $estimatedValue");
    debugPrint("[SYNC] Document ID: $documentId");

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
        'mileage':
            int.tryParse(
              carDetails['mileage']?.replaceAll(RegExp(r'[^0-9]'), '') ?? '',
            ) ??
            0,
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

      // 3. Calculate Current Balance dynamically if possible
      double originalBalance = _toDouble(
        scanData['original_amount_financed'] ?? scanData['current_balance'],
      );
      final resolvedBalance = _toDouble(scanData['resolved_loan_balance'], -1);
      double currentBalance = resolvedBalance >= 0
          ? resolvedBalance
          : originalBalance;

      // If DataService already resolved the balance, persist that value directly.
      if (resolvedBalance >= 0) {
        debugPrint(
          "[SYNC] Using pre-resolved loan balance from DataService: $currentBalance (${scanData['loan_balance_source'] ?? 'unknown'})",
        );
      } else if (originalBalance > 0 &&
          scanData['interest_rate'] != null &&
          scanData['term_months'] != null &&
          scanData['contract_date'] != null) {
        // Otherwise calculate the real-time balance now.
        try {
          debugPrint(
            "[SYNC] Calling calculateLoanEquity with: balance=$originalBalance, rate=${scanData['interest_rate']}, term=${scanData['term_months']}, date=${scanData['contract_date']}, payment=${scanData['monthly_payment'] ?? (scanData['bi_weekly_payment'] ?? 0.0) * 2.16}",
          );
          final calculation = await calculateLoanEquity(
            originalBalance: originalBalance,
            interestRate: (scanData['interest_rate'] ?? 0.0).toDouble(),
            termMonths: (scanData['term_months'] ?? 0).toInt(),
            startDate: scanData['contract_date'].toString(),
            monthlyPayment:
                (scanData['monthly_payment'] ??
                        (scanData['bi_weekly_payment'] ?? 0.0) * 2.16)
                    .toDouble(),
          );
          if (calculation['calculated_balance'] != null) {
            currentBalance = calculation['calculated_balance'].toDouble();
            debugPrint(
              "[SYNC] Dynamically calculated current_balance: $currentBalance",
            );
          }
        } catch (e) {
          debugPrint("[SYNC] Dynamic balance calculation failed: $e");
          // Fallback to originalBalance if calculation fails
        }
      }

      final loanBody = {
        'vehicle_id': vehicleId,
        'lender_name': scanData['lender_name'] ?? '',
        'interest_rate': (scanData['interest_rate'] ?? 0.0).toDouble(),
        'original_balance': originalBalance,
        'current_balance': currentBalance,
        'monthly_payment':
            (scanData['monthly_payment'] ??
                    (scanData['bi_weekly_payment'] ?? 0.0) * 2.16)
                .toDouble(),
        'term_months': (scanData['term_months'] ?? 0).toInt(),
        'start_date':
            scanData['contract_date'] ?? DateTime.now().toIso8601String(),
        'is_verified': isVerified,
      };

      debugPrint("[SYNC] Loan Body for DB: ${jsonEncode(loanBody)}");
      debugPrint("[SYNC] Calculated Final currentBalance: $currentBalance");

      String loanId;
      if (loans.items.isEmpty) {
        final record = await auth.pb.collection('loans').create(body: loanBody);
        loanId = record.id;
        debugPrint("[SYNC] Created new loan for vehicle: $vehicleId");
      } else {
        loanId = loans.items.first.id;
        debugPrint(
          "[SYNC] Updating existing loan: $loanId with balance: ${loanBody['current_balance']}",
        );
        await auth.pb.collection('loans').update(loanId, body: loanBody);
        debugPrint("[SYNC] Update complete for loan: $loanId");
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
      return loanId;
    } catch (e) {
      debugPrint("[SYNC] Error syncing onboarding data: $e");
      rethrow;
    }
  }

  static Future<String> syncVehicleData({
    required Map<String, String> carDetails,
    double? estimatedValue,
  }) async {
    final auth = AuthService();
    if (!auth.isAuthenticated) throw Exception("User not authenticated");

    final userId = auth.userId;
    if (userId.isEmpty) throw Exception("User ID not found");

    debugPrint("[SYNC] Syncing Vehicle Data (Draft)...");

    try {
      final vehicles = await auth.pb
          .collection('vehicles')
          .getList(page: 1, perPage: 1, filter: 'user_id = "$userId"');
      final vehicleBody = {
        'user_id': userId,
        'year': int.tryParse(carDetails['year'] ?? '') ?? 0,
        'make': carDetails['make'] ?? '',
        'model': carDetails['model'] ?? '',
        'trim': carDetails['trim'] ?? '',
        'mileage':
            int.tryParse(
              carDetails['mileage']?.replaceAll(RegExp(r'[^0-9]'), '') ?? '',
            ) ??
            0,
        'vin': carDetails['vin'] ?? '',
        'plate': carDetails['plate'] ?? '',
        'is_verified': false,
      };

      if (estimatedValue != null) {
        vehicleBody['current_market_value'] = estimatedValue;
      }

      if (vehicles.items.isEmpty) {
        final record = await auth.pb
            .collection('vehicles')
            .create(body: vehicleBody);
        debugPrint("[SYNC] Created draft vehicle: ${record.id}");
        return record.id;
      } else {
        final vehicleId = vehicles.items.first.id;
        await auth.pb
            .collection('vehicles')
            .update(vehicleId, body: vehicleBody);
        debugPrint("[SYNC] Updated draft vehicle: $vehicleId");
        return vehicleId;
      }
    } catch (e) {
      debugPrint("[SYNC] Vehicle Sync Error: $e");
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

  static Future<NotificationPage> getNotifications({
    String status = 'all',
    int limit = 20,
    String? cursor,
  }) async {
    final userId = AuthService().userId;
    if (userId.isEmpty) throw Exception('User not logged in');

    final query = <String, String>{
      'userId': userId,
      'status': status,
      'limit': '$limit',
    };
    if (cursor != null && cursor.trim().isNotEmpty) {
      query['cursor'] = cursor.trim();
    }

    final response = await http.get(
      Uri.parse(Config.notifications).replace(queryParameters: query),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load notifications');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final rawItems = (json['items'] as List<dynamic>? ?? const []);
    final meta = (json['meta'] as Map<String, dynamic>? ?? const {});

    return NotificationPage(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(NotificationFeedItem.fromJson)
          .toList(),
      hasMore: meta['hasMore'] == true,
      nextCursor: (meta['nextCursor'] ?? '').toString().isEmpty
          ? null
          : (meta['nextCursor'] ?? '').toString(),
      unreadCount: _toInt(meta['unreadCount'], 0),
    );
  }

  static Future<int> markNotificationsRead({
    List<String> ids = const [],
    String? beforeCreatedAt,
  }) async {
    final userId = AuthService().userId;
    if (userId.isEmpty) return 0;

    final body = <String, dynamic>{'userId': userId};
    if (ids.isNotEmpty) body['ids'] = ids;
    if (beforeCreatedAt != null && beforeCreatedAt.trim().isNotEmpty) {
      body['markAllVisible'] = {'beforeCreatedAt': beforeCreatedAt.trim()};
    }

    final response = await http.post(
      Uri.parse(Config.notificationsMarkRead),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notifications read');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _toInt(json['unreadCount'], 0);
  }

  static Future<ActivityPage> getActivityFeed({
    int limit = 20,
    String? cursor,
  }) async {
    final userId = AuthService().userId;
    if (userId.isEmpty) throw Exception('User not logged in');

    final query = <String, String>{'userId': userId, 'limit': '$limit'};
    if (cursor != null && cursor.trim().isNotEmpty) {
      query['cursor'] = cursor.trim();
    }

    final response = await http.get(
      Uri.parse(Config.activity).replace(queryParameters: query),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load activity feed');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final rawItems = (json['items'] as List<dynamic>? ?? const []);
    final meta = (json['meta'] as Map<String, dynamic>? ?? const {});

    return ActivityPage(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(ActivityFeedItem.fromJson)
          .toList(),
      hasMore: meta['hasMore'] == true,
      nextCursor: (meta['nextCursor'] ?? '').toString().isEmpty
          ? null
          : (meta['nextCursor'] ?? '').toString(),
    );
  }

  static Future<Map<String, dynamic>> getTradeUpPreview() async {
    final userId = AuthService().userId;
    if (userId.isEmpty) throw Exception('User not logged in');

    final response = await http.get(
      Uri.parse('${Config.tradeUpPreview}?userId=$userId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      debugPrint(
        '[API] trade-up-preview failed: ${response.statusCode} - ${response.body}',
      );
      throw Exception(
        'Failed to load trade-up preview (${response.statusCode})',
      );
    }
  }

  static Future<double> getMarketRateFromSettings() async {
    final auth = AuthService();
    if (!auth.isAuthenticated) {
      throw Exception('User not logged in');
    }

    final settings = await auth.pb
        .collection('settings')
        .getList(page: 1, perPage: 50);
    if (settings.items.isEmpty) {
      throw Exception('No settings found');
    }

    for (final item in settings.items) {
      final data = item.data;
      final double direct = _toDouble(
        data['market_rate'] ??
            data['market_apr'] ??
            data['refinance_market_rate'] ??
            data['apr'],
        -1,
      );
      if (direct >= 0) {
        return direct;
      }

      final String key = (data['key'] ?? data['name'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      if (key == 'market_rate' ||
          key == 'market_apr' ||
          key == 'refinance_market_rate') {
        final double value = _toDouble(data['value'], -1);
        if (value >= 0) {
          return value;
        }
      }
    }

    throw Exception('Market rate setting not found');
  }

  static Future<Map<String, dynamic>?> getUserVehicle() async {
    final auth = AuthService();
    if (!auth.isAuthenticated) return null;

    final userId = auth.userId;
    if (userId.isEmpty) return null;

    try {
      final vehicles = await auth.pb
          .collection('vehicles')
          .getList(page: 1, perPage: 1, filter: 'user_id = "$userId"');
      if (vehicles.items.isEmpty) return null;
      final vehicle = vehicles.items.first;

      return {
        'id': vehicle.id,
        'year': vehicle.data['year']?.toString() ?? '',
        'make': vehicle.data['make']?.toString() ?? '',
        'model': vehicle.data['model']?.toString() ?? '',
        'trim': vehicle.data['trim']?.toString() ?? '',
        'vin': vehicle.data['vin']?.toString() ?? '',
        'mileage': vehicle.data['mileage']?.toString() ?? '',
        'current_market_value': _toDouble(vehicle.data['current_market_value']),
      };
    } catch (e) {
      debugPrint("Error fetching user vehicle: $e");
      return null;
    }
  }

  static Future<LoanSnapshot?> getCurrentLoanSnapshot() async {
    final auth = AuthService();
    if (!auth.isAuthenticated) return null;

    final userId = auth.userId;
    if (userId.isEmpty) return null;

    final vehicles = await auth.pb
        .collection('vehicles')
        .getList(page: 1, perPage: 1, filter: 'user_id = "$userId"');
    if (vehicles.items.isEmpty) return null;
    final vehicle = vehicles.items.first;
    final vehicleId = vehicle.id;
    final estimatedValue = _toDouble(vehicle.data['current_market_value']);

    final loans = await auth.pb
        .collection('loans')
        .getList(page: 1, perPage: 1, filter: 'vehicle_id = "$vehicleId"');
    if (loans.items.isEmpty) return null;

    final loan = loans.items.first;
    final data = loan.data;

    return LoanSnapshot(
      loanId: loan.id,
      currentBalance: _toDouble(data['current_balance']),
      monthlyPayment: _toDouble(data['monthly_payment']),
      interestRate: _toDouble(data['interest_rate']),
      termMonths: _toInt(data['term_months']),
      startDate: (data['start_date'] ?? '').toString(),
      originalBalance: _toDouble(data['original_balance']),
      estimatedValue: estimatedValue,
    );
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

  // 3b. Submit Buyer Preapproval Lead
  static Future<void> submitBuyerPreapprovalLead({
    required String name,
    required String phone,
    String? email,
    required double monthlyBudgetTarget,
    required String incomeRange,
    required String employmentStatus,
    required String creditBand,
    String? notes,
    List<String> inventoryContext = const [],
  }) async {
    final userId = AuthService().userId;

    await submitLead('buyer_preapproval', {
      'user_id': userId,
      'source': 'car_owners_hub_buyer_dashboard',
      'name': name,
      'phone': phone,
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      'monthly_budget_target': monthlyBudgetTarget,
      'income_range': incomeRange,
      'employment_status': employmentStatus,
      'credit_band': creditBand,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      if (inventoryContext.isNotEmpty) 'inventory_context': inventoryContext,
    });
  }

  // 4. Fetch Inventory
  static Future<List<dynamic>> getInventory({
    double? equity,
    double? targetPayment,
    double? currentPayment,
    int? currentYear,
    String? currentMake,
    String? currentModel,
    String? currentBodyStyle,
    String? targetMode,
    String? city,
    String? province,
  }) async {
    final userId = AuthService().userId;
    debugPrint(
      '[SHOP] getInventory request location city=${city ?? '-'} province=${province ?? '-'}',
    );
    final queryParameters = <String, String>{'userId': userId};
    if (equity != null) queryParameters['equity'] = equity.toStringAsFixed(2);
    if (targetPayment != null) {
      queryParameters['target_payment'] = targetPayment.toStringAsFixed(2);
    }
    if (currentPayment != null) {
      queryParameters['current_payment'] = currentPayment.toStringAsFixed(2);
    }
    if (currentYear != null) {
      queryParameters['current_year'] = currentYear.toString();
    }
    if (currentMake != null && currentMake.trim().isNotEmpty) {
      queryParameters['current_make'] = currentMake.trim();
    }
    if (currentModel != null && currentModel.trim().isNotEmpty) {
      queryParameters['current_model'] = currentModel.trim();
    }
    if (currentBodyStyle != null && currentBodyStyle.trim().isNotEmpty) {
      queryParameters['current_body_style'] = currentBodyStyle.trim();
    }
    if (targetMode != null && targetMode.trim().isNotEmpty) {
      queryParameters['target_mode'] = targetMode.trim();
    }
    if (city != null && city.trim().isNotEmpty) {
      queryParameters['city'] = city.trim();
    }
    if (province != null && province.trim().isNotEmpty) {
      queryParameters['province'] = province.trim();
    }

    final response = await http.get(
      Uri.parse(Config.inventory).replace(queryParameters: queryParameters),
    );

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

    debugPrint("[API] getVehicleOptions calling: $url");

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      debugPrint(
        "[API] getVehicleOptions response code: ${response.statusCode}",
      );

      if (response.statusCode == 200) {
        // Convert [2023, 2022] to ["2023", "2022"]
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint("[API] getVehicleOptions data length: ${data.length}");
        return data.map((e) => e.toString()).toList();
      } else {
        debugPrint("[API] getVehicleOptions failed: ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("[API] Error fetching vehicle options: $e");
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

    debugPrint(
      "[API] calculateLoanEquity Response: ${response.statusCode} - ${response.body}",
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
      debugPrint(
        "[API] SUCCESS: Loan balance updated in PB: $newBalance for loanId: $loanId",
      );
    } catch (e) {
      debugPrint("Error updating loan balance: $e");
    }
  }
  // --- Garage Document Methods ---

  // Fetch all documents for the current user
  static Future<List<Map<String, dynamic>>> getUserDocuments() async {
    final auth = AuthService();
    if (!auth.isAuthenticated) return [];

    try {
      final records = await auth.pb
          .collection('documents')
          .getList(filter: 'user_id = "${auth.userId}"', sort: '-created');

      return records.items.map((r) {
        return {
          'id': r.id,
          'doc_type': r.data['doc_type'],
          // Build the PocketBase file URL format
          'file_url':
              '${auth.pb.baseURL}/api/files/${r.collectionId}/${r.id}/${r.data['file_blob']}',
          'status': r.data['status'],
        };
      }).toList();
    } catch (e) {
      debugPrint("Error fetching user documents: $e");
      return [];
    }
  }

  // Upload a generic garage document directly to PocketBase
  static Future<void> uploadGarageDocument(
    String filePath,
    String docType, {
    String? loanId,
  }) async {
    final auth = AuthService();
    if (!auth.isAuthenticated) throw Exception('Not authenticated');

    var request = http.MultipartRequest(
      'POST',
      Uri.parse(Config.uploadGarageDoc),
    );
    request.files.add(await http.MultipartFile.fromPath('file_blob', filePath));
    request.fields['user_id'] = auth.userId;
    request.fields['doc_type'] = docType;
    if (loanId != null) {
      request.fields['loan_id'] = loanId;
    }

    debugPrint("[GARAGE] Uploading document: $docType ($filePath)");

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    debugPrint("[GARAGE] Upload Response Code: ${response.statusCode}");

    if (response.statusCode != 200) {
      debugPrint("[GARAGE] Failed: ${response.body}");
      throw Exception('Upload Failed: ${response.body}');
    }
  }
}
