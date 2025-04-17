import 'package:bloc/bloc.dart';
import 'package:convo_mate/logic/providers/locale_provider.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/presence_provider.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(SettingsInitial());
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> loadSettings(BuildContext context) async {
    emit(SettingsLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool('notificationsEnabled') ?? true;
      final language = prefs.getString('language') ?? 'en';
      emit(
        SettingsLoaded(
          notificationsEnabled: notificationsEnabled,
          language: language,
        ),
      );
    } catch (e) {
      emit(
        SettingsError('failedToLoadSettings', params: {'error': e.toString()}),
      );
    }
  }

  Future<void> updateNotifications(BuildContext context, bool value) async {
    final localizations = AppLocalizations.of(context)!;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notificationsEnabled', value);
      final state = this.state;
      if (state is SettingsLoaded) {
        emit(
          SettingsLoaded(notificationsEnabled: value, language: state.language),
        );
      }
    } catch (e) {
      emit(
        SettingsError(
          'failedToUpdateNotifications',
          params: {'error': e.toString()},
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      final state = this.state;
      if (state is SettingsLoaded) {
        emit(state);
      }
    }
  }

  Future<void> updateLanguage(BuildContext context, String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', languageCode);
      final state = this.state;
      if (state is SettingsLoaded) {
        emit(
          SettingsLoaded(
            notificationsEnabled: state.notificationsEnabled,
            language: languageCode,
          ),
        );
      }

      // تحديث اللغة باستخدام LocaleProvider
      final localeProvider = Provider.of<LocaleProvider>(
        context,
        listen: false,
      );
      localeProvider.setLocale(Locale(languageCode));
    } catch (e) {
      emit(
        SettingsError(
          'failedToUpdateLanguage',
          params: {'error': e.toString()},
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      final state = this.state;
      if (state is SettingsLoaded) {
        emit(state);
      }
    }
  }

  Future<void> reAuthAndChangePassword(
    BuildContext context,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      // Implement actual Firebase re-authentication and password change
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        // Create credential with current email and old password
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: oldPassword,
        );
        
        // Re-authenticate user
        await user.reauthenticateWithCredential(credential);
        
        // Change password
        await user.updatePassword(newPassword);
        
        final state = this.state;
        if (state is SettingsLoaded) {
          emit(
            SettingsLoaded(
              notificationsEnabled: state.notificationsEnabled,
              language: state.language,
            ),
          );
        }
      } else {
        throw Exception('User not logged in');
      }
    } on FirebaseAuthException catch (e) {
      String errorKey = 'failedToChangePassword';
      if (e.code == 'wrong-password') {
        errorKey = 'wrongPassword';
      }
      emit(SettingsError(errorKey, params: {'error': e.message ?? e.code}));
      await Future.delayed(const Duration(seconds: 1));
      final state = this.state;
      if (state is SettingsLoaded) {
        emit(state);
      }
    } catch (e) {
      emit(
        SettingsError(
          'failedToChangePassword',
          params: {'error': e.toString()},
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      final state = this.state;
      if (state is SettingsLoaded) {
        emit(state);
      }
    }
  }

  Future<void> signOut(BuildContext context) async {
    emit(SettingsLoading());
    try {
      // Set user offline first
      try {
        final presenceProvider = Provider.of<PresenceProvider>(context, listen: false);
        await presenceProvider.setOfflineOnLogout();
      } catch (e) {
        print('Error setting user offline: $e');
      }
      
      // Actual Firebase signout
      await _auth.signOut();
      emit(SettingsInitial());
      
      // Navigate to login screen
      context.go('/login');
    } catch (e) {
      emit(SettingsError('failedToSignOut', params: {'error': e.toString()}));
      await Future.delayed(const Duration(seconds: 1));
      final state = this.state;
      if (state is SettingsLoaded) {
        emit(state);
      }
    }
  }

  Future<void> deleteAccount(BuildContext context, String password) async {
    emit(SettingsLoading());
    try {
      // Implement actual Firebase account deletion
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        // Set user offline first
        try {
          final presenceProvider = Provider.of<PresenceProvider>(context, listen: false);
          await presenceProvider.setOfflineOnLogout();
        } catch (e) {
          print('Error setting user offline before deletion: $e');
        }
        
        // Create credential for re-authentication
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        
        // Re-authenticate user
        await user.reauthenticateWithCredential(credential);
        
        // Delete user account
        await user.delete();
        
        emit(SettingsInitial());
        
        // Navigate to login screen
        context.go('/login');
      } else {
        throw Exception('User not logged in');
      }
    } on FirebaseAuthException catch (e) {
      String errorKey = 'failedToDeleteAccount';
      if (e.code == 'wrong-password') {
        errorKey = 'wrongPassword';
      }
      emit(SettingsError(errorKey, params: {'error': e.message ?? e.code}));
      await Future.delayed(const Duration(seconds: 1));
      final state = this.state;
      if (state is SettingsLoaded) {
        emit(state);
      }
    } catch (e) {
      emit(
        SettingsError('failedToDeleteAccount', params: {'error': e.toString()}),
      );
      await Future.delayed(const Duration(seconds: 1));
      final state = this.state;
      if (state is SettingsLoaded) {
        emit(state);
      }
    }
  }
}
