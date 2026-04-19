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
import 'excerpt.dart' as _i2;
import 'book.dart' as _i3;
import 'package:readeel_client/src/protocol/protocol.dart' as _i4;

abstract class ExcerptWithBook implements _i1.SerializableModel {
  ExcerptWithBook._({
    required this.excerpt,
    required this.book,
  });

  factory ExcerptWithBook({
    required _i2.Excerpt excerpt,
    required _i3.Book book,
  }) = _ExcerptWithBookImpl;

  factory ExcerptWithBook.fromJson(Map<String, dynamic> jsonSerialization) {
    return ExcerptWithBook(
      excerpt: _i4.Protocol().deserialize<_i2.Excerpt>(
        jsonSerialization['excerpt'],
      ),
      book: _i4.Protocol().deserialize<_i3.Book>(jsonSerialization['book']),
    );
  }

  _i2.Excerpt excerpt;

  _i3.Book book;

  /// Returns a shallow copy of this [ExcerptWithBook]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ExcerptWithBook copyWith({
    _i2.Excerpt? excerpt,
    _i3.Book? book,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ExcerptWithBook',
      'excerpt': excerpt.toJson(),
      'book': book.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ExcerptWithBookImpl extends ExcerptWithBook {
  _ExcerptWithBookImpl({
    required _i2.Excerpt excerpt,
    required _i3.Book book,
  }) : super._(
         excerpt: excerpt,
         book: book,
       );

  /// Returns a shallow copy of this [ExcerptWithBook]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ExcerptWithBook copyWith({
    _i2.Excerpt? excerpt,
    _i3.Book? book,
  }) {
    return ExcerptWithBook(
      excerpt: excerpt ?? this.excerpt.copyWith(),
      book: book ?? this.book.copyWith(),
    );
  }
}
