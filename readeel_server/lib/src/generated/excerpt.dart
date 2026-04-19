/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: unnecessary_null_comparison

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import 'book.dart' as _i2;
import 'package:readeel_server/src/generated/protocol.dart' as _i3;

abstract class Excerpt
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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

  static final t = ExcerptTable();

  static const db = ExcerptRepository._();

  @override
  int? id;

  int bookId;

  _i2.Book? book;

  String content;

  int position;

  String? chapterTitle;

  @override
  _i1.Table<int?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Excerpt',
      if (id != null) 'id': id,
      'bookId': bookId,
      if (book != null) 'book': book?.toJsonForProtocol(),
      'content': content,
      'position': position,
      if (chapterTitle != null) 'chapterTitle': chapterTitle,
    };
  }

  static ExcerptInclude include({_i2.BookInclude? book}) {
    return ExcerptInclude._(book: book);
  }

  static ExcerptIncludeList includeList({
    _i1.WhereExpressionBuilder<ExcerptTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ExcerptTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ExcerptTable>? orderByList,
    ExcerptInclude? include,
  }) {
    return ExcerptIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Excerpt.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Excerpt.t),
      include: include,
    );
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

class ExcerptUpdateTable extends _i1.UpdateTable<ExcerptTable> {
  ExcerptUpdateTable(super.table);

  _i1.ColumnValue<int, int> bookId(int value) => _i1.ColumnValue(
    table.bookId,
    value,
  );

  _i1.ColumnValue<String, String> content(String value) => _i1.ColumnValue(
    table.content,
    value,
  );

  _i1.ColumnValue<int, int> position(int value) => _i1.ColumnValue(
    table.position,
    value,
  );

  _i1.ColumnValue<String, String> chapterTitle(String? value) =>
      _i1.ColumnValue(
        table.chapterTitle,
        value,
      );
}

class ExcerptTable extends _i1.Table<int?> {
  ExcerptTable({super.tableRelation}) : super(tableName: 'excerpts') {
    updateTable = ExcerptUpdateTable(this);
    bookId = _i1.ColumnInt(
      'bookId',
      this,
    );
    content = _i1.ColumnString(
      'content',
      this,
    );
    position = _i1.ColumnInt(
      'position',
      this,
    );
    chapterTitle = _i1.ColumnString(
      'chapterTitle',
      this,
    );
  }

  late final ExcerptUpdateTable updateTable;

  late final _i1.ColumnInt bookId;

  _i2.BookTable? _book;

  late final _i1.ColumnString content;

  late final _i1.ColumnInt position;

  late final _i1.ColumnString chapterTitle;

  _i2.BookTable get book {
    if (_book != null) return _book!;
    _book = _i1.createRelationTable(
      relationFieldName: 'book',
      field: Excerpt.t.bookId,
      foreignField: _i2.Book.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.BookTable(tableRelation: foreignTableRelation),
    );
    return _book!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    bookId,
    content,
    position,
    chapterTitle,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'book') {
      return book;
    }
    return null;
  }
}

class ExcerptInclude extends _i1.IncludeObject {
  ExcerptInclude._({_i2.BookInclude? book}) {
    _book = book;
  }

  _i2.BookInclude? _book;

  @override
  Map<String, _i1.Include?> get includes => {'book': _book};

  @override
  _i1.Table<int?> get table => Excerpt.t;
}

class ExcerptIncludeList extends _i1.IncludeList {
  ExcerptIncludeList._({
    _i1.WhereExpressionBuilder<ExcerptTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Excerpt.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Excerpt.t;
}

class ExcerptRepository {
  const ExcerptRepository._();

  final attachRow = const ExcerptAttachRowRepository._();

  /// Returns a list of [Excerpt]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<Excerpt>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ExcerptTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ExcerptTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ExcerptTable>? orderByList,
    _i1.Transaction? transaction,
    ExcerptInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Excerpt>(
      where: where?.call(Excerpt.t),
      orderBy: orderBy?.call(Excerpt.t),
      orderByList: orderByList?.call(Excerpt.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Excerpt] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<Excerpt?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ExcerptTable>? where,
    int? offset,
    _i1.OrderByBuilder<ExcerptTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ExcerptTable>? orderByList,
    _i1.Transaction? transaction,
    ExcerptInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Excerpt>(
      where: where?.call(Excerpt.t),
      orderBy: orderBy?.call(Excerpt.t),
      orderByList: orderByList?.call(Excerpt.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Excerpt] by its [id] or null if no such row exists.
  Future<Excerpt?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    ExcerptInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Excerpt>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Excerpt]s in the list and returns the inserted rows.
  ///
  /// The returned [Excerpt]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<Excerpt>> insert(
    _i1.DatabaseSession session,
    List<Excerpt> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<Excerpt>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [Excerpt] and returns the inserted row.
  ///
  /// The returned [Excerpt] will have its `id` field set.
  Future<Excerpt> insertRow(
    _i1.DatabaseSession session,
    Excerpt row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Excerpt>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Excerpt]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Excerpt>> update(
    _i1.DatabaseSession session,
    List<Excerpt> rows, {
    _i1.ColumnSelections<ExcerptTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Excerpt>(
      rows,
      columns: columns?.call(Excerpt.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Excerpt]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Excerpt> updateRow(
    _i1.DatabaseSession session,
    Excerpt row, {
    _i1.ColumnSelections<ExcerptTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Excerpt>(
      row,
      columns: columns?.call(Excerpt.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Excerpt] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Excerpt?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<ExcerptUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Excerpt>(
      id,
      columnValues: columnValues(Excerpt.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Excerpt]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Excerpt>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ExcerptUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ExcerptTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ExcerptTable>? orderBy,
    _i1.OrderByListBuilder<ExcerptTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Excerpt>(
      columnValues: columnValues(Excerpt.t.updateTable),
      where: where(Excerpt.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Excerpt.t),
      orderByList: orderByList?.call(Excerpt.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Excerpt]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Excerpt>> delete(
    _i1.DatabaseSession session,
    List<Excerpt> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Excerpt>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Excerpt].
  Future<Excerpt> deleteRow(
    _i1.DatabaseSession session,
    Excerpt row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Excerpt>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Excerpt>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ExcerptTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Excerpt>(
      where: where(Excerpt.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ExcerptTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Excerpt>(
      where: where?.call(Excerpt.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Excerpt] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ExcerptTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Excerpt>(
      where: where(Excerpt.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ExcerptAttachRowRepository {
  const ExcerptAttachRowRepository._();

  /// Creates a relation between the given [Excerpt] and [Book]
  /// by setting the [Excerpt]'s foreign key `bookId` to refer to the [Book].
  Future<void> book(
    _i1.DatabaseSession session,
    Excerpt excerpt,
    _i2.Book book, {
    _i1.Transaction? transaction,
  }) async {
    if (excerpt.id == null) {
      throw ArgumentError.notNull('excerpt.id');
    }
    if (book.id == null) {
      throw ArgumentError.notNull('book.id');
    }

    var $excerpt = excerpt.copyWith(bookId: book.id);
    await session.db.updateRow<Excerpt>(
      $excerpt,
      columns: [Excerpt.t.bookId],
      transaction: transaction,
    );
  }
}
