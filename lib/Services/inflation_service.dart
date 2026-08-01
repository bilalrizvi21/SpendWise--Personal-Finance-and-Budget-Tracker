import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fetches live Pakistan CPI inflation rate from the World Bank API.
/// Indicator: FP.CPI.TOTL.ZG — annual inflation %
/// Free, no API key required, updates annually.
///
/// Falls back to PBS published value if network is unavailable.
/// Petrol price is excluded — OGRA now announces prices daily,
/// making any stored value immediately stale.
class InflationService {
  static final InflationService instance = InflationService._();
  InflationService._();

  EconomicData? _cached;
  DateTime? _lastFetch;
  static const _cacheHours = 24;

  Future<EconomicData> getEconomicData() async {
    // Return cached data if still fresh
    if (_cached != null && _lastFetch != null) {
      if (DateTime.now().difference(_lastFetch!).inHours < _cacheHours) {
        return _cached!;
      }
    }

    double? inflationRate;

    // World Bank API — Pakistan CPI annual inflation %
    try {
      final uri = Uri.parse(
        'https://api.worldbank.org/v2/country/PK/indicator/FP.CPI.TOTL.ZG'
        '?format=json&mrv=1&per_page=1',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List;
        if (json.length > 1 && json[1] is List) {
          final data = json[1] as List;
          if (data.isNotEmpty && data[0]['value'] != null) {
            inflationRate = (data[0]['value'] as num).toDouble();
          }
        }
      }
    } catch (e) {
      print('⚠️ Inflation fetch failed: $e');
    }

    final data = EconomicData(
      inflationRate: inflationRate ?? 11.8, // PBS fallback
      lastUpdated: DateTime.now(),
      isLiveData: inflationRate != null,
    );

    _cached = data;
    _lastFetch = DateTime.now();
    print('📈 Inflation: ${data.inflationLabel} (live=${data.isLiveData})');
    return data;
  }
}

class EconomicData {
  final double inflationRate;
  final DateTime lastUpdated;
  final bool isLiveData;

  const EconomicData({
    required this.inflationRate,
    required this.lastUpdated,
    required this.isLiveData,
  });

  /// Monthly inflation factor applied to spending prediction
  /// e.g. annual 11.8% → 1 + (11.8/100/12) ≈ 1.0098
  double get monthlyInflationFactor => 1 + (inflationRate / 100 / 12);

  String get inflationLabel => '${inflationRate.toStringAsFixed(1)}%';
}
