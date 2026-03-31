import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/session_storage.dart';
import '../../../../core/strings.dart';
import '../../../../core/providers/favorites_provider.dart';
import '../../data/masterclass_service.dart';
import '../../domain/masterclass.dart';
import '../../../../core/api_client.dart';
import '../widgets/masterclass_card.dart';
import '../widgets/filter_modal.dart';
import '../widgets/week_date_strip.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _masterclassService = MasterclassService(ApiClient());
  final ScrollController _scrollController = ScrollController();
  List<Masterclass> _masterclasses = [];
  final Set<int> _loadedIds = {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  Map<String, dynamic> _filters = {};
  DateTime? _selectedDate;
  late DateTime _visibleWeekMonday;
  static const int _pageSize = 20;

  String _isoDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  void initState() {
    super.initState();
    final today = dateOnly(DateTime.now());
    _selectedDate = null;
    _visibleWeekMonday = mondayOfWeekContaining(today);
    _scrollController.addListener(_onScroll);
    _loadMasterclasses(reset: true);
    _initFavorites();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _maybeShowPostRegistrationFilters());
  }

  Future<void> _maybeShowPostRegistrationFilters() async {
    final needs = await SessionStorage.needsPostRegistrationFeedFilters();
    if (!mounted || !needs) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: FilterModal(
          variant: FilterModalVariant.postRegistration,
          popOnApply: false,
          currentFilters: Map<String, dynamic>.from(_filters),
          onApply: (filters) async {
            await SessionStorage.setNeedsPostRegistrationFeedFilters(false);
            if (!mounted) return;
            setState(() => _filters = filters);
            Navigator.of(dialogContext).pop();
            await _loadMasterclasses(reset: true);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initFavorites() async {
    final userId = await SessionStorage.getUserId();
    if (userId != null && mounted) {
      context.read<FavoritesProvider>().loadFavorites(userId);
    }
  }

  Future<void> _loadMasterclasses({required bool reset}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _hasMore = true;
        _loadedIds.clear();
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    }
    try {
      final list = await _masterclassService.getMasterclasses(
        format: _filters['format'],
        company: _filters['company'],
        categories: _filters['categories'] != null
            ? List<String>.from(_filters['categories'])
            : null,
        minAge: _filters['min_age'],
        minPrice: _filters['min_price'],
        maxPrice: _filters['max_price'],
        minRating: _filters['min_rating'],
        audience: _filters['audience'] != null
            ? List<String>.from(_filters['audience'])
            : null,
        eventDateFrom: _selectedDate != null ? _isoDate(_selectedDate!) : null,
        eventDateTo: _selectedDate != null ? _isoDate(_selectedDate!) : null,
        sortOrder: _selectedDate == null ? 'date_asc' : null,
        offset: 0,
        limit: _pageSize,
        excludeIds: reset ? null : _loadedIds.toList(),
      );

      final newItems = list.where((mc) => !_loadedIds.contains(mc.id)).toList();

      setState(() {
        if (reset) {
          _masterclasses = newItems;
        } else {
          _masterclasses.addAll(newItems);
        }
        for (final mc in newItems) {
          _loadedIds.add(mc.id);
        }
        if (newItems.length < _pageSize) {
          _hasMore = false;
        }
      });
    } catch (_) {
    } finally {
      if (reset) {
        setState(() => _isLoading = false);
      } else {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMasterclasses(reset: false);
    }
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterModal(
        currentFilters: _filters,
        onApply: (filters) {
          setState(() => _filters = filters);
          _loadMasterclasses(reset: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          AppStrings.feedTitle,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _openFilters,
                  tooltip: AppStrings.filtersTooltip,
                ),
              ],
            ),
          ),
          WeekDateStrip(
            visibleWeekMonday: _visibleWeekMonday,
            selectedDate: _selectedDate,
            onSelectDay: (day) {
              final d = dateOnly(day);
              setState(() {
                if (_selectedDate != null && _selectedDate == d) {
                  _selectedDate = null;
                } else {
                  _selectedDate = d;
                }
              });
              _loadMasterclasses(reset: true);
            },
            onPrevWeek: () {
              setState(() {
                _visibleWeekMonday =
                    _visibleWeekMonday.subtract(const Duration(days: 7));
              });
            },
            onNextWeek: () {
              setState(() {
                _visibleWeekMonday =
                    _visibleWeekMonday.add(const Duration(days: 7));
              });
            },
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _masterclasses.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _masterclasses.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final masterclass = _masterclasses[index];
                      return Consumer<FavoritesProvider>(
                        builder: (context, favorites, child) {
                          return MasterclassCard(
                            key: ValueKey<int>(masterclass.id),
                            masterclass: masterclass,
                            isFavorite: favorites.isFavorite(masterclass.id),
                            onFavoritePressed: () async {
                              final userId = await SessionStorage.getUserId();
                              if (userId != null && context.mounted) {
                                await context
                                    .read<FavoritesProvider>()
                                    .toggleFavorite(userId, masterclass.id);
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
