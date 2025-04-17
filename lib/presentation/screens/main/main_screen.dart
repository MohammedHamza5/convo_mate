import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MainScreen extends StatefulWidget {
  final Widget child;

  const MainScreen({super.key, required this.child});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const _routes = [
    '/home',
    '/friend_requests',
    '/search',
    '/profile',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSelectedIndexBasedOnRoute();
    });
  }

  void _updateSelectedIndexBasedOnRoute() {
    final currentPath = GoRouter.of(context)
        .routerDelegate
        .currentConfiguration
        .uri
        .path;
    final index = _routes.indexOf(currentPath);
    if (index != -1 && index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    context.go(_routes[index]);
  }

  Stream<int> _getPendingRequestsCount() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0);
    }
    return FirebaseFirestore.instance
        .collection('friend_requests')
        .where('to', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: StreamBuilder<int>(
        stream: _getPendingRequestsCount(),
        builder: (context, snapshot) {
          final pendingRequestsCount = snapshot.data ?? 0;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                  blurRadius: 10.r,
                  offset: Offset(0, -2.h),
                ),
              ],
            ),
            child: BottomNavigationBar(
              items: [
                BottomNavigationBarItem(
                  icon: ZoomIn(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.identity()..scale(_selectedIndex == 0 ? 1.2 : 1.0),
                      child: Icon(
                        Icons.chat,
                        color: _selectedIndex == 0
                            ? (isDarkMode ? Colors.blueAccent : Colors.blue)
                            : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                        size: 24.sp,
                      ),
                    ),
                  ),
                  label: localizations.chats,
                ),
                BottomNavigationBarItem(
                  icon: ZoomIn(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.identity()..scale(_selectedIndex == 1 ? 1.2 : 1.0),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Icon(
                            Icons.person_add,
                            color: _selectedIndex == 1
                                ? (isDarkMode ? Colors.blueAccent : Colors.blue)
                                : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                            size: 24.sp,
                          ),
                          if (pendingRequestsCount > 0)
                            ElasticIn(
                              child: Container(
                                padding: EdgeInsets.all(5.w),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.red.shade400, Colors.red.shade600],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDarkMode ? Colors.grey[900]! : Colors.white,
                                    width: 1.5.w,
                                  ),
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 20.w,
                                  minHeight: 20.h,
                                ),
                                child: Text(
                                  '$pendingRequestsCount',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  label: localizations.requests,
                ),
                BottomNavigationBarItem(
                  icon: ZoomIn(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.identity()..scale(_selectedIndex == 2 ? 1.2 : 1.0),
                      child: Icon(
                        Icons.search,
                        color: _selectedIndex == 2
                            ? (isDarkMode ? Colors.blueAccent : Colors.blue)
                            : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                        size: 24.sp,
                      ),
                    ),
                  ),
                  label: localizations.search,
                ),
                BottomNavigationBarItem(
                  icon: ZoomIn(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.identity()..scale(_selectedIndex == 3 ? 1.2 : 1.0),
                      child: Icon(
                        Icons.person,
                        color: _selectedIndex == 3
                            ? (isDarkMode ? Colors.blueAccent : Colors.blue)
                            : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                        size: 24.sp,
                      ),
                    ),
                  ),
                  label: localizations.profile,
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: isDarkMode ? Colors.blueAccent : Colors.blue,
              unselectedItemColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: GoogleFonts.cairo(fontSize: 12.sp, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12.sp),
              elevation: 0,
              onTap: _onItemTapped,
            ),
          );
        },
      ),
    );
  }
}