import 'package:flutter/material.dart';

import '../../../../core/strings.dart';
import '../../../../core/widgets/labeled_svg_button.dart';

enum FilterModalVariant { bottomSheet, postRegistration }

class FilterModal extends StatefulWidget {
  final void Function(Map<String, dynamic>) onApply;
  final Map<String, dynamic> currentFilters;
  final FilterModalVariant variant;

  /// Если false, вызывающий код закрывает маршрут (например `Dialog`) после [onApply].
  final bool popOnApply;

  const FilterModal({
    super.key,
    required this.onApply,
    required this.currentFilters,
    this.variant = FilterModalVariant.bottomSheet,
    this.popOnApply = true,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late String? _format;
  late String? _company;
  List<String> _categories = [];
  late int? _minAge;
  late double? _priceRangeMin;
  late double? _priceRangeMax;
  late double? _minRating;
  List<String> _audiences = [];
  late String? _tags;

  @override
  void initState() {
    super.initState();
    _format = widget.currentFilters['format'];
    _company = widget.currentFilters['company'];

    if (widget.currentFilters['categories'] != null) {
      _categories = List<String>.from(widget.currentFilters['categories']);
    }

    _minAge = widget.currentFilters['min_age'];
    _priceRangeMin = widget.currentFilters['min_price'];
    _priceRangeMax = widget.currentFilters['max_price'];
    _minRating = widget.currentFilters['min_rating'];

    if (widget.currentFilters['audience'] != null) {
      // Handle if it was stored as list
      if (widget.currentFilters['audience'] is List) {
        _audiences = List<String>.from(widget.currentFilters['audience']);
      }
    }
    _tags = widget.currentFilters['tags'];
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_categories.contains(category)) {
        _categories.remove(category);
      } else {
        _categories.add(category);
      }
    });
  }

  void _toggleAudience(String audience) {
    setState(() {
      if (_audiences.contains(audience)) {
        _audiences.remove(audience);
      } else {
        _audiences.add(audience);
      }
    });
  }

  Map<String, dynamic> _buildFiltersMap() {
    return {
      'format': _format,
      'company': _company,
      'categories': _categories,
      'min_age': _minAge,
      'min_price': _priceRangeMin,
      'max_price': _priceRangeMax,
      'min_rating': _minRating,
      'audience': _audiences,
      'tags': _tags,
    };
  }

  void _submitFilters() {
    widget.onApply(_buildFiltersMap());
    if (widget.popOnApply) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isPostReg = widget.variant == FilterModalVariant.postRegistration;
    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isPostReg
            ? BorderRadius.circular(24)
            : const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isPostReg)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                AppStrings.filterSetupTitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context)),
                Text(AppStrings.filtersTitle,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(AppStrings.categorySection),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(
                          AppStrings.categoryDesign,
                          _categories.contains("design"),
                          () => _toggleCategory("design")),
                      _buildChip(
                          AppStrings.categoryBeauty,
                          _categories.contains("beauty_fashion"),
                          () => _toggleCategory("beauty_fashion")),
                      _buildChip(
                          AppStrings.categoryCraft,
                          _categories.contains("craft_maker"),
                          () => _toggleCategory("craft_maker")),
                      _buildChip(
                          AppStrings.categoryCooking,
                          _categories.contains("cooking_baking"),
                          () => _toggleCategory("cooking_baking")),
                      _buildChip(
                          AppStrings.categoryArt,
                          _categories.contains("drawing_painting"),
                          () => _toggleCategory("drawing_painting")),
                      _buildChip(
                          AppStrings.categoryPhoto,
                          _categories.contains("photography"),
                          () => _toggleCategory("photography")),
                      _buildChip(
                          AppStrings.categoryTech,
                          _categories.contains("tech_coding"),
                          () => _toggleCategory("tech_coding")),
                      _buildChip(
                          AppStrings.categoryMusic,
                          _categories.contains("music"),
                          () => _toggleCategory("music")),
                      _buildChip(
                          AppStrings.categoryDance,
                          _categories.contains("dance_performance"),
                          () => _toggleCategory("dance_performance")),
                      _buildChip(
                          AppStrings.categoryPersonalDev,
                          _categories.contains("personal_dev"),
                          () => _toggleCategory("personal_dev")),
                      _buildChip(
                          AppStrings.categoryHomeGarden,
                          _categories.contains("home_garden"),
                          () => _toggleCategory("home_garden")),
                      _buildChip(
                          AppStrings.categoryWellness,
                          _categories.contains("wellness_sport"),
                          () => _toggleCategory("wellness_sport")),
                      _buildChip(
                          AppStrings.categoryTheater,
                          _categories.contains("theater_cinema"),
                          () => _toggleCategory("theater_cinema")),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(AppStrings.audienceSection),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(
                          AppStrings.audienceAdults,
                          _audiences.contains("adults"),
                          () => _toggleAudience("adults")),
                      _buildChip(
                          AppStrings.audienceKids,
                          _audiences.contains("kids"),
                          () => _toggleAudience("kids")),
                      _buildChip(
                          AppStrings.audienceFamilies,
                          _audiences.contains("families"),
                          () => _toggleAudience("families")),
                      _buildChip(
                          AppStrings.audienceTeens,
                          _audiences.contains("teens"),
                          () => _toggleAudience("teens")),
                      _buildChip(
                          AppStrings.audienceCouples,
                          _audiences.contains("date_couple"),
                          () => _toggleAudience("date_couple")),
                      _buildChip(
                          AppStrings.audienceCorporate,
                          _audiences.contains("corporate"),
                          () => _toggleAudience("corporate")),
                      _buildChip(
                          AppStrings.audienceHobbyists,
                          _audiences.contains("hobbyists"),
                          () => _toggleAudience("hobbyists")),
                      _buildChip(
                          AppStrings.audienceProfessionals,
                          _audiences.contains("professionals"),
                          () => _toggleAudience("professionals")),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(AppStrings.formatSection),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildChip(
                          AppStrings.formatOnline,
                          _format == "online",
                          () => setState(() =>
                              _format = _format == "online" ? null : "online")),
                      _buildChip(
                          AppStrings.formatOffline,
                          _format == "offline",
                          () => setState(() => _format =
                              _format == "offline" ? null : "offline")),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(AppStrings.priceSection),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildChip("< 2500p", _priceRangeMax == 2500, () {
                        setState(() {
                          if (_priceRangeMax == 2500) {
                            _priceRangeMax = null;
                            _priceRangeMin = null;
                          } else {
                            _priceRangeMax = 2500;
                            _priceRangeMin = null;
                          }
                        });
                      }),
                      _buildChip("2500-5000p",
                          _priceRangeMin == 2500 && _priceRangeMax == 5000, () {
                        setState(() {
                          if (_priceRangeMin == 2500) {
                            _priceRangeMax = null;
                            _priceRangeMin = null;
                          } else {
                            _priceRangeMin = 2500;
                            _priceRangeMax = 5000;
                          }
                        });
                      }),
                      _buildChip("> 5000p", _priceRangeMin == 5000, () {
                        setState(() {
                          if (_priceRangeMin == 5000) {
                            _priceRangeMax = null;
                            _priceRangeMin = null;
                          } else {
                            _priceRangeMin = 5000;
                            _priceRangeMax = null;
                          }
                        });
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (isPostReg)
            LabeledSvgButton(
              svgAssetPath: 'assets/button_big_orange.svg',
              label: AppStrings.apply,
              textColor: Colors.white,
              height: 52,
              onTap: _submitFilters,
            )
          else
            FilledButton(
              onPressed: _submitFilters,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFFE67E22),
              ),
              child: Text(AppStrings.apply),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFE67E22),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.grey),
      ),
    );
  }
}
