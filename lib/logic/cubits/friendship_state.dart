abstract class FriendshipState {}

class FriendshipInitial extends FriendshipState {}

class FriendshipLoading extends FriendshipState {}

class FriendshipRequestSent extends FriendshipState {}

class FriendshipRequestAccepted extends FriendshipState {}

class FriendshipRequestDeclined extends FriendshipState {}

class FriendshipRemoved extends FriendshipState {}

class FriendshipError extends FriendshipState {
  final String error;

  FriendshipError(this.error);
}