

class Quote {
  final String? id;
  final String content;
  final List<String> categories;

  Quote({
    this.id,
    required this.content,
    this.categories = const [],
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();  

    return Quote(
      id: id,
      content: json['content'],
      categories: (json['categories'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'categories': categories,
    };
  }
}
