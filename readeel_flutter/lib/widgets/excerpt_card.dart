import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

        // 3. Main Content
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Excerpt Content (Vertically Centered)
              Expanded(
                flex: 10,
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 16.0, bottom: 100),
                    child: SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            textAlign: TextAlign.left,
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: <TextSpan>[
                                TextSpan(
                                  text: '"',
                                  style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 48,
                                    fontFamily: GoogleFonts.mogra().fontFamily,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                TextSpan(
                                  text: excerpt.content,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                TextSpan(
                                  text: '"',
                                  style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 48,
                                    fontFamily: GoogleFonts.mogra(
                                      letterSpacing: 10,
                                    ).fontFamily,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            book.title,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            'by ${book.author}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
