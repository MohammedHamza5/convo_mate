import '../../data/models/interest_model.dart';

abstract class InterestState {}

class InterestInitial extends InterestState {}

class InterestLoading extends InterestState {}

class InterestLoaded extends InterestState {
  final List<InterestModel> interests;
  final List<String> selectedInterests;

  InterestLoaded(this.interests, this.selectedInterests);
}

class InterestSaving extends InterestState {}

class InterestSaved extends InterestState {}

class InterestError extends InterestState {
  final String error;

  InterestError(this.error);
}