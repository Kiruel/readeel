import 'package:flutter/material.dart';
import 'package:readeel_client/readeel_client.dart';
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final languageCode = View.of(context).platformDispatcher.locale.languageCode;
      final feed = await client.excerpt.getDiscoverFeed(
        languageCode: languageCode,
        limit: 20,
      );
      
      setState(() {
        _excerpts.addAll(feed);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load feed. Please check your connection.';
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
        scrollDirection: Axis.vertical,
        itemCount: _excerpts.length,
        itemBuilder: (context, index) {
          return ExcerptCard(excerptWithBook: _excerpts[index]);
        },
      ),
    );
  }
}
