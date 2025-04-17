import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../data/models/user_model.dart';
import '../../../../logic/cubits/friendship_cubit.dart';
import '../../../../logic/cubits/friendship_state.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<DocumentSnapshot>? _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
  }

  void _refreshUserData() {
    setState(() {
      _userFuture = FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => FriendshipCubit(),
      child: Scaffold(
        body: BlocConsumer<FriendshipCubit, FriendshipState>(
          listener: (context, state) {
            if (state is FriendshipRequestSent) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    localizations.friendRequestSent,
                    style: GoogleFonts.cairo(fontSize: 14.sp),
                  ),
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
              );
            } else if (state is FriendshipRequestAccepted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    localizations.friendRequestAccepted,
                    style: GoogleFonts.cairo(fontSize: 14.sp),
                  ),
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
              );
              _refreshUserData();
            } else if (state is FriendshipRequestDeclined) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    localizations.friendRequestDeclined,
                    style: GoogleFonts.cairo(fontSize: 14.sp),
                  ),
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
              );
              _refreshUserData();
            } else if (state is FriendshipRemoved) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    localizations.friendshipRemoved,
                    style: GoogleFonts.cairo(fontSize: 14.sp),
                  ),
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
              );
              _refreshUserData();
            } else if (state is FriendshipError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.error,
                    style: GoogleFonts.cairo(fontSize: 14.sp),
                  ),
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
              );
            }
          },
          builder: (context, state) {
            return FutureBuilder<DocumentSnapshot>(
              future: _userFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(strokeWidth: 4.w));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(
                    child: Text(
                      localizations.userNotFound,
                      style: GoogleFonts.cairo(fontSize: 18.sp, color: Colors.grey),
                    ),
                  );
                }

                final user = UserModel.fromFirestore(snapshot.data!);
                final isFriend = user.friends.contains(currentUserId);
                final isCurrentUser = widget.userId == currentUserId;

                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 280.h,
                      floating: false,
                      pinned: true,
                      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.blue,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: isDarkMode
                                      ? [Colors.grey[900]!, Colors.blueGrey]
                                      : [Colors.blue.shade700, Colors.blue.shade300],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 20.h,
                              left: 0,
                              right: 0,
                              child: Column(
                                children: [
                                  Hero(
                                    tag: 'profile_${user.uid}',
                                    child: CircleAvatar(
                                      radius: 70.r,
                                      backgroundColor: Colors.white,
                                      child: CircleAvatar(
                                        radius: 66.r,
                                        backgroundImage: user.profileImage != null &&
                                            user.profileImage!.isNotEmpty
                                            ? CachedNetworkImageProvider(user.profileImage!)
                                            : null,
                                        child: user.profileImage == null ||
                                            user.profileImage!.isEmpty
                                            ? Text(
                                          user.name[0].toUpperCase(),
                                          style: GoogleFonts.cairo(
                                            fontSize: 40.sp,
                                            color: isDarkMode ? Colors.white : Colors.black87,
                                          ),
                                        )
                                            : null,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  Text(
                                    user.name,
                                    style: GoogleFonts.cairo(
                                      fontSize: 26.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    user.email,
                                    style: GoogleFonts.cairo(
                                      fontSize: 16.sp,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (user.bio != null && user.bio!.isNotEmpty) ...[
                              Text(
                                localizations.bio,
                                style: GoogleFonts.cairo(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Center(
                                child: Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Text(
                                    user.bio!,
                                    style: GoogleFonts.cairo(
                                      fontSize: 16.sp,
                                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16.h),
                            ],
                            if (user.maritalStatus != null) ...[
                              Text(
                                localizations.maritalStatus,
                                style: GoogleFonts.cairo(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Center(
                                child: Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Text(
                                    user.maritalStatus == 'single'
                                        ? localizations.single
                                        : user.maritalStatus == 'married'
                                        ? localizations.married
                                        : localizations.engaged,
                                    style: GoogleFonts.cairo(
                                      fontSize: 16.sp,
                                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16.h),
                            ],
                            if (user.city != null && user.city!.isNotEmpty) ...[
                              Text(
                                localizations.city,
                                style: GoogleFonts.cairo(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Center(
                                child: Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Text(
                                    user.city!,
                                    style: GoogleFonts.cairo(
                                      fontSize: 16.sp,
                                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16.h),
                            ],
                            Text(
                              localizations.interests,
                              style: GoogleFonts.cairo(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              children: user.interests.isEmpty
                                  ? [
                                Text(
                                  localizations.noInterests,
                                  style: GoogleFonts.cairo(
                                    fontSize: 16.sp,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey,
                                  ),
                                )
                              ]
                                  : user.interests.map((interest) {
                                return Chip(
                                  label: Text(
                                    interest,
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  backgroundColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                  elevation: 2,
                                );
                              }).toList(),
                            ),
                            SizedBox(height: 24.h),
                            Center(
                              child: isCurrentUser
                                  ? _buildActionButton(
                                context: context,
                                label: localizations.editProfile,
                                icon: Icons.edit,
                                color: isDarkMode ? Colors.blueGrey : Colors.blue,
                                onPressed: () => context.go('/edit_profile'),
                                isLoading: false,
                              )
                                  : StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('friend_requests')
                                    .doc('${widget.userId}-$currentUserId')
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData || snapshot.hasError) {
                                    return _buildDefaultFriendshipButton(
                                      context,
                                      state,
                                      isFriend,
                                      currentUserId,
                                      widget.userId,
                                      isDarkMode,
                                    );
                                  }
                                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                                  if (data != null && data['status'] == 'pending') {
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildActionButton(
                                          context: context,
                                          label: localizations.accept,
                                          icon: Icons.check,
                                          color: Colors.green,
                                          onPressed: () {
                                            if (state is! FriendshipLoading) {
                                              context
                                                  .read<FriendshipCubit>()
                                                  .acceptFriendRequest(widget.userId, currentUserId);
                                            }
                                          },
                                          isLoading: state is FriendshipLoading,
                                        ),
                                        SizedBox(width: 8.w),
                                        _buildActionButton(
                                          context: context,
                                          label: localizations.decline,
                                          icon: Icons.close,
                                          color: Colors.red,
                                          onPressed: () {
                                            if (state is! FriendshipLoading) {
                                              context
                                                  .read<FriendshipCubit>()
                                                  .declineFriendRequest(widget.userId, currentUserId);
                                            }
                                          },
                                          isLoading: state is FriendshipLoading,
                                        ),
                                      ],
                                    );
                                  }
                                  return _buildDefaultFriendshipButton(
                                    context,
                                    state,
                                    isFriend,
                                    currentUserId,
                                    widget.userId,
                                    isDarkMode,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDefaultFriendshipButton(
      BuildContext context,
      FriendshipState state,
      bool isFriend,
      String currentUserId,
      String userId,
      bool isDarkMode,
      ) {
    final localizations = AppLocalizations.of(context)!;
    if (isFriend) {
      return _buildActionButton(
        context: context,
        label: localizations.removeFriend,
        icon: Icons.person_remove,
        color: Colors.red,
        onPressed: () {
          if (state is! FriendshipLoading) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(localizations.removeFriend, style: GoogleFonts.cairo(fontSize: 18.sp)),
                content: Text(localizations.confirmRemoveFriend, style: GoogleFonts.cairo(fontSize: 16.sp)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(localizations.cancel, style: GoogleFonts.cairo(fontSize: 14.sp)),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<FriendshipCubit>().removeFriend(currentUserId, userId);
                      Navigator.pop(context);
                    },
                    child: Text(localizations.confirm, style: GoogleFonts.cairo(fontSize: 14.sp)),
                  ),
                ],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
              ),
            );
          }
        },
        isLoading: state is FriendshipLoading,
      );
    }
    return _buildActionButton(
      context: context,
      label: localizations.sendFriendRequest,
      icon: Icons.person_add,
      color: Colors.green,
      onPressed: () {
        if (state is! FriendshipLoading) {
          context.read<FriendshipCubit>().sendFriendRequest(currentUserId, userId);
        }
      },
      isLoading: state is FriendshipLoading,
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
          width: 24.w,
          height: 24.h,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.w,
          ),
        )
            : Icon(icon, size: 20.sp),
        label: Text(
          label,
          style: GoogleFonts.cairo(fontSize: 16.sp),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: Size(150.w, 50.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.r),
          ),
          elevation: 5,
          shadowColor: Colors.black26,
        ),
      ),
    );
  }
}