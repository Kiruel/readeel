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

abstract class Book implements _i1.SerializableModel {
  Book._({
    this.id,
    required this.title,
    required this.author,
    this.description,
    this.coverUrl,
    this.isbn,
    this.publishedYear,
    required this.language,
    required this.source,
    required this.externalId,
    required this.isPublicDomain,
    this.content,
    this.amazonLink,
    this.amazonAsin,
  });

  factory Book({
    int? id,
    required String title,
    required String author,
    String? description,
    String? coverUrl,
    String? isbn,
    int? publishedYear,
    required String language,
    required String source,
    required String externalId,
    required bool isPublicDomain,
    String? content,
    String? amazonLink,
    String? amazonAsin,
  }) = _BookImpl;

  factory Book.fromJson(Map<String, dynamic> jsonSerialization) {
    return Book(
      id: jsonSerialization['id'] as int?,
      title: jsonSerialization['title'] as String,
      author: jsonSerialization['author'] as String,
      description: jsonSerialization['description'] as String?,
      coverUrl: jsonSerialization['coverUrl'] as String?,
      isbn: jsonSerialization['isbn'] as String?,
      publishedYear: jsonSerialization['publishedYear'] as int?,
      language: jsonSerialization['language'] as String,
      source: jsonSerialization['source'] as String,
      externalId: jsonSerialization['externalId'] as String,
      isPublicDomain: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['isPublicDomain'],
      ),
      content: jsonSerialization['content'] as String?,
      amazonLink: jsonSerialization['amazonLink'] as String?,
      amazonAsin: jsonSerialization['amazonAsin'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String title;

  String author;

  String? description;

  String? coverUrl;

  String? isbn;

  int? publishedYear;

  String language;

  String source;

  String externalId;

  bool isPublicDomain;

  String? content;

  String? amazonLink;

  String? amazonAsin;

  /// Returns a shallow copy of this [Book]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Book copyWith({
    int? id,
    String? title,
    String? author,
    String? description,
    String? coverUrl,
    String? isbn,
    int? publishedYear,
    String? language,
    String? source,
    String? externalId,
    bool? isPublicDomain,
    String? content,
    String? amazonLink,
    String? amazonAsin,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Book',
      if (id != null) 'id': id,
      'title': title,
      'author': author,
      if (description != null) 'description': description,
      if (coverUrl != null) 'coverUrl': coverUrl,
      if (isbn != null) 'isbn': isbn,
      if (publishedYear != null) 'publishedYear': publishedYear,
      'language': language,
      'source': source,
      'externalId': externalId,
      'isPublicDomain': isPublicDomain,
      if (content != null) 'content': content,
      if (amazonLink != null) 'amazonLink': amazonLink,
      if (amazonAsin != null) 'amazonAsin': amazonAsin,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BookImpl extends Book {
  _BookImpl({
    int? id,
    required String title,
    required String author,
    String? description,
    String? coverUrl,
    String? isbn,
    int? publishedYear,
    required String language,
    required String source,
    required String externalId,
    required bool isPublicDomain,
    String? content,
    String? amazonLink,
    String? amazonAsin,
  }) : super._(
         id: id,
         title: title,
         author: author,
         description: description,
         coverUrl: coverUrl,
         isbn: isbn,
         publishedYear: publishedYear,
         language: language,
         source: source,
         externalId: externalId,
         isPublicDomain: isPublicDomain,
         content: content,
         amazonLink: amazonLink,
         amazonAsin: amazonAsin,
       );

  /// Returns a shallow copy of this [Book]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Book copyWith({
    Object? id = _Undefined,
    String? title,
    String? author,
    Object? description = _Undefined,
    Object? coverUrl = _Undefined,
    Object? isbn = _Undefined,
    Object? publishedYear = _Undefined,
    String? language,
    String? source,
    String? externalId,
    bool? isPublicDomain,
    Object? content = _Undefined,
    Object? amazonLink = _Undefined,
    Object? amazonAsin = _Undefined,
  }) {
    return Book(
      id: id is int? ? id : this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description is String? ? description : this.description,
      coverUrl: coverUrl is String? ? coverUrl : this.coverUrl,
      isbn: isbn is String? ? isbn : this.isbn,
      publishedYear: publishedYear is int? ? publishedYear : this.publishedYear,
      language: language ?? this.language,
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
      isPublicDomain: isPublicDomain ?? this.isPublicDomain,
      content: content is String? ? content : this.content,
      amazonLink: amazonLink is String? ? amazonLink : this.amazonLink,
      amazonAsin: amazonAsin is String? ? amazonAsin : this.amazonAsin,
    );
  }
}
