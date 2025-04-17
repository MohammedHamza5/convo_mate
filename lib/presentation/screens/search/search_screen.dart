import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../data/models/user_model.dart';
import '../../../logic/cubits/search_cubit.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (currentUserId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 4.w)));
    }

    return BlocProvider(
      create: (context) => SearchCubit(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            localizations.searchFriends,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20.sp),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          foregroundColor: isDarkMode ? Colors.white : Colors.black87,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, size: 24.sp),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: Builder(
          builder: (blocContext) {
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: localizations.searchPlaceholder,
                      hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 16.sp),
                      prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20.sp),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 0.h),
                    ),
                    style: GoogleFonts.cairo(fontSize: 16.sp),
                    onChanged: (value) {
                      blocContext.read<SearchCubit>().searchUsers(value.trim(), currentUserId);
                    },
                  ),
                ),
                Expanded(
                  child: BlocBuilder<SearchCubit, SearchState>(
                    builder: (context, state) {
                      if (state is SearchLoading) {
                        return Center(child: CircularProgressIndicator(strokeWidth: 4.w));
                      } else if (state is SearchSuccess) {
                        if (state.users.isEmpty) {
                          return Center(
                            child: Text(
                              localizations.noResults,
                              style: GoogleFonts.cairo(fontSize: 18.sp, color: Colors.grey),
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: EdgeInsets.all(16.w),
                          itemCount: state.users.length,
                          itemBuilder: (context, index) {
                            final user = state.users[index];
                            return _buildUserTile(context, user, isDarkMode, currentUserId);
                          },
                        );
                      } else if (state is SearchFailure) {
                        return Center(
                          child: Text(
                            state.errorMessage,
                            style: GoogleFonts.cairo(fontSize: 16.sp, color: Colors.red),
                          ),
                        );
                      }
                      return Center(
                        child: Text(
                          localizations.enterSearchTerm,
                          style: GoogleFonts.cairo(fontSize: 18.sp, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserTile(
      BuildContext context, UserModel user, bool isDarkMode, String currentUserId) {
    final localizations = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: InkWell(
        onTap: () {
          context.push('/profile/${user.uid}');
        },
        borderRadius: BorderRadius.circular(15.r),
        child: Hero(
          tag: 'profile_${user.uid}',
          child: Material(
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(15.r),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                radius: 25.r,
                backgroundImage: user.profileImage != null && user.profileImage!.isNotEmpty
                    ? CachedNetworkImageProvider(user.profileImage!)
                    : null,
                child: user.profileImage == null || user.profileImage!.isEmpty
                    ? Text(
                  user.name[0].toUpperCase(),
                  style: GoogleFonts.cairo(fontSize: 18.sp),
                )
                    : null,
              ),
              title: Text(
                user.name,
                style: GoogleFonts.cairo(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: user.interests.isEmpty
                    ? [
                  Text(
                    localizations.noInterests,
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ]
                    : user.interests.map((interest) {
                  return Chip(
                    label: Text(
                      interest,
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  );
                }).toList(),
              ),
              trailing: CircleAvatar(
                radius: 8.r,
                backgroundColor: user.isOnline ? Colors.green : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}