part of 'upload_cubit.dart';

abstract class UploadState extends Equatable {
  const UploadState();

  @override
  List<Object?> get props => [];
}

class UploadInitial extends UploadState {}

class UploadLoading extends UploadState {
  final String message;
  
  const UploadLoading(this.message);
  
  @override
  List<Object?> get props => [message];
}

class UploadImageSelected extends UploadState {
  final File imageFile;

  const UploadImageSelected(this.imageFile);

  @override
  List<Object?> get props => [imageFile];
}

class UploadAudioSelected extends UploadState {
  final File audioFile;
  final int? duration; // مدة التسجيل بالثواني

  const UploadAudioSelected(this.audioFile, {this.duration});

  @override
  List<Object?> get props => [audioFile, duration];
  
  // تحويل المدة إلى نص مقروء
  String get formattedDuration {
    if (duration == null) return '00:00';
    final minutes = (duration! ~/ 60).toString().padLeft(2, '0');
    final seconds = (duration! % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class UploadRecording extends UploadState {
  final int duration; // مدة التسجيل الحالي بالثواني
  
  const UploadRecording({this.duration = 0});
  
  @override
  List<Object?> get props => [duration];
  
  // تحويل المدة إلى نص مقروء
  String get formattedDuration {
    final minutes = (duration ~/ 60).toString().padLeft(2, '0');
    final seconds = (duration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class UploadInProgress extends UploadState {
  final int progress;
  
  const UploadInProgress({this.progress = 0});
  
  @override
  List<Object?> get props => [progress];
}

class UploadSuccess extends UploadState {
  final String? imageUrl;
  final String? audioUrl;
  final int? audioDuration; // مدة الصوت بالثواني

  const UploadSuccess({this.imageUrl, this.audioUrl, this.audioDuration});

  @override
  List<Object?> get props => [imageUrl, audioUrl, audioDuration];
  
  // تحويل مدة الصوت إلى نص مقروء
  String get formattedDuration {
    if (audioDuration == null) return '00:00';
    final minutes = (audioDuration! ~/ 60).toString().padLeft(2, '0');
    final seconds = (audioDuration! % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class UploadError extends UploadState {
  final String message;

  const UploadError(this.message);

  @override
  List<Object?> get props => [message];
}