import 'package:flutter/material.dart';
import 'package:readeel_client/readeel_client.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../widgets/excerpt_card.dart';

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
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeed();
    });
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
        _currentIndex = 0;
        _excerpts.clear();
      });
    }

    try {
      final languageCode = View.of(
        context,
      ).platformDispatcher.locale.languageCode;
      final feed = await client.excerpt.getDiscoverFeed(
        languageCode: languageCode,
        limit: 20,
        offset: _currentOffset,
      );

      setState(() {
        _excerpts.addAll(feed);
        _currentOffset += feed.length;
        if (loadMore) {
          _isLoadingMore = false;
        } else {
          _isLoading = false;
        }
      });
    } catch (e) {
      debugPrint('Error loading feed: $e');
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
          child: CircularProgressIndicator(),
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
      body: PageView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _excerpts.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Trigger load more when we only have 5 items left in the list
          if (index >= _excerpts.length - 5) {
            _loadFeed(loadMore: true);
          }
        },
        itemBuilder: (context, index) {
          return ExcerptCard(excerptWithBook: _excerpts[index]);
        },
      ),
      floatingActionButton: _excerpts.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                final book = _excerpts[_currentIndex].book;
                final String tag = 'readeel-21';
                final String query = Uri.encodeComponent(
                  '${book.title} ${book.author}',
                );
                debugPrint('Book: ${book.title} ${book.author}');
                debugPrint('Query: $query');
                final Uri url = Uri.parse(
                  'https://www.amazon.fr/s?k=$query&tag=$tag',
                );
                debugPrint('Launching URL: $url');

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
              label: const Text('Continue reading'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}
