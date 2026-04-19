import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class ExcerptEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  Future<List<ExcerptWithBook>> getDiscoverFeed(Session session, {String? languageCode, int limit = 10}) async {
    // We prioritize excerpts where the book language matches the phone setup.
    List<Excerpt> excerpts = [];
    
    if (languageCode != null) {
      excerpts = await Excerpt.db.find(
        session,
        where: (t) => t.book.language.equals(languageCode),
        limit: limit,
        include: Excerpt.include(
          book: Book.include(),
        ),
      );
    }

    if (excerpts.length < limit) {
      final additionalExcerpts = await Excerpt.db.find(
        session,
        where: languageCode != null 
          ? (t) => t.book.language.notEquals(languageCode) 
          : null,
        limit: limit - excerpts.length,
        include: Excerpt.include(
          book: Book.include(),
        ),
      );
      excerpts.addAll(additionalExcerpts);
    }

    return excerpts.map((e) => ExcerptWithBook(
      excerpt: e,
      book: e.book!,
    )).toList();
  }
}
