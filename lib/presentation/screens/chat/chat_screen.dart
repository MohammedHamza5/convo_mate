import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/services.dart'; // لدعم نسخ النص
import 'package:provider/provider.dart';
import '../../../data/models/message_model.dart';
import '../../../data/repositories/chat_repositories.dart';
import '../../../data/repositories/user_presence_repository.dart';
import '../../../logic/cubits/chat_cubit.dart';
import '../../../logic/providers/presence_provider.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _editMessageController = TextEditingController();
  bool _isTyping = false;
  bool _isSending = false;
  bool _isEditing = false;
  String? _editingMessageId;
  MessageModel? _replyToMessage;
  late AnimationController _textAnimationController;
  late Animation<Offset> _textAnimation;
  PresenceProvider? _presenceProvider;
  ChatCubit? _chatCubit;

  @override
  void initState() {
    super.initState();
    _textAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _textAnimation = Tween<Offset>(
      begin: Offset(0.2.w, 0),
      end: Offset(-0.2.w, 0),
    ).animate(
      CurvedAnimation(
        parent: _textAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Reset unread count when opening this conversation
    Future.delayed(Duration.zero, () {
      try {
        final cubit = context.read<ChatCubit>();
        // Mark messages as read for the current user
        cubit.markMessagesAsRead();
      } catch (e) {
        print('Error marking messages as read: $e');
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _presenceProvider = Provider.of<PresenceProvider>(context, listen: false);
    try {
      _chatCubit = BlocProvider.of<ChatCubit>(context);
    } catch (e) {
      // The ChatCubit might not be available yet, which is fine
      // It will be created in the build method
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryGradient = LinearGradient(
      colors:
          isDarkMode
              ? [Colors.blueGrey.shade700, Colors.blueGrey.shade500]
              : [Colors.blue.shade400, Colors.blue.shade200],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return BlocProvider(
      create:
          (context) =>
              ChatCubit(ChatRepositoryImpl(), widget.chatId)..loadMessages(),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 100.h,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(gradient: primaryGradient),
                ),
                title: BlocBuilder<ChatCubit, ChatState>(
                  builder: (context, state) {
                    if (state is ChatLoaded) {
                      final chat = state.chat;

                      // بدء مراقبة حالة المستخدم الآخر
                      if (_presenceProvider != null) {
                        _presenceProvider!.startWatchingUser(chat.otherUserId);
                      }

                      return Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              context.push('/profile/${chat.otherUserId}');
                            },
                            child: Hero(
                              tag: 'profile_${widget.chatId}',
                              child: CircleAvatar(
                                radius: 20.r,
                                backgroundImage:
                                    chat.otherUserImage != null &&
                                            chat.otherUserImage!.isNotEmpty
                                        ? CachedNetworkImageProvider(
                                          chat.otherUserImage!,
                                        )
                                        : null,
                                child:
                                    chat.otherUserImage == null ||
                                            chat.otherUserImage!.isEmpty
                                        ? Text(
                                          chat.otherUserName[0].toUpperCase(),
                                          style: GoogleFonts.cairo(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16.sp,
                                          ),
                                        )
                                        : null,
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                context.push('/profile/${chat.otherUserId}');
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chat.otherUserName,
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.sp,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  // عرض حالة الاتصال باستخدام مزود التواجد
                                  Consumer<PresenceProvider>(
                                    builder: (context, presenceProvider, _) {
                                      if (chat.otherUserId.isEmpty) {
                                        print(
                                          'ChatScreen: Cannot show online status - empty otherUserId',
                                        );
                                        return const SizedBox.shrink();
                                      }

                                      // Use the cached presence data instead of the Stream
                                      final presenceData =
                                          presenceProvider.usersPresenceData[chat
                                              .otherUserId];
                                      if (presenceData == null) {
                                        print(
                                          'ChatScreen: No presence data for ${chat.otherUserId}',
                                        );
                                        return Text(
                                          'غير متصل',
                                          style: GoogleFonts.cairo(
                                            fontSize: 12.sp,
                                            color: Colors.white70,
                                          ),
                                        );
                                      }

                                      final isOnline =
                                          presenceData['isOnline'] as bool? ??
                                          false;
                                      final isGhostMode =
                                          presenceData['isGhostMode'] as bool? ??
                                          false;

                                      print(
                                        'ChatScreen: User ${chat.otherUserId} status - online: $isOnline, ghostMode: $isGhostMode',
                                      );

                                      // عرض "متصل" فقط إذا كان المستخدم متصل وليس في وضع التخفي
                                      final isUserVisible =
                                          isOnline && !isGhostMode;

                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 500,
                                            ),
                                            width: 8.w,
                                            height: 8.h,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                                  isUserVisible
                                                      ? Colors.green
                                                      : Colors.grey,
                                            ),
                                          ),
                                          SizedBox(width: 4.w),
                                          Flexible(
                                            child: Text(
                                              isUserVisible
                                                  ? localizations.online
                                                  : _getLastSeenText(
                                                    presenceProvider,
                                                    chat.otherUserId,
                                                  ),
                                              style: GoogleFonts.cairo(
                                                fontSize: 12.sp,
                                                color: Colors.white70,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
                onPressed: () => context.go('/home'),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            SliverFillRemaining(
              child: Column(
                children: [
                  Expanded(
                    child: BlocBuilder<ChatCubit, ChatState>(
                      builder: (context, state) {
                        if (state is ChatLoading) {
                          return Center(
                            child: CircularProgressIndicator(strokeWidth: 4.w),
                          );
                        } else if (state is ChatLoaded) {
                          return ListView.builder(
                            reverse: true,
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            itemCount: state.messages.length,
                            itemBuilder: (context, index) {
                              final message = state.messages[index];
                              final isMe =
                                  message.senderId ==
                                  FirebaseAuth.instance.currentUser?.uid;
                              return SlideInRight(
                                duration: const Duration(milliseconds: 300),
                                delay: Duration(milliseconds: index * 50),
                                from: isMe ? 50.w : -50.w,
                                child: GestureDetector(
                                  onLongPress:
                                      () => _showMessageOptions(
                                        context,
                                        message,
                                        isMe,
                                      ),
                                  child: _buildMessageBubble(
                                    context,
                                    message,
                                    isMe,
                                    localizations,
                                    state.messages,
                                  ),
                                ),
                              );
                            },
                          );
                        } else if (state is ChatError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  localizations.chatError(state.message),
                                  style: GoogleFonts.cairo(fontSize: 16.sp),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16.h),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    context.read<ChatCubit>().loadMessages();
                                  },
                                  icon: Icon(Icons.refresh, size: 18.sp),
                                  label: Text(
                                    localizations.retry,
                                    style: GoogleFonts.cairo(fontSize: 14.sp),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return Center(
                          child: Text(
                            localizations.startConversation,
                            style: GoogleFonts.cairo(fontSize: 16.sp),
                          ),
                        );
                      },
                    ),
                  ),
                  Builder(
                    builder:
                        (context) => _buildInputField(context, localizations),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(
    BuildContext context,
    MessageModel message,
    bool isMe,
  ) {
    final localizations = AppLocalizations.of(context)!;
    final chatCubit = context.read<ChatCubit>();

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15.r)),
      ),
      builder:
          (bottomSheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.message.isNotEmpty)
                  ListTile(
                    leading: Icon(Icons.copy, size: 20.sp),
                    title: Text(
                      localizations.copy,
                      style: GoogleFonts.cairo(fontSize: 14.sp),
                    ),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: message.message));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            localizations.messageCopied,
                            style: GoogleFonts.cairo(fontSize: 14.sp),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(bottomSheetContext);
                    },
                  ),
                ListTile(
                  leading: Icon(Icons.reply, size: 20.sp),
                  title: Text(
                    localizations.reply,
                    style: GoogleFonts.cairo(fontSize: 14.sp),
                  ),
                  onTap: () {
                    setState(() {
                      _replyToMessage = message;
                    });
                    metering:
                    1.0;
                    Navigator.pop(bottomSheetContext);
                  },
                ),
                if (isMe && message.message.isNotEmpty)
                  ListTile(
                    leading: Icon(Icons.edit, size: 20.sp),
                    title: Text(
                      localizations.edit,
                      style: GoogleFonts.cairo(fontSize: 14.sp),
                    ),
                    onTap: () {
                      setState(() {
                        _isEditing = true;
                        _editingMessageId = message.messageId;
                        _editMessageController.text = message.message;
                      });
                      Navigator.pop(bottomSheetContext);
                    },
                  ),
                if (isMe)
                  ListTile(
                    leading: Icon(Icons.delete, size: 20.sp, color: Colors.red),
                    title: Text(
                      localizations.delete,
                      style: GoogleFonts.cairo(
                        fontSize: 14.sp,
                        color: Colors.red,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(bottomSheetContext); // إغلاق قائمة الخيارات

                      // عرض مؤشر تقدم
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext dialogContext) {
                          return Dialog(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(strokeWidth: 3.w),
                                    SizedBox(height: 10.h),
                                    Text(
                                      localizations.deletingMessage,
                                      style: GoogleFonts.cairo(
                                        fontSize: 14.sp,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                      // حذف الرسالة باستخدام مرجع chatCubit المحفوظ مسبقًا
                      chatCubit
                          .deleteMessage(message.messageId)
                          .then((_) {
                            // إغلاق مؤشر التقدم بعد الانتهاء
                            Navigator.of(context, rootNavigator: true).pop();

                            // إظهار إشعار بنجاح الحذف
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  localizations.messageDeleted,
                                  style: GoogleFonts.cairo(fontSize: 14.sp),
                                ),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          })
                          .catchError((error) {
                            // إغلاق مؤشر التقدم في حالة الخطأ
                            Navigator.of(context, rootNavigator: true).pop();
                          });
                    },
                  ),
              ],
            ),
          ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    MessageModel message,
    bool isMe,
    AppLocalizations localizations,
    List<MessageModel> messages,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final repliedMessage =
        message.replyTo != null
            ? messages.firstWhere(
              (m) => m.messageId == message.replyTo,
              orElse:
                  () => MessageModel(
                    messageId: '',
                    senderId: '',
                    message: localizations.messageDeleted,
                    isSeen: false,
                    timestamp: DateTime.now(),
                  ),
            )
            : null;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color:
                    isMe
                        ? (isDarkMode
                            ? Colors.blue.shade600
                            : Colors.blue.shade400)
                        : isDarkMode
                        ? Colors.grey.shade700.withOpacity(0.8)
                        : Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isMe ? 12.r : 0),
                  topRight: Radius.circular(isMe ? 0 : 12.r),
                  bottomLeft: Radius.circular(12.r),
                  bottomRight: Radius.circular(12.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isMe ? 0.15 : 0.1),
                    blurRadius: 6.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
                border: Border.all(
                  color:
                      isMe
                          ? Colors.blue.shade200.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                  width: 0.5.w,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (repliedMessage != null)
                    Container(
                      padding: EdgeInsets.all(8.w),
                      margin: EdgeInsets.only(bottom: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        repliedMessage.message,
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          color: isMe ? Colors.white70 : Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder:
                              (_) => Dialog(
                                backgroundColor: Colors.transparent,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10.r),
                                  child: CachedNetworkImage(
                                    imageUrl: message.imageUrl!,
                                    fit: BoxFit.contain,
                                    placeholder:
                                        (context, url) =>
                                            CircularProgressIndicator(
                                              strokeWidth: 4.w,
                                            ),
                                    errorWidget:
                                        (context, url, error) =>
                                            Icon(Icons.error, size: 24.sp),
                                  ),
                                ),
                              ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6.r),
                        child: CachedNetworkImage(
                          imageUrl: message.imageUrl!,
                          width: 120.w,
                          height: 120.h,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) =>
                                  CircularProgressIndicator(strokeWidth: 4.w),
                          errorWidget:
                              (context, url, error) =>
                                  Icon(Icons.error, size: 24.sp),
                        ),
                      ),
                    ),
                  if (message.audioUrl != null && message.audioUrl!.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.play_circle,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    localizations.playAudioInDevelopment,
                                    style: GoogleFonts.cairo(fontSize: 14.sp),
                                  ),
                                ),
                              );
                            },
                          ),
                          Container(
                            width: 80.w,
                            height: 3.h,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: 0.6,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '0:15',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (message.message.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            message.message,
                            style: GoogleFonts.cairo(
                              color:
                                  isMe
                                      ? Colors.white
                                      : isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                        if (message.isEdited)
                          Padding(
                            padding: EdgeInsets.only(right: 4.w),
                            child: Text(
                              '(${localizations.edited})',
                              style: GoogleFonts.cairo(
                                fontSize: 10.sp,
                                color: isMe ? Colors.white70 : Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatRelativeTime(message.timestamp, localizations),
                        style: GoogleFonts.cairo(
                          fontSize: 8.sp,
                          color: isMe ? Colors.white70 : Colors.grey,
                        ),
                      ),
                      if (isMe) ...[
                        SizedBox(width: 4.w),
                        _buildMessageStatusIcon(message),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              right: isMe ? -8.w : null,
              left: isMe ? null : -8.w,
              child: CustomPaint(
                size: Size(8.w, 8.h),
                painter: ChatBubbleTail(isMe: isMe, isDarkMode: isDarkMode),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageStatusIcon(MessageModel message) {
    // اختيار الرمز المناسب والألوان لحالة الرسالة بشكل أكثر وضوحًا
    IconData icon;
    Color iconColor;
    String statusText;

    if (message.messageId.startsWith('temp_')) {
      // الرسالة قيد الإرسال (مؤقتة)
      icon = Icons.access_time;
      iconColor = Colors.white70;
      statusText = 'جارٍ الإرسال';
    } else if (message.isRead) {
      // الرسالة مقروءة
      icon = Icons.done_all;
      iconColor = Colors.lightBlueAccent;
      statusText = 'تم القراءة';
    } else if (message.isDelivered) {
      // الرسالة تم تسليمها ولكن لم تُقرأ بعد
      icon = Icons.done_all;
      iconColor = Colors.white70;
      statusText = 'تم التسليم';
    } else {
      // الرسالة تم إرسالها ولكن لم يتم تسليمها بعد
      icon = Icons.done;
      iconColor = Colors.white70;
      statusText = 'تم الإرسال';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12.sp, color: iconColor),
        SizedBox(width: 2.w),
        Text(
          statusText,
          style: GoogleFonts.cairo(
            fontSize: 8.sp,
            color: iconColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_replyToMessage != null || _isEditing)
            Container(
              padding: EdgeInsets.all(8.w),
              color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing
                          ? localizations.editingMessage
                          : localizations.replyingTo(_replyToMessage!.message),
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18.sp),
                    onPressed: () {
                      setState(() {
                        _replyToMessage = null;
                        _isEditing = false;
                        _editingMessageId = null;
                        _editMessageController.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.attach_file,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  size: 20.sp,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        localizations.attachFilesInDevelopment,
                        style: GoogleFonts.cairo(fontSize: 14.sp),
                      ),
                    ),
                  );
                },
              ),
              Expanded(
                child: TextField(
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  controller:
                      _isEditing ? _editMessageController : _messageController,
                  onChanged: (value) {
                    setState(() {
                      _isTyping = value.trim().isNotEmpty;
                    });
                    if (value.isEmpty) {
                      _textAnimationController.forward(from: 0);
                    } else {
                      _textAnimationController.stop();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: '',
                    hintStyle: GoogleFonts.cairo(
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      fontSize: 14.sp,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.r),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    suffix:
                        _isTyping
                            ? null
                            : SlideTransition(
                              position: _textAnimation,
                              child: Text(
                                localizations.typeYourMessage,
                                style: GoogleFonts.cairo(
                                  color:
                                      isDarkMode
                                          ? Colors.grey[500]
                                          : Colors.grey[600],
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                  ),
                  style: GoogleFonts.cairo(fontSize: 14.sp),
                  textDirection: TextDirection.ltr,
                ),
              ),
              SizedBox(width: 6.w),
              AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: _isTyping ? 1.0 : 0.8,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor:
                      _isTyping
                          ? (isDarkMode
                              ? Colors.blueGrey
                              : Colors.blue.shade400)
                          : Colors.grey,
                  onPressed:
                      _isTyping && !_isSending
                          ? () async {
                            setState(() {
                              _isSending = true;
                            });
                            final messageText =
                                (_isEditing
                                        ? _editMessageController
                                        : _messageController)
                                    .text
                                    .trim();
                            try {
                              if (_isEditing && _editingMessageId != null) {
                                context.read<ChatCubit>().editMessage(
                                  _editingMessageId!,
                                  messageText,
                                );
                                setState(() {
                                  _isEditing = false;
                                  _editingMessageId = null;
                                  _editMessageController.clear();
                                });
                              } else {
                                context.read<ChatCubit>().sendMessage(
                                  messageText,
                                  replyTo: _replyToMessage?.messageId,
                                );
                                _messageController.clear();
                                setState(() {
                                  _replyToMessage = null;
                                });
                              }
                              setState(() {
                                _isTyping = false;
                                _isSending = false;
                              });
                              _textAnimationController.forward(from: 0);
                            } catch (e) {
                              setState(() {
                                _isSending = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _isEditing
                                        ? localizations.failedToEditMessage(
                                          e.toString(),
                                        )
                                        : localizations.failedToSendMessage(
                                          e.toString(),
                                        ),
                                    style: GoogleFonts.cairo(fontSize: 14.sp),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                          : null,
                  child:
                      _isSending
                          ? SizedBox(
                            width: 18.w,
                            height: 18.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.w,
                              valueColor: const AlwaysStoppedAnimation(
                                Colors.white,
                              ),
                            ),
                          )
                          : Icon(Icons.send, color: Colors.white, size: 18.sp),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime time, AppLocalizations localizations) {
    final locale = Localizations.localeOf(context).languageCode;
    int hour = time.hour;
    String minute = time.minute.toString().padLeft(2, '0');

    if (locale == 'ar') {
      String period = hour >= 12 ? localizations.pm : localizations.am;
      hour = hour % 12;
      hour = hour == 0 ? 12 : hour;
      String hourStr = hour.toString().padLeft(2, '0');
      return localizations.timeFormat(hourStr, minute, period);
    } else {
      String hourStr = hour.toString().padLeft(2, '0');
      return localizations.timeFormat(hourStr, minute, '');
    }
  }

  // دالة لعرض نص آخر ظهور في صيغة مناسبة
  String _getLastSeenText(PresenceProvider presenceProvider, String userId) {
    if (userId.isEmpty) {
      print('ChatScreen: Cannot get last seen for empty userId');
      return 'غير متصل';
    }

    // Use the cached presence data from the usersPresenceData map
    final presenceData = presenceProvider.usersPresenceData[userId];
    if (presenceData == null) {
      print('ChatScreen: No presence data for lastSeen of $userId');
      return 'غير متصل';
    }

    final lastSeen = presenceData['lastSeen'] as DateTime?;
    if (lastSeen == null) {
      print('ChatScreen: lastSeen is null for $userId');
      return 'غير متصل';
    }

    print('ChatScreen: Last seen for $userId: $lastSeen');
    // Use the shortFormat parameter to get a more compact last seen text
    return UserPresenceRepository.formatLastSeen(lastSeen, shortFormat: true);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _editMessageController.dispose();
    _textAnimationController.dispose();

    // إيقاف مراقبة حالة المستخدم عند الخروج من الشاشة
    if (_chatCubit != null) {
      final state = _chatCubit!.state;
      if (state is ChatLoaded && _presenceProvider != null) {
        final chat = state.chat;
        _presenceProvider!.stopWatchingUser(chat.otherUserId);
      }
    }

    super.dispose();
  }
}

class ChatBubbleTail extends CustomPainter {
  final bool isMe;
  final bool isDarkMode;

  ChatBubbleTail({required this.isMe, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color =
              isMe
                  ? (isDarkMode ? Colors.blue.shade600 : Colors.blue.shade400)
                  : isDarkMode
                  ? Colors.grey.shade700.withOpacity(0.8)
                  : Colors.white.withOpacity(0.95)
          ..style = PaintingStyle.fill;

    final path = Path();
    if (isMe) {
      path.moveTo(0, 0);
      path.quadraticBezierTo(0, size.height / 2, size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
    } else {
      path.moveTo(size.width, 0);
      path.quadraticBezierTo(size.width, size.height / 2, 0, size.height);
      path.lineTo(size.width, size.height);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
