import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/repositories/chat_repositories.dart';
import '../../../logic/cubits/home_cubit.dart';
import '../../../logic/cubits/home_state.dart';
import '../../widgets/chat_list_item.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit(ChatRepositoryImpl())..loadConversations(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('ConvoMate', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                context.go('/search');
              },
            ),
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                context.go('/notifications');
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                context.go('/settings');
              },
            ),
          ],
        ),
        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading || state is HomeSearching) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is HomeLoaded) {
              return state.chats.isEmpty
                  ? Center(
                child: Text(
                  'لا توجد محادثات بعد!',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: state.chats.length,
                itemBuilder: (context, index) {
                  final chat = state.chats[index];
                  return Dismissible(
                    key: Key(chat.chatId),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      context.read<HomeCubit>().deleteChat(chat.chatId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم حذف محادثة ${chat.otherUserName}')),
                      );
                    },
                    child: ChatListItem(chat: chat),
                  );
                },
              );
            } else if (state is HomeSearchResult) {
              return ListView.builder(
                itemCount: state.users.length,
                itemBuilder: (context, index) {
                  final user = state.users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user.profileImage != null
                          ? NetworkImage(user.profileImage!)
                          : null,
                      child: user.profileImage == null ? Text(user.name[0]) : null,
                    ),
                    title: Text(
                      user.name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'اهتمامات: ${user.interests.join(', ')}',
                      style: GoogleFonts.poppins(),
                    ),
                    trailing: user.isOnline
                        ? const Icon(Icons.circle, color: Colors.green, size: 12)
                        : const Icon(Icons.circle, color: Colors.grey, size: 12),
                    onTap: () {
                      context.go('/new_chat'); // يمكن تعديله لإنشاء محادثة مع user.uid
                    },
                  );
                },
              );
            } else if (state is HomeError) {
              return Center(child: Text(state.message));
            }
            return Center(
              child: Text(
                'ابدأ محادثة جديدة!',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.go('/new_chat');
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}