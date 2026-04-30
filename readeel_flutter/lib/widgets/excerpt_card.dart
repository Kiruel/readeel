import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:readeel_client/readeel_client.dart';
import 'package:readeel_flutter/widgets/loading_logo.dart';

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
            horizontal: 16.0,
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
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                top: -20,
                                left: -8,
                                child: Text(
                                  '"',
                                  style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 100,
                                    fontFamily: GoogleFonts.mogra().fontFamily,
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    height: 1.0,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 20.0,
                                  top: 16.0,
                                  bottom: 8.0,
                                  right: 8.0,
                                ),
                                child: Text(
                                  excerpt.content,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 16.0,
                              bottom: 32.0,
                              left: 20.0,
                              right: 20.0,
                            ),
                            child: Row(
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
                                          if (loadingProgress != null) {
                                            return SizedBox(
                                              width: 60,
                                              height: 90,
                                              child: const Center(
                                                child: LoadingLogo(
                                                  size: 24,
                                                ),
                                              ),
                                            );
                                          }
                                          return child.animate().fade();
                                        },
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
