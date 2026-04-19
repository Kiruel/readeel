/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'book.dart' as _i2;
import 'package:readeel_client/src/protocol/protocol.dart' as _i3;

abstract class Excerpt implements _i1.SerializableModel {
  Excerpt._({
    this.id,
    required this.bookId,
    this.book,
    required this.content,
    required this.position,
    this.chapterTitle,
  });

  factory Excerpt({
    int? id,
    required int bookId,
    _i2.Book? book,
    required String content,
    required int position,
    String? chapterTitle,
  }) = _ExcerptImpl;

  factory Excerpt.fromJson(Map<String, dynamic> jsonSerialization) {
    return Excerpt(
      id: jsonSerialization['id'] as int?,
      bookId: jsonSerialization['bookId'] as int,
      book: jsonSerialization['book'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.Book>(jsonSerialization['book']),
      content: jsonSerialization['content'] as String,
      position: jsonSerialization['position'] as int,
      chapterTitle: jsonSerialization['chapterTitle'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int bookId;

  _i2.Book? book;

  String content;

  int position;

  String? chapterTitle;

  /// Returns a shallow copy of this [Excerpt]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Excerpt copyWith({
    int? id,
    int? bookId,
    _i2.Book? book,
    String? content,
    int? position,
    String? chapterTitle,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Excerpt',
      if (id != null) 'id': id,
      'bookId': bookId,
      if (book != null) 'book': book?.toJson(),
      'content': content,
      'position': position,
      if (chapterTitle != null) 'chapterTitle': chapterTitle,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ExcerptImpl extends Excerpt {
  _ExcerptImpl({
    int? id,
    required int bookId,
    _i2.Book? book,
    required String content,
    required int position,
    String? chapterTitle,
  }) : super._(
         id: id,
         bookId: bookId,
         book: book,
         content: content,
         position: position,
         chapterTitle: chapterTitle,
       );

  /// Returns a shallow copy of this [Excerpt]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Excerpt copyWith({
    Object? id = _Undefined,
    int? bookId,
    Object? book = _Undefined,
    String? content,
    int? position,
    Object? chapterTitle = _Undefined,
  }) {
    return Excerpt(
      id: id is int? ? id : this.id,
      bookId: bookId ?? this.bookId,
      book: book is _i2.Book? ? book : this.book?.copyWith(),
      content: content ?? this.content,
      position: position ?? this.position,
      chapterTitle: chapterTitle is String? ? chapterTitle : this.chapterTitle,
    );
  }
}
