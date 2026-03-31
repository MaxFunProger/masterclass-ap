import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/session_storage.dart';
import '../../../../core/providers/favorites_provider.dart';
import '../../domain/masterclass.dart';
import '../../../../core/api_client.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/strings.dart';

class MasterclassDetailsScreen extends StatefulWidget {
  final Masterclass masterclass;

  const MasterclassDetailsScreen({super.key, required this.masterclass});

  @override
  State<MasterclassDetailsScreen> createState() =>
      _MasterclassDetailsScreenState();
}

class _MasterclassDetailsScreenState extends State<MasterclassDetailsScreen> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _syncFavoritesFromServer());
  }

  Future<void> _syncFavoritesFromServer() async {
    final userId = await SessionStorage.getUserId();
    if (userId != null && mounted) {
      await context.read<FavoritesProvider>().loadFavorites(userId);
    }
  }

  Future<void> _launchUrl(String urlString) async {
    if (urlString.isEmpty) return;
    var normalized = urlString.trim();
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }
    final Uri url = Uri.parse(normalized);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {}
  }

  Future<void> _handleToggleFavorite() async {
    setState(() => _isProcessing = true);
    try {
      final userId = await SessionStorage.getUserId();
      if (userId == null) return;

      await context
          .read<FavoritesProvider>()
          .toggleFavorite(userId, widget.masterclass.id);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite =
        context.watch<FavoritesProvider>().isFavorite(widget.masterclass.id);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final fav =
            context.read<FavoritesProvider>().isFavorite(widget.masterclass.id);
        context.pop(fav);
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Image.network(
                  ApiClient.resolveImageUrl(widget.masterclass.imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 50)),
                ),
              ),
              leading: IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.arrow_back, color: Colors.black),
                ),
                onPressed: () => context.pop(
                  context
                      .read<FavoritesProvider>()
                      .isFavorite(widget.masterclass.id),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            widget.masterclass.title,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.star, color: Colors.orange, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          widget.masterclass.rating.toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${widget.masterclass.price.toInt()} ₽",
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE67E22)),
                    ),
                    const SizedBox(height: 24),
                    _buildInfoRow(Icons.calendar_today,
                        DateFormatter.format(widget.masterclass.eventDate)),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                        Icons.access_time, widget.masterclass.duration),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                        Icons.location_on, widget.masterclass.location),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.person, widget.masterclass.organizer),

                    const SizedBox(height: 24),
                    Text(
                      AppStrings.aboutMasterclass,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.masterclass.description,
                      style: const TextStyle(
                          fontSize: 16, height: 1.5, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.paymentDisclaimer,
                      style: TextStyle(
                          fontSize: 13, height: 1.4, color: Colors.black54),
                    ),
                    const SizedBox(height: 100), // Space for bottom button area
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomSheet: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _isProcessing ? null : _handleToggleFavorite,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          isFavorite ? Colors.white : const Color(0xFFE67E22),
                      foregroundColor:
                          isFavorite ? const Color(0xFFE67E22) : Colors.white,
                      side: isFavorite
                          ? const BorderSide(color: Color(0xFFE67E22), width: 2)
                          : BorderSide.none,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isProcessing
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isFavorite
                                    ? const Color(0xFFE67E22)
                                    : Colors.white))
                        : Text(
                            isFavorite
                                ? AppStrings.willNotAttend
                                : AppStrings.willAttend,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (widget.masterclass.contactTg != null &&
                  widget.masterclass.contactTg!.isNotEmpty)
                _buildSocialButton('assets/tg.png',
                    widget.masterclass.contactTg!, Icons.telegram),
              if (widget.masterclass.website.isNotEmpty) ...[
                const SizedBox(width: 8),
                _buildSocialButton('assets/web.png', widget.masterclass.website,
                    Icons.language),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
      ],
    );
  }

  Widget _buildSocialButton(
      String assetPath, String url, IconData fallbackIcon) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE67E22), width: 2),
        ),
        child: Icon(fallbackIcon, color: const Color(0xFFE67E22)),
      ),
    );
  }
}
