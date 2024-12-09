import 'package:equatable/equatable.dart';

class NavigationState extends Equatable {
  final String route;
  final Map<String, dynamic>? params;

  const NavigationState({
    required this.route,
    this.params,
  });

  @override
  List<Object?> get props => [route, params];
} 