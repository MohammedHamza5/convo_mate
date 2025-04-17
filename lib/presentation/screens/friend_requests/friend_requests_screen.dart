import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../data/models/friend_request_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../logic/cubits/friendship_cubit.dart';
import '../../../../logic/cubits/friendship_state.dart';

class FriendRequestsScreen extends StatelessWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => FriendshipCubit(),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(isDarkMode, localizations),
            SliverToBoxAdapter(
              child: BlocConsumer<FriendshipCubit, FriendshipState>(
                listener: (context, state) {
                  if (state is FriendshipRequestAccepted) {
                    _showSnackBar(context, localizations.friendRequestAccepted, Colors.green);
                  } else if (state is FriendshipRequestDeclined) {
                    _showSnackBar(context, localizations.friendRequestDeclined, Colors.red);
                  } else if (state is FriendshipError) {
                    _showSnackBar(context, localizations.errorMessage(state.error), Colors.red);
                  }
                },
                builder: (context, state) => _buildRequestList(context, currentUserId, isDarkMode, state, localizations),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(bool isDarkMode, AppLocalizations localizations) {
    return SliverAppBar(
      expandedHeight: 180.h,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: FadeInDown(
          child: Text(
            localizations.friendRequests,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 24.sp,
              color: Colors.white,
            ),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [Colors.blueGrey.shade900, Colors.blueGrey.shade700]
                  : [Colors.blue.shade600, Colors.blue.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.2,
                  child: Image.asset(
                    'assets/images/pattern.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(),
                  ),
                ),
              ),
              Center(
                child: FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.group_add_rounded,
                    size: 60.sp,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: isDarkMode ? Colors.blueGrey.shade900 : Colors.blue.shade600,
      elevation: 0,
    );
  }

  Widget _buildRequestList(BuildContext context, String currentUserId, bool isDarkMode,
      FriendshipState state, AppLocalizations localizations) {
    return StreamBuilder<List<FriendRequest>>(
      stream: context.read<FriendshipCubit>().getFriendRequests(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading(isDarkMode);
        }
        if (snapshot.hasError) {
          return _buildErrorWidget(localizations.errorFetchingRequests(snapshot.error.toString()), isDarkMode);
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyWidget(isDarkMode, localizations);
        }

        final requests = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return FadeInUp(
              delay: Duration(milliseconds: 100 * index),
              child: _buildRequestCard(context, requests[index], currentUserId, isDarkMode, state, localizations),
            );
          },
        );
      },
    );
  }

  Widget _buildShimmerLoading(bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: List.generate(
          3,
              (index) => Shimmer.fromColors(
            baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
            child: Card(
              margin: EdgeInsets.symmetric(vertical: 8.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              child: ListTile(
                leading: CircleAvatar(radius: 30.r, backgroundColor: Colors.grey[300]),
                title: Container(
                  height: 16.h,
                  width: 100.w,
                  color: Colors.grey[300],
                ),
                subtitle: Container(
                  height: 12.h,
                  width: 150.w,
                  color: Colors.grey[300],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(bool isDarkMode, AppLocalizations localizations) {
    return SizedBox(
      height: 400.h,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElasticIn(
              child: Icon(
                Icons.group_off_rounded,
                size: 80.sp,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              localizations.noFriendRequests,
              style: GoogleFonts.cairo(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message, bool isDarkMode) {
    return SizedBox(
      height: 400.h,
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.cairo(
            fontSize: 16.sp,
            color: isDarkMode ? Colors.red[300] : Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, FriendRequest request, String currentUserId,
      bool isDarkMode, FriendshipState state, AppLocalizations localizations) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(request.from).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return _buildShimmerCard(isDarkMode);
        }
        if (userSnapshot.hasError) {
          return _buildErrorCard(isDarkMode, localizations);
        }

        final sender = UserModel.fromFirestore(userSnapshot.data!);
        return GestureDetector(
          onTap: () => safePush(context, '/profile/${request.from}'),
          child: Card(
            elevation: 8,
            shadowColor: isDarkMode ? Colors.blueGrey.withOpacity(0.3) : Colors.blue.withOpacity(0.2),
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
              side: BorderSide(
                color: isDarkMode ? Colors.blueGrey.shade700 : Colors.blue.shade100,
                width: 1.w,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  ZoomIn(
                    child: CircleAvatar(
                      radius: 30.r,
                      backgroundImage: sender.profileImage != null && sender.profileImage!.isNotEmpty
                          ? NetworkImage(sender.profileImage!)
                          : null,
                      child: sender.profileImage == null || sender.profileImage!.isEmpty
                          ? Text(
                        sender.name[0].toUpperCase(),
                        style: GoogleFonts.cairo(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.blue,
                        ),
                      )
                          : null,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sender.name,
                          style: GoogleFonts.cairo(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          localizations.incomingFriendRequest,
                          style: GoogleFonts.cairo(
                            fontSize: 14.sp,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          localizations.requestSent(_formatRelativeDate(request.createdAt, localizations)),
                          style: GoogleFonts.cairo(
                            fontSize: 12.sp,
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildActionButtons(context, request, currentUserId, state, isDarkMode),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerCard(bool isDarkMode) {
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              CircleAvatar(radius: 30.r, backgroundColor: Colors.grey[300]),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 16.h, width: 100.w, color: Colors.grey[300]),
                    SizedBox(height: 4.h),
                    Container(height: 12.h, width: 150.w, color: Colors.grey[300]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(bool isDarkMode, AppLocalizations localizations) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Text(
          localizations.errorFetchingUser,
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            color: isDarkMode ? Colors.red[300] : Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, FriendRequest request, String currentUserId,
      FriendshipState state, bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeInRight(
          child: GestureDetector(
            onTap: state is FriendshipLoading
                ? null
                : () {
              context.read<FriendshipCubit>().acceptFriendRequest(request.from, currentUserId);
            },
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: state is FriendshipLoading
                  ? SizedBox(
                width: 24.w,
                height: 24.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2.w,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : Icon(Icons.check, color: Colors.white, size: 24.sp),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        FadeInRight(
          delay: const Duration(milliseconds: 100),
          child: GestureDetector(
            onTap: state is FriendshipLoading
                ? null
                : () {
              context.read<FriendshipCubit>().declineFriendRequest(request.from, currentUserId);
            },
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.red.shade600],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: state is FriendshipLoading
                  ? SizedBox(
                width: 24.w,
                height: 24.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2.w,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : Icon(Icons.close, color: Colors.white, size: 24.sp),
            ),
          ),
        ),
      ],
    );
  }

  String _formatRelativeDate(DateTime? date, AppLocalizations localizations) {
    if (date == null) return localizations.unknownTime;
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) {
      return localizations.sinceDays(diff.inDays);
    }
    if (diff.inHours > 0) {
      return localizations.sinceHours(diff.inHours);
    }
    return localizations.sinceMinutes(diff.inMinutes);
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 14.sp),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  void safePush(BuildContext context, String path) {
    final currentPath = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    if (currentPath != path) {
      context.push(path);
    }
  }
}