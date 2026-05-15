import 'package:equatable/equatable.dart';

class UsageStatus extends Equatable {
  final bool isAllowed;
  final int remainingQuota;
  final String message;

  const UsageStatus({
    required this.isAllowed,
    required this.remainingQuota,
    required this.message,
  });

  @override
  List<Object?> get props => [isAllowed, remainingQuota, message];
}
