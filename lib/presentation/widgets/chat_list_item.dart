import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/repositories/user_presence_repository.dart';
import '../../../logic/providers/presence_provider.dart';

class ChatListItem extends StatefulWidget {
  final ChatModel chat;

  const ChatListItem({super.key, required this.chat});

  @override
  State<ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<ChatListItem> {
  PresenceProvider? _presenceProvider;
  bool _initialized = false;
  bool _isLoadingPresence = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_initialized) {
      _presenceProvider = Provider.of<PresenceProvider>(context, listen: false);
      if (widget.chat.otherUserId.isNotEmpty) {
        print('ChatListItem: Start watching user ${widget.chat.otherUserId}');
        _presenceProvider?.startWatchingUser(widget.chat.otherUserId);
        
        // Set a short delay to allow presence data to load
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isLoadingPresence = false;
            });
          }
        });
      } else {
        print('ChatListItem: Cannot watch user with empty ID');
        setState(() {
          _isLoadingPresence = false;
        });
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    if (_initialized && _presenceProvider != null && widget.chat.otherUserId.isNotEmpty) {
      print('ChatListItem: Stop watching user ${widget.chat.otherUserId}');
      _presenceProvider!.stopWatchingUser(widget.chat.otherUserId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: () {
        context.push('/chat/${widget.chat.chatId}');
      },
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24.r,
            backgroundImage: widget.chat.otherUserImage != null && widget.chat.otherUserImage!.isNotEmpty
                ? CachedNetworkImageProvider(widget.chat.otherUserImage!)
                : null,
            child: widget.chat.otherUserImage == null || widget.chat.otherUserImage!.isEmpty
                ? Text(
              widget.chat.otherUserName.isNotEmpty ? widget.chat.otherUserName[0].toUpperCase() : '',
              style: GoogleFonts.cairo(fontSize: 18.sp, color: Colors.white),
            )
                : null,
          ),
          // استخدام حالة التواجد الحقيقية بدلاً من الحالة في نموذج المحادثة
          Consumer<PresenceProvider>(
            builder: (context, provider, _) {
              // Display loading indicator while waiting for presence data
              if (_isLoadingPresence) {
                return Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDarkMode ? Colors.grey[800]! : Colors.white,
                        width: 2.w,
                      ),
                    ),
                  ),
                );
              }
              
              // Get presence data from the provider's map
              final String userId = widget.chat.otherUserId;
              if (userId.isEmpty) {
                return const SizedBox.shrink();
              }
              
              // Get presence data from the provider's usersPresenceData map
              final presenceData = provider.usersPresenceData[userId];
              
              // If still no presence data after loading period
              if (presenceData == null) {
                print('ChatListItem: No presence data for ${widget.chat.otherUserId}');
                return Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDarkMode ? Colors.grey[800]! : Colors.white,
                        width: 2.w,
                      ),
                    ),
                  ),
                );
              }
              
              final isOnline = presenceData['isOnline'] as bool? ?? false;
              final isGhostMode = presenceData['isGhostMode'] as bool? ?? false;
              
              print('ChatListItem: User ${widget.chat.otherUserId} status - online: $isOnline, ghostMode: $isGhostMode');
              
              // عرض نقطة التواجد فقط إذا كان المستخدم متصل وليس في وضع التخفي
              if (isOnline && !isGhostMode) {
                return Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDarkMode ? Colors.grey[800]! : Colors.white,
                        width: 2.w,
                      ),
                    ),
                  ),
                );
              }
              return Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12.w,
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[800]! : Colors.white,
                      width: 2.w,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      title: Text(
        widget.chat.otherUserName,
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.w600,
          fontSize: 16.sp,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Row(
        children: [
          // عرض حالة آخر ظهور مع آخر رسالة
          Expanded(
            child: Text(
              widget.chat.lastMessage.isNotEmpty 
                  ? widget.chat.lastMessage 
                  : localizations.noMessages,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          
          // إضافة نص حالة التواجد إذا كان المستخدم متصل
          Consumer<PresenceProvider>(
            builder: (context, provider, _) {
              // Skip showing presence text while loading
              if (_isLoadingPresence) {
                return const SizedBox.shrink();
              }
              
              // Only try to get presence data if the otherUserId is not empty
              final String userId = widget.chat.otherUserId;
              if (userId.isEmpty) {
                return const SizedBox.shrink();
              }
              
              // Get presence data from the provider's usersPresenceData map
              final presenceData = provider.usersPresenceData[userId];
              
              // Check for valid presence data
              if (presenceData == null) {
                return const SizedBox.shrink();
              }
              
              final isOnline = presenceData['isOnline'] as bool? ?? false;
              final isGhostMode = presenceData['isGhostMode'] as bool? ?? false;
              
              if (isOnline && !isGhostMode) {
                return Text(
                  ' • متصل',
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
              
              // If the user is not online or in ghost mode and we have a lastSeen timestamp,
              // we could show "last seen XX" here instead of nothing
              final lastSeen = presenceData['lastSeen'] as DateTime?;
              if (lastSeen != null && !isOnline && !isGhostMode) {
                return Text(
                  ' • ${UserPresenceRepository.formatLastSeen(lastSeen, shortFormat: true)}',
                  style: GoogleFonts.cairo(
                    fontSize: 10.sp,
                    color: Colors.grey,
                  ),
                );
              }
              
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatTime(widget.chat.lastMessageTime),
            style: GoogleFonts.cairo(
              fontSize: 12.sp,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          if (widget.chat.unreadCount > 0)
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Text(
                widget.chat.unreadCount.toString(),
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);
    if (date == today) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month}/${time.year.toString().substring(2)}';
    }
  }
}