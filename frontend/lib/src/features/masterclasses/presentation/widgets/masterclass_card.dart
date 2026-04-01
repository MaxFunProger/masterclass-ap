import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../domain/masterclass.dart';
import '../../../../core/api_client.dart';
import '../../../../core/analytics.dart';
import '../../../../core/strings.dart';

/// Иконка избранного в отдельном [IconButton] над [InkWell], иначе конфликт жестов с открытием деталей.
class MasterclassCard extends StatelessWidget {
  final Masterclass masterclass;
  final bool isFavorite;
  final Future<void> Function()? onFavoritePressed;

  const MasterclassCard({
    super.key,
    required this.masterclass,
    this.isFavorite = false,
    this.onFavoritePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                Analytics.cardView(masterclass.id);
                await context.push<bool>('/masterclass', extra: {
                  'masterclass': masterclass,
                });
              },
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: Colors.grey[300]!,
                      child: Image.network(
                        ApiClient.resolveImageUrl(masterclass.imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                    Positioned.fill(
                      child: SvgPicture.asset(
                        'assets/gradient_black.svg',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _Badge(
                        assetPath: 'assets/price_orange.svg',
                        child: Text(
                          "${masterclass.price.toInt()}₽",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: _Badge(
                        assetPath: 'assets/date.svg',
                        child: Text(
                          _formatShortDate(masterclass.eventDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            masterclass.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (masterclass.duration.isNotEmpty)
                            Text(
                              masterclass.duration,
                              style: const TextStyle(color: Colors.white70),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (masterclass.organizer.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              masterclass.organizer,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.transparent,
              type: MaterialType.transparency,
              child: IconButton(
                tooltip: isFavorite
                    ? AppStrings.removeFavoriteTooltip
                    : AppStrings.addFavoriteTooltip,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                onPressed: onFavoritePressed == null
                    ? null
                    : () {
                        onFavoritePressed!();
                      },
                icon: SizedBox(
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/like_background.svg',
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                      Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.white,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatShortDate(String isoDate) {
    if (isoDate.isEmpty) return AppStrings.soonLabelUpper;
    try {
      final parts = isoDate.split('-');
      if (parts.length != 3) return isoDate.toUpperCase();
      final day = int.parse(parts[2]);
      final month = int.parse(parts[1]);
      return "$day ${AppStrings.monthsShortUpper[month] ?? ''}".trim();
    } catch (e) {
      return isoDate.toUpperCase();
    }
  }
}

class _Badge extends StatelessWidget {
  final String assetPath;
  final Widget child;
  final double height;

  const _Badge({
    required this.assetPath,
    required this.child,
    this.height = 32,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            assetPath,
            height: height,
            fit: BoxFit.contain,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: child,
          ),
        ],
      ),
    );
  }
}
