import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../data/models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  String? _maritalStatus;
  final List<String> _selectedInterests = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      final user = UserModel.fromFirestore(doc);
      _nameController.text = user.name;
      _bioController.text = user.bio ?? '';
      _cityController.text = user.city ?? '';
      setState(() {
        _maritalStatus = user.maritalStatus;
        _selectedInterests.addAll(user.interests);
      });
    }
  }

  Future<void> _saveProfile() async {
    final localizations = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate() || _isLoading) return;
    if (_selectedInterests.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.selectAtLeastThreeInterests,
            style: GoogleFonts.cairo(fontSize: 14.sp),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      print('Starting profile update for user: $userId');
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        'maritalStatus': _maritalStatus,
        'interests': _selectedInterests,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Profile updated successfully');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.profileUpdated,
            style: GoogleFonts.cairo(fontSize: 14.sp),
          ),
          backgroundColor: Colors.green,
        ),
      );

      print('Scheduling navigation to /profile');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          print('Navigating to /profile');
          context.go('/profile');
        } else {
          print('Widget not mounted, skipping navigation');
        }
      });
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.errorUpdatingProfile(e.toString()),
            style: GoogleFonts.cairo(fontSize: 14.sp),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    print('Disposing EditProfileScreen');
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final Map<String, String> availableInterests = {
      'sport': localizations.interestSport,
      'tech': localizations.interestTech,
      'movies': localizations.interestMovies,
      'books': localizations.interestBooks,
      'music': localizations.interestMusic,
      'travel': localizations.interestTravel,
      'games': localizations.interestGames,
      'food': localizations.interestFood,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.editProfile,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20.sp),
        ),
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 24.sp),
          onPressed: () {
            print('Back button pressed, navigating to /profile');
            context.go('/profile');
          },
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(strokeWidth: 4.w))
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: localizations.name,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  labelStyle: GoogleFonts.cairo(),
                ),
                validator: (value) =>
                value!.isEmpty ? localizations.pleaseEnterYourName : null,
                style: GoogleFonts.cairo(fontSize: 16.sp),
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: localizations.bio,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  labelStyle: GoogleFonts.cairo(),
                ),
                maxLines: 3,
                style: GoogleFonts.cairo(fontSize: 16.sp),
              ),
              SizedBox(height: 16.h),
              DropdownButtonFormField<String>(
                value: _maritalStatus,
                decoration: InputDecoration(
                  labelText: localizations.maritalStatus,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  labelStyle: GoogleFonts.cairo(),
                ),
                items: [
                  DropdownMenuItem(
                      value: 'single', child: Text(localizations.single)),
                  DropdownMenuItem(
                      value: 'married', child: Text(localizations.married)),
                  DropdownMenuItem(
                      value: 'engaged', child: Text(localizations.engaged)),
                ],
                onChanged: (value) {
                  setState(() {
                    _maritalStatus = value;
                  });
                },
                style: GoogleFonts.cairo(fontSize: 16.sp),
                dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: localizations.city,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  labelStyle: GoogleFonts.cairo(),
                ),
                style: GoogleFonts.cairo(fontSize: 16.sp),
              ),
              SizedBox(height: 16.h),
              Text(
                localizations.selectInterestsWithCount(_selectedInterests.length),
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
                children: availableInterests.keys.map((interestKey) {
                  final isSelected = _selectedInterests.contains(interestKey);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedInterests.remove(interestKey);
                        } else if (_selectedInterests.length < 5) {
                          _selectedInterests.add(interestKey);
                        }
                      });
                    },
                    child: Chip(
                      label: Text(
                        availableInterests[interestKey]!,
                        style: GoogleFonts.cairo(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 14.sp,
                        ),
                      ),
                      backgroundColor: isSelected
                          ? (isDarkMode ? Colors.blueGrey : Colors.blue)
                          : (isDarkMode ? Colors.grey[700] : Colors.grey[200]),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      elevation: isSelected ? 2 : 0,
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 24.h),
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  transform: Matrix4.identity()..scale(_isLoading ? 0.95 : 1.0),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.blueGrey : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 4.w,
                    )
                        : Text(
                      localizations.saveChanges,
                      style: GoogleFonts.cairo(fontSize: 16.sp),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}