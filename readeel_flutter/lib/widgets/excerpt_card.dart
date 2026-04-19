import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:readeel_client/readeel_client.dart';

class ExcerptCard extends StatelessWidget {
  final ExcerptWithBook excerptWithBook;

  const ExcerptCard({
    super.key,
    required this.excerptWithBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final excerpt = excerptWithBook.excerpt;
    final book = excerptWithBook.book;

    return Stack(
      children: [
        // 1. Blurred Background Image (Placeholder for now)
        if (book.coverUrl != null)
          Positioned.fill(
            child: Image.network(
              book.coverUrl!,
              fit: BoxFit.cover,
            ),
          ),
        
        // 2. Backdrop Filter for Blur Effect
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50.0, sigmaY: 50.0),
            child: Container(
              color: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
            ),
          ),
        ),

        // 3. Main Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                // Book Title & Author
                Text(
                  book.title,
                  style: theme.textTheme.displayLarge?.copyWith(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'by ${book.author}',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                
                const Spacer(),
                
                // Excerpt Content (Vertically Centered)
                Expanded(
                  flex: 10,
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        excerpt.content,
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                
                const Spacer(),

                // Actions Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to Library')),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // In a real app, launch URL
                      },
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Buy on Amazon'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
