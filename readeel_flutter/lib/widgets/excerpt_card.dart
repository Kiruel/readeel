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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (book.coverUrl != null) ...[
                                Image.network(
                                  book.coverUrl!,
                                  fit: BoxFit.cover,
                                  width: 60,
                                  height: 90,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return SizedBox(
                                          width: 60,
                                          height: 90,
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                ),
                                const SizedBox(width: 16),
                              ],
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      book.title,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                    Text(
                                      'by ${book.author}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontStyle: FontStyle.italic,
                                            fontSize: 12,
                                          ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
