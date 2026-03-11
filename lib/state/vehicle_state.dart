import 'package:flutter_riverpod/flutter_riverpod.dart';

class VehicleState {
  final Map<String, String> carDetails;
  final Map<String, dynamic>? lastScanData;

  const VehicleState({
    required this.carDetails,
    required this.lastScanData,
  });

  factory VehicleState.initial() {
    return const VehicleState(
      carDetails: {
        'year': '',
        'make': '',
        'model': '',
        'trim': '',
        'vin': '',
        'plate': '',
      },
      lastScanData: null,
    );
  }

  VehicleState copyWith({
    Map<String, String>? carDetails,
    Map<String, dynamic>? lastScanData,
    bool keepLastScanData = true,
  }) {
    return VehicleState(
      carDetails: carDetails ?? this.carDetails,
      lastScanData: keepLastScanData ? (lastScanData ?? this.lastScanData) : lastScanData,
    );
  }
}

class VehicleNotifier extends StateNotifier<VehicleState> {
  VehicleNotifier() : super(VehicleState.initial());

  String _sanitizeCarDetailValue(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return '';

    final normalized = raw.toLowerCase();
    const placeholders = {
      'n/a',
      'na',
      'not available',
      'unknown',
      'null',
      '-',
      '--',
    };
    if (placeholders.contains(normalized) ||
        normalized.startsWith('fetching') ||
        normalized.startsWith('pending')) {
      return '';
    }
    return raw;
  }

  Map<String, String> _sanitizeCarDetailsPatch(Map<String, String> patch) {
    return patch.map(
      (key, value) => MapEntry(key, _sanitizeCarDetailValue(value)),
    );
  }

  void updateCarDetails(Map<String, String> patch) {
    final sanitized = _sanitizeCarDetailsPatch(patch);
    state = state.copyWith(
      carDetails: {
        ...state.carDetails,
        ...sanitized,
      },
      keepLastScanData: true,
    );
  }

  void setLastScanData(Map<String, dynamic>? data) {
    state = state.copyWith(lastScanData: data, keepLastScanData: false);
  }

  void clearLastScanData() {
    state = state.copyWith(lastScanData: null, keepLastScanData: false);
  }
}

final vehicleProvider = StateNotifierProvider<VehicleNotifier, VehicleState>(
  (ref) => VehicleNotifier(),
);
