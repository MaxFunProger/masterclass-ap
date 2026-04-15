import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/api_client.dart';
import '../../../../core/strings.dart';
import '../../../../core/session_storage.dart';
import '../../../../core/providers/favorites_provider.dart';
import '../../../chat/chat_state.dart';
import '../../data/profile_service.dart';
import '../../domain/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService(ApiClient());
  UserProfile? _profile;
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      String? id = widget.userId;
      if (id == null || id.isEmpty) {
        id = await SessionStorage.getUserId();
      }
      _currentUserId = id;

      if (id == null || id.isEmpty) {
        if (mounted) context.go('/login');
        return;
      }

      final profile = await _profileService.getProfile(id);

      if (mounted) {
        setState(() {
          _profile = profile;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_profile == null)
      return Scaffold(body: Center(child: Text(AppStrings.profileLoadFailed)));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 380,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 168,
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/background_orange.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 92,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 152,
                          height: 152,
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: SvgPicture.asset(
                              'assets/avatar_dummy.svg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _profile!.fullName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              context.push(
                                '/profile/data?phone=${Uri.encodeComponent(_profile!.phone)}',
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 24,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppStrings.showData,
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.orange,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildMenuItem(Icons.favorite_border, AppStrings.favorites,
                onTap: () {
              if (_currentUserId != null) {
                context.read<FavoritesProvider>().bumpWishlistReloadNonce();
                context.go('/wishlist?user_id=$_currentUserId');
              }
            }),
            _buildMenuItem(
              Icons.settings_outlined,
              AppStrings.settings,
              onTap: () => context.push('/settings'),
            ),
            _buildMenuItem(
              Icons.info_outline,
              AppStrings.aboutApp,
              onTap: () => context.push('/about'),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _ImageButton(
                assetPath: 'assets/button_big_white.svg',
                label: AppStrings.logout,
                textColor: Colors.black,
                iconAssetPath: 'assets/icon_exit.svg',
                onTap: () async {
                  await SessionStorage.clear();
                  await context.read<ChatState>().clearAllOnLogout();

                  if (context.mounted) {
                    context.read<FavoritesProvider>().clear();
                    context.go('/login');
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _ImageButton(
                assetPath: 'assets/button_big_orange_gradient.svg',
                label: AppStrings.goToChat,
                textColor: Colors.white,
                onTap: () => context.go('/chat'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.orange),
      onTap: onTap,
    );
  }
}

class _ImageButton extends StatelessWidget {
  final String assetPath;
  final String label;
  final VoidCallback onTap;
  final Color textColor;
  final String? iconAssetPath;

  const _ImageButton({
    required this.assetPath,
    required this.label,
    required this.onTap,
    required this.textColor,
    this.iconAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    final isSvg = assetPath.toLowerCase().endsWith('.svg');
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isSvg)
                SvgPicture.asset(
                  assetPath,
                  fit: BoxFit.fill,
                )
              else
                Image.asset(
                  assetPath,
                  fit: BoxFit.fill,
                ),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (iconAssetPath != null) ...[
                      SvgPicture.asset(
                        iconAssetPath!,
                        height: 18,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
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
