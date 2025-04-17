part of 'settings_cubit.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final bool notificationsEnabled;
  final String language;

  const SettingsLoaded({
    required this.notificationsEnabled,
    required this.language,
  });

  @override
  List<Object> get props => [notificationsEnabled, language];
}

class SettingsError extends SettingsState {
  final String key;
  final Map<String, String> params;

  const SettingsError(this.key, {this.params = const {}});

  @override
  List<Object> get props => [key, params];
}