import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = 'User';
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final username = await SessionService.getUsername();
    final userId = await SessionService.getUserId();
    if (mounted) {
      setState(() {
        _username = username ?? 'User';
        _userId = userId;
      });
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Log Out',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to log out of ShoppingHub?',
          style: TextStyle(color: AppColors.fundySlate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.fundySlate)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.wishlistRemove,
              minimumSize: const Size(90, 40),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    Provider.of<WishlistProvider>(context, listen: false).clear();

    await SessionService.clearSession();

    if (!mounted) return;


    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // User Avatar Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.antique, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.fundySlate.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.evergreen,
                    child: Text(
                      _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _username,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userId != null ? 'User ID #$_userId • Local SQLite Account' : 'ShoppingHub Member',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.fundySlate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // App Information Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.antique, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About ShoppingHub',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.storefront_outlined,
                    label: 'Application',
                    value: 'ShoppingHub Mobile',
                  ),
                  const Divider(color: AppColors.antique, height: 20),
                  _buildInfoRow(
                    icon: Icons.palette_outlined,
                    label: 'Design Theme',
                    value: 'Seasons of Sage',
                  ),
                  const Divider(color: AppColors.antique, height: 20),
                  _buildInfoRow(
                    icon: Icons.storage_outlined,
                    label: 'Local Database',
                    value: 'SQLite (Encrypted Passwords)',
                  ),
                  const Divider(color: AppColors.antique, height: 20),
                  _buildInfoRow(
                    icon: Icons.cloud_outlined,
                    label: 'Product Catalog',
                    value: 'DummyJSON REST API',
                  ),
                  const Divider(color: AppColors.antique, height: 20),
                  _buildInfoRow(
                    icon: Icons.verified_user_outlined,
                    label: 'Version',
                    value: '1.0.0 (Responsi PAM)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: AppColors.wishlistRemove),
              label: const Text(
                'Log Out',
                style: TextStyle(
                  color: AppColors.wishlistRemove,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.wishlistRemove, width: 1.5),
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.fundySlate),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.fundySlate,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
