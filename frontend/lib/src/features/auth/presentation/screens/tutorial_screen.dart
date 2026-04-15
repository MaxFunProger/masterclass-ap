import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/session_storage.dart';
import '../../../../core/strings.dart';
import '../../../../core/widgets/labeled_svg_button.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      "title": AppStrings.tutorialTitle1,
      "description": AppStrings.tutorialDesc1,
      "icon": "search",
      "asset": "assets/guy_hello.svg",
    },
    {
      "title": AppStrings.tutorialTitle2,
      "description": AppStrings.tutorialDesc2,
      "icon": "chat",
      "asset": "assets/guy_sing.svg",
    },
    {
      "title": AppStrings.tutorialTitle3,
      "description": AppStrings.tutorialDesc3,
      "icon": "notifications",
      "asset": "assets/guy_look.svg",
    },
    {
      "title": AppStrings.tutorialTitle4,
      "description": AppStrings.tutorialDesc4,
      "icon": "person",
      "asset": "assets/guy_home.svg",
    },
    {
      "title": AppStrings.tutorialTitle5,
      "description": AppStrings.tutorialDesc5,
      "icon": "star",
      "asset": "assets/guy_sleep.svg",
    },
  ];

  Future<void> _goHomeAfterTutorial() async {
    await SessionStorage.markPostTutorialFeedFilterPromptReady();
    if (!mounted) return;
    context.go('/home');
  }

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _goHomeAfterTutorial();
    }
  }

  void _onSkip() {
    _goHomeAfterTutorial();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final guyHeight = constraints.maxHeight * 0.7;
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/background_orange.png',
                fit: BoxFit.cover,
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SvgPicture.asset(
                  _slides[_currentPage]['asset']!,
                  width: constraints.maxWidth,
                  height: guyHeight,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) =>
                              setState(() => _currentPage = index),
                          itemCount: _slides.length,
                          itemBuilder: (context, index) {
                            final slide = _slides[index];
                            return LayoutBuilder(
                              builder: (context, pageConstraints) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                      top: pageConstraints.maxHeight * 0.25),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        slide['title']!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        slide['description']!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _onSkip,
                      child: Text(AppStrings.tutorialSkip,
                          style: const TextStyle(color: Colors.white)),
                    ),
                    LabeledSvgButton(
                      svgAssetPath: 'assets/button_small_black.svg',
                      label: AppStrings.tutorialNext,
                      textColor: Colors.white,
                      height: 40,
                      width: 140,
                      onTap: _onNext,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
