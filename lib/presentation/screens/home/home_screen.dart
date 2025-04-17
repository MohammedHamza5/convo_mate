import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chat_repositories.dart';
import '../../../logic/cubits/home_cubit.dart';
import '../../../logic/cubits/home_state.dart';
import '../../widgets/chat_list_item.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // دالة مساعدة للتنقل الآمن
  void safePush(BuildContext context, String path) {
    final currentPath = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    if (currentPath != path) {
      context.push(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 4.w)));
    }

    return BlocProvider(
      create: (context) => HomeCubit(ChatRepositoryImpl())..loadConversations(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            localizations.appName,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20.sp),
          ),
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          foregroundColor: isDarkMode ? Colors.white : Colors.black87,
          actions: [
            IconButton(
              icon: Icon(Icons.search, size: 24.sp),
              onPressed: () {
                context.go('/search');
              },
            ),
            IconButton(
              icon: Icon(Icons.notifications, size: 24.sp),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      localizations.notificationsInDevelopment,
                      style: GoogleFonts.cairo(fontSize: 14.sp),
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.settings, size: 24.sp),
              onPressed: () {
                safePush(context, '/settings');
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: isDarkMode ? Colors.blueGrey : Colors.blue,
          onPressed: () {
            _showFriendsList(context, userId);
          },
          child: Icon(Icons.message, size: 24.sp),
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) {
                  if (state is HomeLoading || state is HomeSearching) {
                    return Center(child: CircularProgressIndicator(strokeWidth: 4.w));
                  } else if (state is HomeLoaded) {
                    return state.chats.isEmpty
                        ? Center(
                      child: Text(
                        localizations.noConversations,
                        style: GoogleFonts.cairo(fontSize: 16.sp),
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
                            padding: EdgeInsets.only(right: 16.w),
                            child: Icon(Icons.delete, color: Colors.white, size: 24.sp),
                          ),
                          onDismissed: (direction) {
                            context.read<HomeCubit>().deleteChat(chat.chatId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  localizations.deleteChat(chat.otherUserName),
                                  style: GoogleFonts.cairo(fontSize: 14.sp),
                                ),
                              ),
                            );
                          },
                          child: ChatListItem(
                            chat: chat,
                          ),
                        );
                      },
                    );
                  } else if (state is HomeError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            localizations.errorMessage(state.message),
                            style: GoogleFonts.cairo(fontSize: 16.sp),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16.h),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.read<HomeCubit>().loadConversations();
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
                      localizations.startNewConversation,
                      style: GoogleFonts.cairo(fontSize: 16.sp),
                    ),
                  );
                },
              ),
            ),
            Divider(
              height: 2.h,
              thickness: 1.w,
              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
            ),
            SizedBox(height: 40.h),
            Divider(
              height: 2.h,
              thickness: 1.w,
              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Text(
                localizations.suggestedUsers,
                style: GoogleFonts.cairo(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, currentUserSnapshot) {
                  if (!currentUserSnapshot.hasData) {
                    return Center(child: CircularProgressIndicator(strokeWidth: 4.w));
                  }
                  final currentUser = UserModel.fromFirestore(currentUserSnapshot.data!);
                  final userInterests = currentUser.interests;
                  final userFriends = List<String>.from(currentUser.friends ?? []);

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('uid', isNotEqualTo: userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(strokeWidth: 4.w));
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            localizations.errorFetchingUsers,
                            style: GoogleFonts.cairo(fontSize: 16.sp),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            localizations.noUsersAvailable,
                            style: GoogleFonts.cairo(fontSize: 16.sp),
                          ),
                        );
                      }

                      final users = snapshot.data!.docs
                          .map((doc) => UserModel.fromFirestore(doc))
                          .where((user) =>
                      !userFriends.contains(user.uid) &&
                          user.interests.any((interest) => userInterests.contains(interest)))
                          .toList();

                      users.sort((a, b) {
                        final aCommon =
                            a.interests.where((i) => userInterests.contains(i)).length;
                        final bCommon =
                            b.interests.where((i) => userInterests.contains(i)).length;
                        return bCommon.compareTo(aCommon);
                      });

                      final suggestedUsers = users.take(3).toList();

                      if (suggestedUsers.isEmpty) {
                        return Center(
                          child: Text(
                            localizations.noUsersWithSharedInterests,
                            style: GoogleFonts.cairo(fontSize: 16.sp),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: suggestedUsers.length,
                        itemBuilder: (context, index) {
                          final user = suggestedUsers[index];
                          final commonInterests = user.interests
                              .where((interest) => userInterests.contains(interest))
                              .toList();
                          return Card(
                            color: isDarkMode ? Colors.grey[850] : Colors.white,
                            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: user.profileImage != null &&
                                    user.profileImage!.isNotEmpty
                                    ? NetworkImage(user.profileImage!)
                                    : null,
                                child: user.profileImage == null || user.profileImage!.isEmpty
                                    ? Text(
                                  user.name[0].toUpperCase(),
                                  style: GoogleFonts.cairo(fontSize: 16.sp),
                                )
                                    : null,
                              ),
                              title: Text(
                                user.name,
                                style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w600, fontSize: 16.sp),
                              ),
                              subtitle: Text(
                                localizations.commonInterests(commonInterests.join(', ')),
                                style: GoogleFonts.cairo(
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  fontSize: 14.sp,
                                ),
                              ),
                              trailing: user.isOnline
                                  ? Icon(Icons.circle, color: Colors.green, size: 12.sp)
                                  : Icon(Icons.circle, color: Colors.grey, size: 12.sp),
                              onTap: () {
                                safePush(context, '/profile/${user.uid}');
                              },
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFriendsList(BuildContext context, String currentUserId) {
    final localizations = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              color: isDarkMode ? Colors.grey[900] : Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Text(
                      localizations.friends,
                      style: GoogleFonts.cairo(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUserId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator(strokeWidth: 4.w));
                        }
                        final userData = snapshot.data!.data() as Map<String, dynamic>;
                        final friends = List<String>.from(userData['friends'] ?? []);

                        if (friends.isEmpty) {
                          return Center(
                            child: Text(
                              localizations.noFriendsYet,
                              style: GoogleFonts.cairo(fontSize: 16.sp),
                            ),
                          );
                        }

                        // Use a single stream to fetch all friends data at once
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where('uid', whereIn: friends)
                              .snapshots(),
                          builder: (context, friendsSnapshot) {
                            if (friendsSnapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator(strokeWidth: 4.w));
                            }
                            
                            if (!friendsSnapshot.hasData || friendsSnapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Text(
                                  localizations.noFriendsYet,
                                  style: GoogleFonts.cairo(fontSize: 16.sp),
                                ),
                              );
                            }
                            
                            final friendsList = friendsSnapshot.data!.docs
                                .map((doc) => UserModel.fromFirestore(doc))
                                .toList();
                                
                            return ListView.builder(
                              controller: scrollController,
                              itemCount: friendsList.length,
                              itemBuilder: (context, index) {
                                final friend = friendsList[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: friend.profileImage != null &&
                                        friend.profileImage!.isNotEmpty
                                        ? NetworkImage(friend.profileImage!)
                                        : null,
                                    child: friend.profileImage == null ||
                                        friend.profileImage!.isEmpty
                                        ? Text(
                                      friend.name[0].toUpperCase(),
                                      style: GoogleFonts.cairo(fontSize: 16.sp),
                                    )
                                        : null,
                                  ),
                                  title: Text(
                                    friend.name,
                                    style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.w600, fontSize: 16.sp),
                                  ),
                                  trailing: friend.isOnline
                                      ? Icon(Icons.circle, color: Colors.green, size: 12.sp)
                                      : Icon(Icons.circle, color: Colors.grey, size: 12.sp),
                                  onTap: () async {
                                    try {
                                      final friendId = friend.uid;
                                      final chatId = currentUserId.compareTo(friendId) < 0
                                          ? '$currentUserId$friendId'
                                          : '$friendId$currentUserId';
                                      final chatDoc = await FirebaseFirestore.instance
                                          .collection('conversations')
                                          .doc(chatId)
                                          .get();
                                      if (!chatDoc.exists) {
                                        // تهيئة حقول عداد الرسائل غير المقروءة لكل مستخدم
                                        final Map<String, dynamic> unreadCountFields = {
                                          'unreadCount': 0,  // للتوافق مع الإصدارات القديمة
                                          'unreadCount_$currentUserId': 0,  // عداد للمستخدم الحالي
                                          'unreadCount_$friendId': 0,  // عداد للمستخدم الآخر
                                          'lastOpenedBy_$currentUserId': FieldValue.serverTimestamp(),
                                          'lastOpenedBy_$friendId': null,
                                        };
                                        
                                        await FirebaseFirestore.instance
                                            .collection('conversations')
                                            .doc(chatId)
                                            .set({
                                          'participants': [currentUserId, friendId],
                                          'lastMessage': '',
                                          'lastMessageTime': FieldValue.serverTimestamp(),
                                          'isLastMessageSeen': false,
                                          'isLastMessageDelivered': false,
                                          'lastMessageSenderId': '',
                                          'otherUserName': friend.name,
                                          'otherUserImage': friend.profileImage,
                                          'isOnline': friend.isOnline,
                                          'otherUserId': friendId,
                                          ...unreadCountFields,
                                        });
                                      }
                                      Navigator.pop(context);
                                      safePush(context, '/chat/$chatId');
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            localizations.errorCreatingChat,
                                            style: GoogleFonts.cairo(fontSize: 14.sp),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}