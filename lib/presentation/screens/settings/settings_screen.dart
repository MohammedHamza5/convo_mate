import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../logic/cubits/settings_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _oldPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _deletePasswordController = TextEditingController();
  bool _isOldPasswordVisible = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isDeletePasswordVisible = false;
  bool _hasLoadedSettings = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryGradient = LinearGradient(
      colors: isDarkMode
          ? [Colors.blueGrey.shade700, Colors.blueGrey.shade500]
          : [Colors.blue.shade400, Colors.blue.shade200],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return BlocProvider(
      create: (context) => SettingsCubit(),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // AppBar عصري
            SliverAppBar(
              pinned: true,
              expandedHeight: 120.h,
              flexibleSpace: FlexibleSpaceBar(
                title: FadeInDown(
                  child: Text(
                    localizations.settings,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 22.sp,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: primaryGradient,
                  ),
                ),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, size: 24.sp),
                onPressed: () => context.go('/home'),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            // المحتوى
            SliverToBoxAdapter(
              child: BlocConsumer<SettingsCubit, SettingsState>(
                listener: (context, state) {
                  if (state is SettingsError) {
                    final errorMessage = _translateError(context, state);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          errorMessage,
                          style: GoogleFonts.cairo(fontSize: 14.sp),
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else if (state is SettingsInitial) {
                    context.go('/login');
                  } else if (state is SettingsLoaded) {
                    if (_passwordController.text.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            localizations.passwordChanged,
                            style: GoogleFonts.cairo(fontSize: 14.sp),
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      _oldPasswordController.clear();
                      _passwordController.clear();
                      _confirmPasswordController.clear();
                    }
                  }
                },
                builder: (context, state) {
                  // Call loadSettings only once when the state is not yet loaded
                  if (!_hasLoadedSettings && state is! SettingsLoaded && state is! SettingsLoading) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      context.read<SettingsCubit>().loadSettings(context);
                      setState(() {
                        _hasLoadedSettings = true;
                      });
                    });
                  }

                  if (state is SettingsLoading) {
                    return Center(
                      child: CircularProgressIndicator(strokeWidth: 4.w),
                    );
                  } else if (state is SettingsLoaded) {
                    return Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // الإشعارات
                          FadeInUp(
                            child: Card(
                              elevation: 4.r,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.r),
                              ),
                              color: isDarkMode ? Colors.grey[850] : Colors.white,
                              child: Padding(
                                padding: EdgeInsets.all(12.w),
                                child: SwitchListTile(
                                  title: Text(
                                    localizations.enableNotifications,
                                    style: GoogleFonts.cairo(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    localizations.notificationsSubtitle,
                                    style: GoogleFonts.cairo(
                                      fontSize: 14.sp,
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                  value: state.notificationsEnabled,
                                  onChanged: (value) {
                                    context.read<SettingsCubit>().updateNotifications(context, value);
                                  },
                                  activeColor: Colors.blue,
                                  secondary: Icon(
                                    Icons.notifications,
                                    color: isDarkMode ? Colors.white70 : Colors.black54,
                                    size: 24.sp,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // تغيير اللغة
                          FadeInUp(
                            delay: const Duration(milliseconds: 100),
                            child: Card(
                              elevation: 4.r,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.r),
                              ),
                              color: isDarkMode ? Colors.grey[850] : Colors.white,
                              child: Padding(
                                padding: EdgeInsets.all(12.w),
                                child: ListTile(
                                  title: Text(
                                    localizations.language,
                                    style: GoogleFonts.cairo(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    localizations.languageSubtitle,
                                    style: GoogleFonts.cairo(
                                      fontSize: 14.sp,
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                  leading: Icon(
                                    Icons.language,
                                    color: isDarkMode ? Colors.white70 : Colors.black54,
                                    size: 24.sp,
                                  ),
                                  trailing: DropdownButton<String>(
                                    value: state.language,
                                    items: [
                                      DropdownMenuItem(
                                        value: 'ar',
                                        child: Text(
                                          localizations.arabic,
                                          style: GoogleFonts.cairo(fontSize: 14.sp),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'en',
                                        child: Text(
                                          localizations.english,
                                          style: GoogleFonts.cairo(fontSize: 14.sp),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'de',
                                        child: Text(
                                          localizations.german,
                                          style: GoogleFonts.cairo(fontSize: 14.sp),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        context.read<SettingsCubit>().updateLanguage(context, value);
                                      }
                                    },
                                    style: GoogleFonts.cairo(
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                      fontSize: 14.sp,
                                    ),
                                    dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                                    underline: const SizedBox(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // تغيير كلمة المرور
                          FadeInUp(
                            delay: const Duration(milliseconds: 200),
                            child: Card(
                              elevation: 4.r,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.r),
                              ),
                              color: isDarkMode ? Colors.grey[850] : Colors.white,
                              child: Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      localizations.changePassword,
                                      style: GoogleFonts.cairo(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 12.h),
                                    TextField(
                                      controller: _oldPasswordController,
                                      obscureText: !_isOldPasswordVisible,
                                      decoration: InputDecoration(
                                        hintText: localizations.oldPassword,
                                        hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 14.sp),
                                        filled: true,
                                        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15.r),
                                          borderSide: BorderSide.none,
                                        ),
                                        prefixIcon: Icon(Icons.lock_outline, size: 20.sp),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isOldPasswordVisible
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            size: 20.sp,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isOldPasswordVisible = !_isOldPasswordVisible;
                                            });
                                          },
                                        ),
                                      ),
                                      style: GoogleFonts.cairo(fontSize: 14.sp),
                                      textDirection: TextDirection.ltr,
                                    ),
                                    SizedBox(height: 12.h),
                                    TextField(
                                      controller: _passwordController,
                                      obscureText: !_isPasswordVisible,
                                      decoration: InputDecoration(
                                        hintText: localizations.newPassword,
                                        hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 14.sp),
                                        filled: true,
                                        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15.r),
                                          borderSide: BorderSide.none,
                                        ),
                                        prefixIcon: Icon(Icons.lock, size: 20.sp),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isPasswordVisible
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            size: 20.sp,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isPasswordVisible = !_isPasswordVisible;
                                            });
                                          },
                                        ),
                                      ),
                                      style: GoogleFonts.cairo(fontSize: 14.sp),
                                      textDirection: TextDirection.ltr,
                                    ),
                                    SizedBox(height: 12.h),
                                    TextField(
                                      controller: _confirmPasswordController,
                                      obscureText: !_isConfirmPasswordVisible,
                                      decoration: InputDecoration(
                                        hintText: localizations.confirmPassword,
                                        hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 14.sp),
                                        filled: true,
                                        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15.r),
                                          borderSide: BorderSide.none,
                                        ),
                                        prefixIcon: Icon(Icons.lock, size: 20.sp),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isConfirmPasswordVisible
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            size: 20.sp,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                            });
                                          },
                                        ),
                                      ),
                                      style: GoogleFonts.cairo(fontSize: 14.sp),
                                      textDirection: TextDirection.ltr,
                                    ),
                                    SizedBox(height: 12.h),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          if (_oldPasswordController.text.isEmpty ||
                                              _passwordController.text.isEmpty ||
                                              _confirmPasswordController.text.isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  localizations.fillAllFields,
                                                  style: GoogleFonts.cairo(fontSize: 14.sp),
                                                ),
                                                backgroundColor: Colors.red,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          } else if (_passwordController.text !=
                                              _confirmPasswordController.text) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  localizations.passwordsDoNotMatch,
                                                  style: GoogleFonts.cairo(fontSize: 14.sp),
                                                ),
                                                backgroundColor: Colors.red,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          } else if (_passwordController.text.length < 6) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  localizations.passwordTooShort,
                                                  style: GoogleFonts.cairo(fontSize: 14.sp),
                                                ),
                                                backgroundColor: Colors.red,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          } else {
                                            context
                                                .read<SettingsCubit>()
                                                .reAuthAndChangePassword(
                                              context,
                                              _oldPasswordController.text,
                                              _passwordController.text,
                                            );
                                          }
                                        },
                                        icon: Icon(Icons.save, size: 18.sp),
                                        label: Text(
                                          localizations.save,
                                          style: GoogleFonts.cairo(fontSize: 14.sp),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12.r),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 12.h,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // تسجيل الخروج
                          FadeInUp(
                            delay: const Duration(milliseconds: 300),
                            child: Card(
                              elevation: 4.r,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.r),
                              ),
                              color: Colors.red.shade500,
                              child: ListTile(
                                title: Text(
                                  localizations.logout,
                                  style: GoogleFonts.cairo(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: Text(
                                  localizations.logoutSubtitle,
                                  style: GoogleFonts.cairo(
                                    fontSize: 14.sp,
                                    color: Colors.white70,
                                  ),
                                ),
                                leading: Icon(
                                  Icons.logout,
                                  color: Colors.white,
                                  size: 24.sp,
                                ),
                                onTap: () {
                                  final settingsCubit = context.read<SettingsCubit>();
                                  showDialog(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: Text(
                                        localizations.confirmLogout,
                                        style: GoogleFonts.cairo(fontSize: 16.sp),
                                      ),
                                      content: Text(
                                        localizations.confirmLogoutMessage,
                                        style: GoogleFonts.cairo(fontSize: 14.sp),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15.r),
                                      ),
                                      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dialogContext),
                                          child: Text(
                                            localizations.cancel,
                                            style: GoogleFonts.cairo(
                                              color: Colors.grey,
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            settingsCubit.signOut(context);
                                            Navigator.pop(dialogContext);
                                          },
                                          child: Text(
                                            localizations.logout,
                                            style: GoogleFonts.cairo(
                                              color: Colors.red,
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // حذف الحساب
                          FadeInUp(
                            delay: const Duration(milliseconds: 400),
                            child: Card(
                              elevation: 4.r,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.r),
                              ),
                              color: Colors.red.shade700,
                              child: ListTile(
                                title: Text(
                                  localizations.deleteAccount,
                                  style: GoogleFonts.cairo(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: Text(
                                  localizations.deleteAccountSubtitle,
                                  style: GoogleFonts.cairo(
                                    fontSize: 14.sp,
                                    color: Colors.white70,
                                  ),
                                ),
                                leading: Icon(
                                  Icons.delete_forever,
                                  color: Colors.white,
                                  size: 24.sp,
                                ),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: Text(
                                        localizations.confirmDeleteAccount,
                                        style: GoogleFonts.cairo(fontSize: 16.sp),
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            localizations.confirmDeleteAccountMessage,
                                            style: GoogleFonts.cairo(fontSize: 14.sp),
                                          ),
                                          SizedBox(height: 12.h),
                                          TextField(
                                            controller: _deletePasswordController,
                                            obscureText: !_isDeletePasswordVisible,
                                            decoration: InputDecoration(
                                              hintText: localizations.password,
                                              hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 14.sp),
                                              filled: true,
                                              fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(15.r),
                                                borderSide: BorderSide.none,
                                              ),
                                              prefixIcon: Icon(Icons.lock, size: 20.sp),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _isDeletePasswordVisible
                                                      ? Icons.visibility
                                                      : Icons.visibility_off,
                                                  size: 20.sp,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _isDeletePasswordVisible = !_isDeletePasswordVisible;
                                                  });
                                                },
                                              ),
                                            ),
                                            style: GoogleFonts.cairo(fontSize: 14.sp),
                                            textDirection: TextDirection.ltr,
                                          ),
                                        ],
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15.r),
                                      ),
                                      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            _deletePasswordController.clear();
                                            Navigator.pop(dialogContext);
                                          },
                                          child: Text(
                                            localizations.cancel,
                                            style: GoogleFonts.cairo(
                                              color: Colors.grey,
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            if (_deletePasswordController.text.isEmpty) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    localizations.pleaseEnterYourPassword,
                                                    style: GoogleFonts.cairo(fontSize: 14.sp),
                                                  ),
                                                  backgroundColor: Colors.red,
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            } else {
                                              context
                                                  .read<SettingsCubit>()
                                                  .deleteAccount(context, _deletePasswordController.text);
                                              _deletePasswordController.clear();
                                              Navigator.pop(dialogContext);
                                            }
                                          },
                                          child: Text(
                                            localizations.deleteAccount,
                                            style: GoogleFonts.cairo(
                                              color: Colors.red,
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Center(
                    child: Text(
                      localizations.errorTryAgain,
                      style: GoogleFonts.cairo(fontSize: 16.sp),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _translateError(BuildContext context, SettingsError state) {
    final localizations = AppLocalizations.of(context)!;
    switch (state.key) {
      case 'failedToLoadSettings':
        return localizations.failedToLoadSettings(state.params['error']!);
      case 'failedToUpdateNotifications':
        return localizations.failedToUpdateNotifications(state.params['error']!);
      case 'failedToChangePassword':
        return localizations.failedToChangePassword(state.params['error']!);
      case 'wrongPassword':
        return localizations.wrongPassword;
      case 'failedToDeleteAccount':
        return localizations.failedToDeleteAccount(state.params['error']!);
      case 'failedToSignOut':
        return localizations.failedToSignOut(state.params['error']!);
      case 'failedToUpdateLanguage':
        return localizations.failedToUpdateLanguage;
      default:
        return localizations.errorTryAgain;
    }
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _deletePasswordController.dispose();
    super.dispose();
  }
}