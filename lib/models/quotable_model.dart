// To parse this JSON data, do
//
//     final quoteApi = quoteApiFromJson(jsonString);

import 'dart:convert';

Quotable quoteApiFromJson(String str) => Quotable.fromJson(json.decode(str));

String quoteApiToJson(Quotable data) => json.encode(data.toJson());

class Quotable {
  final String? id;
  final String? content;
  final String? author;
  final List<String>? tags;
  final String? authorSlug;
  final int? length;
  final DateTime? dateAdded;
  final DateTime? dateModified;

  Quotable({
    this.id,
    this.content,
    this.author,
    this.tags,
    this.authorSlug,
    this.length,
    this.dateAdded,
    this.dateModified,
  });

  Quotable copyWith({
    String? id,
    String? content,
    String? author,
    List<String>? tags,
    String? authorSlug,
    int? length,
    DateTime? dateAdded,
    DateTime? dateModified,
  }) =>
      Quotable(
        id: id ?? this.id,
        content: content ?? this.content,
        author: author ?? this.author,
        tags: tags ?? this.tags,
        authorSlug: authorSlug ?? this.authorSlug,
        length: length ?? this.length,
        dateAdded: dateAdded ?? this.dateAdded,
        dateModified: dateModified ?? this.dateModified,
      );

  factory Quotable.fromJson(Map<String, dynamic> json) {
    DateTime? date(Object? value) =>
        value == null ? null : DateTime.tryParse(value.toString());
    final length = json['length'];

    return Quotable(
      id: json['_id']?.toString(),
      content: json['content']?.toString(),
      author: json['author']?.toString(),
      tags: json['tags'] is List
          ? (json['tags'] as List).map((tag) => tag.toString()).toList()
          : const [],
      authorSlug: json['authorSlug']?.toString(),
      length: length is num ? length.toInt() : null,
      dateAdded: date(json['dateAdded']),
      dateModified: date(json['dateModified']),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'content': content,
        'author': author,
        'tags': tags ?? const [],
        'authorSlug': authorSlug,
        'length': length,
        'dateAdded': dateAdded?.toIso8601String(),
        'dateModified': dateModified?.toIso8601String(),
      };
}
