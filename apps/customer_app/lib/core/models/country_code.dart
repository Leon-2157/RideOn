/// Model Kode Negara untuk Selector & PhoneNumber Formatter
class CountryCode {
  final String name;
  final String flag;
  final String dialCode;

  const CountryCode({
    required this.name,
    required this.flag,
    required this.dialCode,
  });
}

const List<CountryCode> supportedCountries = [
  CountryCode(name: 'Indonesia', flag: '🇮🇩', dialCode: '+62'),
  CountryCode(name: 'Malaysia', flag: '🇲🇾', dialCode: '+60'),
  CountryCode(name: 'Singapura', flag: '🇸🇬', dialCode: '+65'),
  CountryCode(name: 'Filipina', flag: '🇵🇭', dialCode: '+63'),
  CountryCode(name: 'Thailand', flag: '🇹🇭', dialCode: '+66'),
  CountryCode(name: 'Vietnam', flag: '🇻🇳', dialCode: '+84'),
  CountryCode(name: 'Arab Saudi', flag: '🇸🇦', dialCode: '+966'),
  CountryCode(name: 'Amerika Serikat', flag: '🇺🇸', dialCode: '+1'),
  CountryCode(name: 'Inggris', flag: '🇬🇧', dialCode: '+44'),
  CountryCode(name: 'Australia', flag: '🇦🇺', dialCode: '+61'),
  CountryCode(name: 'Jepang', flag: '🇯🇵', dialCode: '+81'),
  CountryCode(name: 'Korea Selatan', flag: '🇰🇷', dialCode: '+82'),
];

