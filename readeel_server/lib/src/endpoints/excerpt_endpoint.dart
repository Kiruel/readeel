import 'dart:math';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class ExcerptEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  Future<List<ExcerptWithBook>> getDiscoverFeed(Session session, {String? languageCode, int limit = 10, int offset = 0}) async {
    // We prioritize excerpts where the book language matches the phone setup.
    List<Excerpt> excerpts = [];
    final random = Random();
    
    if (languageCode != null) {
      final count = await Excerpt.db.count(
        session,
        where: (t) => t.book.language.equals(languageCode),
      );
      
      if (count > 0) {
        final futures = List.generate(limit, (_) async {
          int rOffset = random.nextInt(count);
          final res = await Excerpt.db.find(
            session,
            where: (t) => t.book.language.equals(languageCode),
            limit: 1,
            offset: rOffset,
            include: Excerpt.include(
              book: Book.include(),
            ),
          );
          return res.isNotEmpty ? res.first : null;
        });
        
        final results = await Future.wait(futures);
        for (var e in results) {
          if (e != null) excerpts.add(e);
        }
      }
    }

    if (excerpts.length < limit) {
      final remainingCount = limit - excerpts.length;
      final fallbackCount = await Excerpt.db.count(
        session,
        where: languageCode != null 
          ? (t) => t.book.language.notEquals(languageCode) 
          : null,
      );
      
      if (fallbackCount > 0) {
        final futures = List.generate(remainingCount, (_) async {
          int rOffset = random.nextInt(fallbackCount);
          final res = await Excerpt.db.find(
            session,
            where: languageCode != null 
              ? (t) => t.book.language.notEquals(languageCode) 
              : null,
            limit: 1,
            offset: rOffset,
            include: Excerpt.include(
              book: Book.include(),
            ),
          );
          return res.isNotEmpty ? res.first : null;
        });
        
        final results = await Future.wait(futures);
        for (var e in results) {
          if (e != null) excerpts.add(e);
        }
      }
    }

    // Deduplicate in case random offsets picked the same row
    final uniqueExcerpts = <int, Excerpt>{};
    for (var e in excerpts) {
      if (e.id != null) uniqueExcerpts[e.id!] = e;
    }

    return uniqueExcerpts.values.map((e) => ExcerptWithBook(
      excerpt: e,
      book: e.book!,
    )).toList();
  }
}
