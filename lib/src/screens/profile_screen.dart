import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../widgets/glow_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    required this.authService,
    required this.onProfileUpdated,
  });

  final AppUser user;
  final AuthService authService;
  final ValueChanged<AppUser> onProfileUpdated;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _updatingProfile = false;
  bool _changingPassword = false;

  String? _profileError;
  String? _profileSuccess;
  String? _passwordError;
  String? _passwordSuccess;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name;
    _phoneController.text = widget.user.phone ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() {
      _updatingProfile = true;
      _profileError = null;
      _profileSuccess = null;
    });

    try {
      final updatedUser = await widget.authService.updateProfile(
        name: _nameController.text,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      );
      widget.onProfileUpdated(updatedUser);
      setState(() {
        _profileSuccess = 'Profile updated successfully!';
      });
    } on AuthException catch (e) {
      setState(() {
        _profileError = e.message;
      });
    } finally {
      setState(() {
        _updatingProfile = false;
      });
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() {
      _changingPassword = true;
      _passwordError = null;
      _passwordSuccess = null;
    });

    try {
      await widget.authService.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      _oldPasswordController.clear();
      _newPasswordController.clear();
      setState(() {
        _passwordSuccess = 'Password changed successfully!';
      });
    } on AuthException catch (e) {
      setState(() {
        _passwordError = e.message;
      });
    } finally {
      setState(() {
        _changingPassword = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MY PROFILE',
          style: GoogleFonts.bebasNeue(letterSpacing: 1.0),
        ),
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Meta
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: const Icon(Icons.person, color: AppTheme.primaryColor, size: 36),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.user.name.toUpperCase(),
                    style: GoogleFonts.bebasNeue(fontSize: 24, letterSpacing: 1.0),
                  ),
                  Text(
                    widget.user.email,
                    style: TextStyle(color: AppTheme.mutedForegroundColor, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.user.role.toUpperCase(),
                      style: GoogleFonts.bebasNeue(
                        fontSize: 10,
                        color: AppTheme.primaryColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Profile Edit Form
            Form(
              key: _profileFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'UPDATE DETAILS',
                    style: GoogleFonts.bebasNeue(fontSize: 16, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_profileError != null) ...[
                    Text(_profileError!, style: const TextStyle(color: AppTheme.destructiveColor)),
                    const SizedBox(height: 8),
                  ],
                  if (_profileSuccess != null) ...[
                    Text(_profileSuccess!, style: const TextStyle(color: Colors.green)),
                    const SizedBox(height: 8),
                  ],
                  GlowButton(
                    onPressed: _updatingProfile ? null : _updateProfile,
                    isLoading: _updatingProfile,
                    child: const Text('SAVE DETAILS'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Password Change Form
            Form(
              key: _passwordFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'CHANGE PASSWORD',
                    style: GoogleFonts.bebasNeue(fontSize: 16, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _oldPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter current password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter new password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  if (_passwordError != null) ...[
                    Text(_passwordError!, style: const TextStyle(color: AppTheme.destructiveColor)),
                    const SizedBox(height: 8),
                  ],
                  if (_passwordSuccess != null) ...[
                    Text(_passwordSuccess!, style: const TextStyle(color: Colors.green)),
                    const SizedBox(height: 8),
                  ],
                  GlowButton(
                    onPressed: _changingPassword ? null : _changePassword,
                    isLoading: _changingPassword,
                    child: const Text('CHANGE PASSWORD'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
