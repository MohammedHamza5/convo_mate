import 'package:equatable/equatable.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/user_model.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<ChatModel> chats;

  const HomeLoaded({required this.chats});

  @override
  List<Object> get props => [chats];
}

class HomeSearching extends HomeState {}

class HomeSearchResult extends HomeState {
  final List<UserModel> users;

  const HomeSearchResult(this.users);

  @override
  List<Object> get props => [users];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object> get props => [message];
}

class HomeLoggedOut extends HomeState {}

class HomeGhostModeToggled extends HomeState {
  final bool isEnabled;

  const HomeGhostModeToggled(this.isEnabled);

  @override
  List<Object> get props => [isEnabled];
}