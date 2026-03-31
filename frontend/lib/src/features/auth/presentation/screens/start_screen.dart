import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/app_assets.dart';
import '../../../../core/strings.dart';
import '../../../../core/widgets/labeled_svg_button.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/background_orange.png',
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Stack(
                children: [
                  Center(
                    child: SvgPicture.asset(
                      AppAssets.welcomeLogo,
                      width: MediaQuery.sizeOf(context).width * 0.72,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LabeledSvgButton(
                          svgAssetPath: 'assets/button_big_black.svg',
                          label: AppStrings.login,
                          textColor: Colors.white,
                          onTap: () => context.go('/login'),
                        ),
                        const SizedBox(height: 12),
                        LabeledSvgButton(
                          svgAssetPath: 'assets/button_big_orange.svg',
                          label: AppStrings.register,
                          textColor: Colors.white,
                          onTap: () => context.go('/register'),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
