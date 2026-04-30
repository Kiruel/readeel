import 'package:flutter/material.dart';
import 'package:readeel_client/readeel_client.dart';
import 'package:readeel_flutter/widgets/loading_logo.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../widgets/excerpt_card.dart';
import '../widgets/onboarding_overlay.dart';
import 'settings_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final List<ExcerptWithBook> _excerpts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentOffset = 0;

  // Use ValueNotifier to avoid rebuilding the entire screen on every swipe
  final ValueNotifier<int> _currentIndexNotifier = ValueNotifier<int>(0);
  String? _lastLanguageCode;

  @override
  void initState() {
    super.initState();
    _lastLanguageCode = settingsController.languageCode;
    settingsController.addListener(_onSettingsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeed();
    });
  }

  @override
  void dispose() {
    settingsController.removeListener(_onSettingsChanged);
    _currentIndexNotifier.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (_lastLanguageCode != settingsController.languageCode) {
      _lastLanguageCode = settingsController.languageCode;
      _loadFeed();
    }
  }

  Future<void> _loadFeed({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentOffset = 0;
        _currentIndexNotifier.value = 0;
        _excerpts.clear();
      });
    }

    try {
      final languageCode =
          settingsController.languageCode ??
          View.of(
            context,
          ).platformDispatcher.locale.languageCode;

      final feed = await client.excerpt.getDiscoverFeed(
        languageCode: languageCode,
        limit: 20,
        offset: _currentOffset,
      );

      if (!mounted) return;

      // Optimization: Yield to the event loop before calling setState.
      // This allows any ongoing swipe animations to finish cleanly
      // rather than being interrupted by a heavy widget rebuild.
      await Future.delayed(const Duration(milliseconds: 50));

      if (!mounted) return;

      // Ensure feed is fully evaluated before updating the UI state
      final evaluatedFeed = feed.toList();

      setState(() {
        _excerpts.addAll(evaluatedFeed);
        _currentOffset += evaluatedFeed.length;
        if (loadMore) {
          _isLoadingMore = false;
        } else {
          _isLoading = false;
        }
      });

      // Background optimization: precache the new images to prevent stutter when scrolling to them
      for (final item in evaluatedFeed) {
        if (item.book.coverUrl != null && mounted) {
          precacheImage(NetworkImage(item.book.coverUrl!), context);
        }
      }
    } catch (e) {
      debugPrint('Error loading feed: $e');
      if (!mounted) return;
      setState(() {
        if (loadMore) {
          _isLoadingMore = false;
        } else {
          _isLoading = false;
          _error = 'Failed to load feed. Please check your connection.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _excerpts.isEmpty) {
      return const Scaffold(
        body: Center(
          child: LoadingLogo(),
        ),
      );
    }

    if (_error != null && _excerpts.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadFeed,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _excerpts.length,
            onPageChanged: (index) {
              // Update notifier instead of calling setState to prevent PageView stutter
              _currentIndexNotifier.value = index;

              // Trigger load more when we only have 5 items left in the list
              if (index >= _excerpts.length - 5) {
                _loadFeed(loadMore: true);
              }
            },
            itemBuilder: (context, index) {
              return ExcerptCard(
                key: ValueKey(_excerpts[index].excerpt.id),
                excerptWithBook: _excerpts[index],
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top,
            right: 16,
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.7),
              ),
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ),
          if (!settingsController.hasSeenOnboarding && _excerpts.isNotEmpty)
            OnboardingOverlay(
              onDismiss: () {
                setState(() {});
              },
            ),
        ],
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
      floatingActionButton: _excerpts.isNotEmpty
          ? ValueListenableBuilder<int>(
              valueListenable: _currentIndexNotifier,
              builder: (context, currentIndex, child) {
                // Safeguard against index out of bounds during loading
                if (currentIndex >= _excerpts.length) {
                  return const SizedBox.shrink();
                }

                return FloatingActionButton.extended(
                  heroTag: "amazon-buy-fab-$currentIndex",
                  onPressed: () async {
                    final book = _excerpts[currentIndex].book;
                    final String tag = 'readeel-21';
                    final String query = Uri.encodeComponent(
                      '${book.title} ${book.author}',
                    );
                    final Uri url = Uri.parse(
                      'https://www.amazon.fr/s?k=$query&tag=$tag',
                    );

                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not open Amazon.'),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.book),
                  label: Text(AppLocalizations.of(context)!.continueReading),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                );
              },
            )
          : null,
    );
  }
}
