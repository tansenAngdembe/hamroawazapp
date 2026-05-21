import 'package:equatable/equatable.dart';

class UploadDocumentRequest extends Equatable {
  const UploadDocumentRequest({
    required this.citizenShipNumber,
    required this.nationalIdentityNumber,
    required this.provinceUniqueId,
    required this.districtUniqueId,
  });

  final String citizenShipNumber;
  final String nationalIdentityNumber;
  final int provinceUniqueId;
  final int districtUniqueId;

  Map<String, dynamic> toJson() => {
        'citizenShipNumber': citizenShipNumber,
        'nationalIdentityNumber': nationalIdentityNumber,
        'provinceUniqueId': provinceUniqueId,
        'districtUniqueId': districtUniqueId,
      };

  @override
  List<Object?> get props =>
      [citizenShipNumber, nationalIdentityNumber, provinceUniqueId, districtUniqueId];
}
