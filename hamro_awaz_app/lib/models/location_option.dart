import 'package:equatable/equatable.dart';

class LocationOption extends Equatable {
  const LocationOption({
    required this.uniqueId,
    required this.name,
  });

  final int uniqueId;
  final String name;

  @override
  List<Object?> get props => [uniqueId, name];
}
