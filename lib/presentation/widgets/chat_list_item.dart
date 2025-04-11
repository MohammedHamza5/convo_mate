import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/chat_model.dart';

class ChatListItem extends StatelessWidget {
  final ChatModel chat;

  const ChatListItem({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Hero(
        tag: 'profile_${chat.chatId}',
        child: CircleAvatar(
          radius: 25,
          backgroundImage: chat.otherUserImage != null
              ? CachedNetworkImageProvider(chat.otherUserImage!)
              : null,
          child: chat.otherUserImage == null
              ? Text(
            chat.otherUserName[0].toUpperCase(),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          )
              : null,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat.otherUserName,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chat.isOnline && !chat.isLastMessageSeen)
            const Icon(
              Icons.circle,
              color: Colors.green,
              size: 10,
            ),
        ],
      ),
      subtitle: Text(
        chat.lastMessage.isEmpty ? 'لا توجد رسائل بعد' : chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: chat.isLastMessageSeen ? Colors.grey : Colors.blue,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatTime(chat.lastMessageTime),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          if (chat.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Text(
                chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        context.go('/chat/${chat.chatId}'); // الانتقال إلى شاشة الدردشة باستخدام GoRouter
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays > 0) {
      return '${difference.inDays} أيام';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعات';
    } else {
      return '${difference.inMinutes} دقائق';
    }
  }
}