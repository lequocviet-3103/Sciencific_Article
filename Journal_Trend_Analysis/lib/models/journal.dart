class Journal {
  final String id;
  final String name;
  final String? issn;
  final String? publisher;
  final String? country;

  const Journal({
    required this.id,
    required this.name,
    this.issn,
    this.publisher,
    this.country,
  });

  /// Display name for the UI. Returns "Unknown Journal" when the
  /// OpenAlex record was missing `display_name` so that user-facing
  /// surfaces (cards, detail screen) never show a blank string.
  String get displayName =>
      (name.isEmpty) ? 'Unknown Journal' : name;

  factory Journal.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Journal(id: '', name: '');
    final name = (json['display_name'] as String?)?.trim();

    String? publisher;
    if (json['host_organization_name'] != null) {
      publisher = json['host_organization_name'] as String?;
    } else if (json['host_organization'] != null) {
      final org = json['host_organization'] as Map<String, dynamic>?;
      publisher = org?['display_name'] as String?;
    }

    String? country;
    if (json['country_code'] != null) {
      final code = json['country_code'] as String?;
      country = _countryName(code!);
    }

    return Journal(
      id: (json['id'] as String?) ?? '',
      name: (name != null && name.isNotEmpty) ? name : '',
      issn: (json['issn_l'] as String?),
      publisher: publisher,
      country: country,
    );
  }

  static String _countryName(String code) {
    final countries = {
      'US': 'United States',
      'GB': 'United Kingdom',
      'NL': 'Netherlands',
      'DE': 'Germany',
      'CH': 'Switzerland',
      'FR': 'France',
      'JP': 'Japan',
      'CN': 'China',
      'IN': 'India',
      'AU': 'Australia',
      'BR': 'Brazil',
      'KR': 'South Korea',
      'CA': 'Canada',
      'IT': 'Italy',
      'ES': 'Spain',
      'PL': 'Poland',
      'RU': 'Russia',
      'SE': 'Sweden',
      'NO': 'Norway',
      'DK': 'Denmark',
      'FI': 'Finland',
      'BE': 'Belgium',
      'AT': 'Austria',
      'SG': 'Singapore',
      'TW': 'Taiwan',
      'VN': 'Vietnam',
      'TH': 'Thailand',
      'MY': 'Malaysia',
      'ID': 'Indonesia',
      'PH': 'Philippines',
      'PK': 'Pakistan',
      'EG': 'Egypt',
      'ZA': 'South Africa',
      'NG': 'Nigeria',
      'KE': 'Kenya',
      'MX': 'Mexico',
      'AR': 'Argentina',
      'CL': 'Chile',
      'CO': 'Colombia',
      'PE': 'Peru',
      'CZ': 'Czech Republic',
      'HU': 'Hungary',
      'TR': 'Turkey',
      'IR': 'Iran',
      'IL': 'Israel',
      'IE': 'Ireland',
      'NZ': 'New Zealand',
    };
    return countries[code.toUpperCase()] ?? code.toUpperCase();
  }
}
