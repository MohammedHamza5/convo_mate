import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'upload_state.dart';

// تعريف نوع الملف المستخدم في التطبيق
enum FileType {
  image,
  audio,
  video
}

class UploadCubit extends Cubit<UploadState> {
  final _picker = ImagePicker();
  final _recorder = FlutterSoundRecorder();
  final _player = FlutterSoundPlayer();
  
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  int _recordingDuration = 0;
  
  // تكوين Cloudinary للرفع بدون توقيع
  final _cloudName = 'dit1j9aed';
  final _uploadPreset = 'convomate';
  
  final _cloudinary = CloudinaryPublic(
    'dit1j9aed',       // معرف السحابة
    'convomate',       // اسم الإعداد المسبق غير الموقع
    cache: false
  );
  
  UploadCubit() : super(UploadInitial()) {
    // تهيئة الكيوبت بدون أي إسناد إضافي
  }

  // طريقة بديلة للرفع باستخدام HTTP مباشرة
  Future<String?> _uploadViaHttp(File file, String fileType) async {
    try {
      // التحقق من وجود الملف
      if (!await file.exists()) {
        return null;
      }
      
      // إنشاء طلب متعدد الأجزاء
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/auto/upload');
      
      final request = http.MultipartRequest('POST', uri);
      
      // إضافة معلمات الرفع
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = 'convomate';
      
      // إضافة الملف
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: path.basename(file.path),
      );
      request.files.add(multipartFile);
      
      // إرسال الطلب
      
      // استخدام timeout للتعامل مع مشكلة الاتصال
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('انتهت مهلة الاتصال أثناء الرفع');
        },
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      // تحليل الاستجابة
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String secureUrl = data['secure_url'];
        return secureUrl;
      } else {
        // محاولة تحليل رسالة الخطأ من الاستجابة
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['error']?['message'] ?? 'خطأ غير معروف';
          // تجاهل رسالة الخطأ
        } catch (parseError) {
          // تجاهل خطأ التحليل
        }
        
        return null;
      }
    } catch (e) {
      // تجاهل الاستثناء
      return null;
    }
  }

  Future<void> pickImage() async {
    try {
      emit(UploadLoading("جاري اختيار الصورة..."));
      final picker = ImagePicker();
      
      // اختيار الصورة مع ضغطها للحصول على حجم أصغر
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 70,
        maxWidth: 1000,
        maxHeight: 1000,
      );
      
      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        
        // إصدار حالة تم اختيار الصورة
        emit(UploadImageSelected(imageFile));
        
        // بدء عملية الرفع تلقائيًا بعد اختيار الصورة
        await uploadFiles(
          files: [imageFile],
          userUid: FirebaseAuth.instance.currentUser?.uid ?? '',
          type: 'image'
        );
      } else {
        emit(UploadInitial());
      }
    } catch (e) {
      emit(UploadError('فشل في اختيار الصورة: $e'));
    }
  }

  Future<void> startRecording() async {
    try {
      final tempDir = await getTemporaryDirectory();
      _currentRecordingPath = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';

      // تهيئة مسجل الصوت إذا لم يكن مفتوح بعد
      if (await _recorder.isRecording == false) {
        await _recorder.openRecorder();
      }

      // بدء التسجيل
      await _recorder.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacADTS,
      );

      _recordingStartTime = DateTime.now();
      _recordingDuration = 0;
      
      // بدء مؤقت لتحديث مدة التسجيل
      _startRecordingTimer();
      
      // إخبار واجهة المستخدم بأن التسجيل قد بدأ
      emit(UploadRecording(duration: _recordingDuration));
    } catch (e) {
      emit(UploadError('فشل بدء التسجيل: $e'));
    }
  }

  void _startRecordingTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (await _recorder.isRecording == false) return false;
      
      _recordingDuration++;
      emit(UploadRecording(duration: _recordingDuration));
      return true;
    });
  }

  Future<void> stopRecording() async {
    try {
      if (await _recorder.isRecording) {
        final path = await _recorder.stopRecorder();
        
        // التأكد من أن المسار صالح
        if (path != null && File(path).existsSync()) {
          final audioFile = File(path);
          final duration = _recordingDuration;
          
          // إرسال حالة نجاح التحميل
          emit(UploadAudioSelected(audioFile, duration: duration));
          
          // بدء عملية الرفع تلقائيًا
          await uploadFiles(
            files: [audioFile],
            userUid: FirebaseAuth.instance.currentUser?.uid ?? '',
            type: 'audio'
          );
        } else {
          emit(UploadError('ملف التسجيل غير موجود'));
        }
      } else {
        emit(UploadError('لا يوجد تسجيل نشط لإيقافه'));
      }
    } catch (e) {
      emit(UploadError('فشل إيقاف التسجيل: $e'));
    }
  }

  Future<void> cancelRecording() async {
    try {
      if (await _recorder.isRecording) {
        await _recorder.stopRecorder();
      }
      emit(UploadInitial());
    } catch (e) {
      emit(UploadError('فشل في إلغاء التسجيل: $e'));
    }
  }

  // وظيفة احتياطية لتخزين الملف محليًا في حالة فشل الرفع إلى Cloudinary
  Future<String> _storeLocallyAsBackup(File file, {bool isFromCamera = false}) async {
    try {
      // التحقق من وجود الملف
      if (!await file.exists()) {
        return file.path; // استخدام المسار الأصلي في حالة حدوث أي خطأ
      }
      
      // الحصول على المجلد المؤقت
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      
      // نسخ الملف
      final copiedFile = await file.copy(targetPath);
      
      if (await copiedFile.exists()) {
        return copiedFile.path;
      } else {
        return file.path; // استخدام المسار الأصلي كخطة بديلة
      }
    } catch (e) {
      return file.path; // استخدام المسار الأصلي في حالة حدوث أي خطأ
    }
  }

  Future<void> uploadFiles({
    required List<File> files,
    required String userUid,
    required String type,
    bool isFromCamera = false,
  }) async {
    try {
      // فحص أولي لقائمة الملفات
      if (files.isEmpty) {
        emit(const UploadError('قائمة الملفات فارغة'));
        return;
      }
      
      emit(UploadInProgress(progress: 0));
      
      final List<String> uploadedUrls = [];
      int completedUploads = 0;
      
      for (var file in files) {
        try {
          // التحقق من وجود الملف
          if (!await file.exists()) {
            completedUploads++;
            continue;
          }
          
          // التخزين المحلي أولاً كنسخة احتياطية
          final localUrl = await _storeLocallyAsBackup(file, isFromCamera: isFromCamera);
          
          if (localUrl != null) {
            uploadedUrls.add(localUrl);
            
            // محاولة الرفع إلى السحابة في الخلفية
            _tryCloudUploadInBackground(file, localUrl);
            
            // تحديث التقدم
            completedUploads++;
            final progress = (completedUploads / files.length) * 100;
            emit(UploadInProgress(progress: progress.round()));
          } else {
            // مواصلة المحاولة مع الملفات الأخرى
          }
        } catch (fileError) {
          // مواصلة المحاولة مع الملفات الأخرى بدلاً من فشل العملية بالكامل
        }
      }
      
      // التحقق من نتيجة التحميل
      if (uploadedUrls.isEmpty) {
        emit(const UploadError('فشل تحميل جميع الملفات'));
      } else {
        emit(UploadSuccess(imageUrl: type == 'image' ? uploadedUrls.first : null, 
                           audioUrl: type == 'audio' ? uploadedUrls.first : null,
                           audioDuration: type == 'audio' ? _recordingDuration : null));
      }
    } catch (e) {
      emit(UploadError(e.toString()));
    }
  }
  
  // محاولة الرفع إلى السحابة في الخلفية بعد أن تم بالفعل تخزين الملف محليًا
  void _tryCloudUploadInBackground(File file, String localUrl) {
    // استخدام future مستقل مع تجاهل الاستثناءات للعمل في الخلفية
    () async {
      try {
        final cloudUrl = await _uploadToCloudInBackground(file);
        
        // هنا يمكن تحديث قاعدة البيانات بالرابط السحابي لاستخدامه بدلاً من المسار المحلي
      } catch (e) {
        // تجاهل الخطأ واستمر باستخدام المسار المحلي
      }
    }();
  }
  
  // وظيفة لرفع الملف إلى السحابة في الخلفية
  Future<String?> _uploadToCloudInBackground(File file) async {
    try {
      // تحقق من وجود الملف واتصال الإنترنت قبل المحاولة
      if (!await file.exists()) {
        return null;
      }
      
      // محاولة الرفع باستخدام الطريقة البديلة أولاً
      var cloudUrl = await _uploadViaHttp(file, 'file');
      
      // إذا فشلت المحاولة البديلة، جرب الطريقة الأصلية
      if (cloudUrl == null) {
        try {
          final response = await _cloudinary.uploadFile(
            CloudinaryFile.fromFile(
              file.path,
              resourceType: CloudinaryResourceType.Auto,
            ),
          );
          cloudUrl = response.secureUrl;
        } catch (e) {
          return null;
        }
      }
      
      return cloudUrl;
    } catch (e) {
      return null;
    }
  }

  void clear() {
    emit(UploadInitial());
  }

  @override
  Future<void> close() async {
    // التخلص من الموارد
    try {
      if (await _recorder.isRecording == false) {
        await _recorder.closeRecorder();
      } else {
        await _recorder.stopRecorder();
        await _recorder.closeRecorder();
      }
      await _player.closePlayer();
    } catch (e) {
      // تجاهل الخطأ
    }
    return super.close();
  }
}