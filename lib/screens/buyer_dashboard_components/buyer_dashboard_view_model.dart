import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import 'buyer_dashboard_constants.dart';

class BuyerDashboardViewModel extends ChangeNotifier {
  // --- Form State ---
  String? income;
  String? employment;
  String? credit;
  double _budget = 350;

  double get budget => _budget;
  set budget(double value) {
    _budget = value;
    notifyListeners();
  }

  // Manual override for wizard step
  int? manualStep;

  // Bottom Sheet Form State
  String? dobMonth;
  String? dobDay;
  String? dobYear;
  String? homeAddress;
  String? empCompany;
  String? empTitle;
  String? incomeYears;
  String? incomeMonths;
  double housingCost = 0;
  double downpayment = 0;
  String? hasCosigner;
  String? notes;
  bool acceptedTerms = false;

  // Inventory logic
  bool inventoryLoading = true;
  String? inventoryError;
  List<Map<String, dynamic>> inventory = [];
  final Set<String> inventoryContextIds = <String>{};

  // --- Computed Properties ---

  int get currentStep {
    if (manualStep != null) return manualStep!;
    if ((income ?? '').isEmpty) return 0;
    if ((employment ?? '').isEmpty) return 1;
    if ((credit ?? '').isEmpty) return 2;
    return 3;
  }

  double get approvalProgress {
    int completed = 0;
    if ((income ?? '').isNotEmpty) completed++;
    if ((employment ?? '').isNotEmpty) completed++;
    if ((credit ?? '').isNotEmpty) completed++;
    return completed / 3;
  }

  bool get isProfileComplete => approvalProgress >= 1;

  AffordabilityEstimate get affordability => estimateAffordability(budget);

  // --- Methods ---

  void setManualStep(int? step) {
    manualStep = step;
    notifyListeners();
  }

  Future<void> loadDraft() async {
    try {
      final appData = await DataService().loadAppData(
        fallbackUserType: 'buyer',
      );
      final profile = appData.buyerProfile;

      income = (profile['income_range'] ?? '').toString().isEmpty
          ? null
          : (profile['income_range'] ?? '').toString();
      employment = (profile['employment_status'] ?? '').toString().isEmpty
          ? null
          : (profile['employment_status'] ?? '').toString();
      credit = (profile['credit_score_range'] ?? '').toString().isEmpty
          ? null
          : (profile['credit_score_range'] ?? '').toString();

      final budgetRaw = profile['monthly_budget'];
      if (budgetRaw is num) {
        _budget = budgetRaw.toDouble().clamp(150, 900);
      } else if (budgetRaw is String) {
        final parsed = double.tryParse(budgetRaw);
        if (parsed != null) _budget = parsed.clamp(150, 900);
      }

      final dobStr = (profile['dob'] ?? '').toString();
      if (dobStr.isNotEmpty && dobStr.contains('/')) {
        final parts = dobStr.split('/');
        if (parts.length == 3) {
          dobMonth = parts[0].padLeft(2, '0');
          dobDay = parts[1].padLeft(2, '0');
          dobYear = parts[2];
        }
      }

      homeAddress = (profile['address'] ?? '').toString();
      empCompany = (profile['employer_name'] ?? '').toString();
      empTitle = (profile['job_title'] ?? '').toString();

      final duration = (profile['employment_duration'] ?? '').toString();
      if (duration.isNotEmpty && duration.contains('|')) {
        final parts = duration.split('|');
        if (parts.length == 2) {
          incomeYears = parts[0];
          incomeMonths = parts[1];
        }
      }

      housingCost = _asDouble(profile['housing_cost']).clamp(0, 5000);
      downpayment = _asDouble(profile['downpayment']).clamp(0, 10000);
      hasCosigner = profile['has_cosigner'] == true ? 'yes' : 'no';
      notes = (profile['buyer_notes'] ?? '').toString();

      notifyListeners();
    } catch (e) {
      debugPrint('[BUYER VM] Failed to load draft: $e');
    }
  }

  Future<void> saveDraft() async {
    try {
      final body = {
        'income_range': income,
        'employment_status': employment,
        'credit_score_range': credit,
        'monthly_budget': budget.toInt().toString(),
        'dob': (dobMonth != null && dobDay != null && dobYear != null)
            ? '$dobMonth/$dobDay/$dobYear'
            : '',
        'address': homeAddress,
        'employer_name': empCompany,
        'job_title': empTitle,
        'employment_duration': '$incomeYears|$incomeMonths',
        'housing_cost': housingCost,
        'downpayment': downpayment,
        'has_cosigner': hasCosigner == 'yes',
        'buyer_notes': notes,
      };

      await DataService().saveBuyerProfileDraft(body);
      notifyListeners();
    } catch (e) {
      debugPrint('[BUYER VM] Failed to save draft: $e');
    }
  }

  Future<void> fetchInventory(AnimationController refreshSpinController) async {
    if (!refreshSpinController.isAnimating) {
      refreshSpinController.repeat();
    }

    inventoryLoading = true;
    inventoryError = null;
    notifyListeners();

    try {
      final authRecord = AuthService().pb.authStore.record;
      final city = authRecord?.getStringValue('city');
      final province = authRecord?.getStringValue('province');

      final data = await ApiService.getInventory(
        targetPayment: budget,
        targetMode: 'buyer_budget',
        city: city,
        province: province,
      );

      final normalized = data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      final ids = <String>{};
      for (final car in normalized) {
        final id = (car['id'] ?? car['vehicle_id'] ?? '').toString().trim();
        if (id.isNotEmpty) {
          ids.add(id);
        }
      }

      inventory = normalized;
      inventoryContextIds
        ..clear()
        ..addAll(ids);
    } catch (e) {
      inventoryError = 'Could not load starter matches right now.';
      debugPrint('[BUYER VM] Failed to fetch inventory: $e');
    } finally {
      inventoryLoading = false;
      if (refreshSpinController.isAnimating) {
        refreshSpinController.stop();
        refreshSpinController.reset();
      }
      notifyListeners();
    }
  }

  double _asDouble(dynamic value, [double fallback = 0.0]) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }
}
