import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/push_token_service.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  final PushTokenService _pushTokenService = PushTokenService();

  bool _pushNotificationsEnabled = true;
  bool _isPushSettingLoading = true;
  bool _isPushUpdating = false;
  bool _isAvatarUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadPushPreference();
  }

  Future<void> _loadPushPreference() async {
    try {
      final enabled = await _pushTokenService.getPushNotificationsEnabled();
      if (!mounted) return;
      setState(() {
        _pushNotificationsEnabled = enabled;
      });
    } catch (error) {
      debugPrint('[PROFILE] Failed to load push preference: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isPushSettingLoading = false;
        });
      }
    }
  }

  Future<void> _handlePushToggle(bool enabled) async {
    if (_isPushUpdating || _isPushSettingLoading) return;

    final previousValue = _pushNotificationsEnabled;
    setState(() {
      _pushNotificationsEnabled = enabled;
      _isPushUpdating = true;
    });

    try {
      if (enabled) {
        await _pushTokenService.enablePushNotifications();
      } else {
        await _pushTokenService.disablePushNotifications();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pushNotificationsEnabled = previousValue;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update notification setting: $error'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPushUpdating = false;
        });
      }
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "??";
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[parts.length - 1].substring(0, 1))
        .toUpperCase();
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_isAvatarUpdating) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) return;

      setState(() => _isAvatarUpdating = true);

      final filePath = result.files.single.path!;
      await _auth.updateAvatar(filePath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated successfully'),
          backgroundColor: Color(0xFF00CA50),
        ),
      );
    } catch (error) {
      debugPrint('[PROFILE] Avatar update failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile photo: $error'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAvatarUpdating = false);
      }
    }
  }

  String? _getAvatarUrl() {
    return _auth.getAvatarUrl(thumb: '100x100');
  }

  @override
  Widget build(BuildContext context) {
    final email = _auth.userEmail;
    final phone = _auth.userPhone;
    final name = _auth.userName.isNotEmpty ? _auth.userName : "Car Owner";

    // Colors
    const colorSlate50 = Color(0xFFF8FAFC);
    const colorSlate500 = Color(0xFF64748B);
    const colorSlate800 = Color(0xFF1E293B);
    const colorSlate900 = Color(0xFF0F172A);
    const colorNavy = Color(0xFF003366);

    return Scaffold(
      backgroundColor: colorSlate50,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(LucideIcons.chevronLeft, size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Profile",
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorSlate800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Header: Avatar & Name
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickAndUploadAvatar,
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blueGrey.shade200,
                                        Colors.blueGrey.shade400,
                                      ],
                                    ),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: _getAvatarUrl() != null
                                        ? Image.network(
                                            _getAvatarUrl()!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => Center(
                                                  child: Text(
                                                    _getInitials(name),
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 32,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: colorSlate800,
                                                    ),
                                                  ),
                                                ),
                                          )
                                        : Center(
                                            child: Text(
                                              _getInitials(name),
                                              style: GoogleFonts.outfit(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: colorSlate800,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                if (_isAvatarUpdating)
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.black38,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: colorNavy,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        LucideIcons.camera,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            name,
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colorSlate900,
                            ),
                          ),
                          Text(
                            email.isNotEmpty ? email : "mikel@example.com",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: colorSlate500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Profile Sections
                    _buildSection("Account Information", [
                      _buildListTile(
                        icon: LucideIcons.phone,
                        title: "Phone Number",
                        subtitle: phone.isNotEmpty ? phone : "Not set",
                        trailing: const Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                        ),
                      ),
                      _buildListTile(
                        icon: LucideIcons.mail,
                        title: "Email Address",
                        subtitle: email,
                      ),
                    ]),

                    const SizedBox(height: 24),

                    _buildSection("App Settings", [
                      _buildListTile(
                        icon: LucideIcons.bell,
                        title: "Push Notifications",
                        subtitle: _isPushSettingLoading
                            ? "Loading..."
                            : (_pushNotificationsEnabled
                                  ? "Enabled"
                                  : "Disabled"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isPushUpdating)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorNavy,
                                ),
                              ),
                            if (_isPushUpdating) const SizedBox(width: 8),
                            Switch(
                              value: _pushNotificationsEnabled,
                              onChanged:
                                  (_isPushSettingLoading || _isPushUpdating)
                                  ? null
                                  : _handlePushToggle,
                              activeThumbColor: colorNavy,
                            ),
                          ],
                        ),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    _buildSection("Legal & Privacy", [
                      _buildListTile(
                        icon: LucideIcons.shield,
                        title: "Privacy Policy",
                        trailing: const Icon(
                          LucideIcons.externalLink,
                          size: 16,
                        ),
                        onTap: () {
                          launchUrl(Uri.parse('https://carownershub.app/privacy'));
                        },
                      ),
                      _buildListTile(
                        icon: LucideIcons.fileText,
                        title: "Terms of Service",
                        trailing: const Icon(
                          LucideIcons.externalLink,
                          size: 16,
                        ),
                        onTap: () {
                          launchUrl(Uri.parse('https://carownershub.app/terms/'));
                        },
                      ),
                      _buildListTile(
                        icon: LucideIcons.trash2,
                        title: "Delete Account",
                        titleColor: Colors.red.shade600,
                        iconColor: Colors.red.shade600,
                        onTap: () {
                          // Placeholder for delete account logic
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Contact support to delete account")),
                          );
                        },
                      ),
                    ]),

                    const SizedBox(height: 40),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _auth.logout();
                          widget.onLogout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red.shade600,
                          elevation: 0,
                          side: BorderSide(color: Colors.red.shade100),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.logOut, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "Log Out",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade300,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? titleColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (iconColor ?? const Color(0xFF003366)).withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor ?? const Color(0xFF003366),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? const Color(0xFF1E293B),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.blueGrey.shade300,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
