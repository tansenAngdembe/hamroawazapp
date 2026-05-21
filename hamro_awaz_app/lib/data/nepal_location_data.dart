import '../models/location_option.dart';

/// Static province/district options until a backend list API is available.
/// Replace [uniqueId] values with IDs from your environment when known.
class NepalLocationData {
  NepalLocationData._();

  static const List<LocationOption> provinces = [
    LocationOption(uniqueId: 1, name: 'Bagmati Province'),
    LocationOption(uniqueId: 2, name: 'Gandaki Province'),
    LocationOption(uniqueId: 3, name: 'Koshi Province'),
    LocationOption(uniqueId: 4, name: 'Madhesh Province'),
    LocationOption(uniqueId: 5, name: 'Lumbini Province'),
    LocationOption(uniqueId: 6, name: 'Karnali Province'),
    LocationOption(uniqueId: 7, name: 'Sudurpashchim Province'),
  ];

  static List<LocationOption> districtsForProvince(int provinceId) {
    switch (provinceId) {
      case 1:
        return const [
          LocationOption(uniqueId: 101, name: 'Kathmandu'),
          LocationOption(uniqueId: 102, name: 'Lalitpur'),
          LocationOption(uniqueId: 103, name: 'Bhaktapur'),
        ];
      case 2:
        return const [
          LocationOption(uniqueId: 201, name: 'Kaski'),
          LocationOption(uniqueId: 202, name: 'Gorkha'),
        ];
      default:
        return const [
          LocationOption(uniqueId: 901, name: 'District A'),
          LocationOption(uniqueId: 902, name: 'District B'),
        ];
    }
  }
}
