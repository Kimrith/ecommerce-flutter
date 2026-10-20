import 'package:flutter/material.dart';
import 'package:midterm/routes/app_routes.dart';
import 'package:midterm/services/app_theme_service.dart';
import 'package:midterm/services/auth_service.dart';
import 'package:midterm/config/app_colors.dart';
import 'package:midterm/widgets/app_toast.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserPayload? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final loggedIn = await AuthService.isLoggedIn();
    final user = await AuthService.getCurrentUser();

    if (!mounted) return;
    setState(() {
      _isLoggedIn = loggedIn && user != null;
      _currentUser = user;
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await AuthService.logout();
      if (!mounted) return;
      AppToast.showSuccess(context, 'Logged out successfully');

      setState(() {
        _isLoggedIn = false;
        _currentUser = null;
      });

      // Navigate to Login screen and clear backstack
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  void _navigateToLogin() {
    Navigator.pushNamed(context, AppRoutes.login).then((_) {
      _loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayName = _isLoggedIn && (_currentUser?.name.trim().isNotEmpty ?? false)
        ? _currentUser!.name.trim()
        : (_isLoggedIn ? 'User' : 'Guest User');

    final displayEmail = _isLoggedIn && (_currentUser?.email.trim().isNotEmpty ?? false)
        ? _currentUser!.email.trim()
        : 'Sign in to access your profile & orders';

    final initialLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'G';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Profile Avatar
              GestureDetector(
                onTap: _isLoggedIn ? null : _navigateToLogin,
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: _isLoggedIn
                      ? AppColors.primary
                      : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade300),
                  child: _isLoggedIn
                      ? Text(
                          initialLetter,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.person_outline,
                          size: 48,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // User Name
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),

              // User Email / Sign in prompt
              GestureDetector(
                onTap: _isLoggedIn ? null : _navigateToLogin,
                child: Text(
                  displayEmail,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: _isLoggedIn
                        ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600)
                        : AppColors.primary,
                    fontWeight: _isLoggedIn ? FontWeight.normal : FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Profile Options List
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text('Settings'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: const Text('Shipping Address'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.payment_outlined),
                      title: const Text('Payment Methods'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
                    ),

                    // Dark Mode Switch Integration
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: AppThemeService.themeModeNotifier,
                      builder: (context, currentMode, child) {
                        final isDarkTheme = currentMode == ThemeMode.dark;
                        return SwitchListTile(
                          activeThumbColor: AppColors.switchActiveThumb,
                          activeTrackColor: AppColors.switchActiveTrack,
                          inactiveThumbColor: AppColors.switchInactiveThumb,
                          inactiveTrackColor: AppColors.switchInactiveTrack,
                          trackOutlineColor: WidgetStateProperty.all(AppColors.switchTrackOutline),
                          secondary: Icon(
                            isDarkTheme ? Icons.dark_mode : Icons.light_mode,
                            color: isDarkTheme ? AppColors.switchDarkIcon : AppColors.switchLightIcon,
                          ),
                          title: const Text('Dark Mode'),
                          subtitle: Text(
                            isDarkTheme ? 'Dark theme enabled' : 'Light theme enabled',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkTheme ? AppColors.switchDarkSubtitle : AppColors.switchLightSubtitle,
                            ),
                          ),
                          value: isDarkTheme,
                          onChanged: (bool value) {
                            AppThemeService.toggleTheme(value);
                          },
                        );
                      },
                    ),

                    // Log in / Log out Button Tile
                    if (_isLoggedIn)
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text(
                          'Log out',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: _handleLogout,
                      )
                    else
                      ListTile(
                        leading: const Icon(Icons.login, color: AppColors.primary),
                        title: const Text(
                          'Log in',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: _navigateToLogin,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}