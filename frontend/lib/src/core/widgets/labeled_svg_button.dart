import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Кнопка: фон из SVG + подпись по центру (как бывшие PNG-кнопки).
class LabeledSvgButton extends StatelessWidget {
  const LabeledSvgButton({
    super.key,
    required this.svgAssetPath,
    required this.label,
    required this.onTap,
    required this.textColor,
    this.height = 48,
    this.width,
    this.showMaterialSplash = true,
  });

  final String svgAssetPath;
  final String label;
  final VoidCallback? onTap;
  final Color textColor;
  final double height;
  final double? width;

  /// Если false - без всплеска InkWell (удобно при сразу следующем setState).
  final bool showMaterialSplash;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashFactory: showMaterialSplash ? null : NoSplash.splashFactory,
          splashColor: showMaterialSplash ? null : Colors.transparent,
          highlightColor: showMaterialSplash ? null : Colors.transparent,
          hoverColor: showMaterialSplash ? null : Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SvgPicture.asset(
                svgAssetPath,
                fit: BoxFit.fill,
              ),
              Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: height >= 48 ? 15 : 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
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
