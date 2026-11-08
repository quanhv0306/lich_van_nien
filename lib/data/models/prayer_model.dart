class PrayerModel {
  final String id;
  final String title;
  final String category;
  final String meaning;
  final String offerings;
  final String bestTime;
  final String content;

  const PrayerModel({
    required this.id,
    required this.title,
    required this.category,
    required this.meaning,
    required this.offerings,
    required this.bestTime,
    required this.content,
  });

  factory PrayerModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawOfferings = json['offerings'];
    final String offeringsStr = rawOfferings is List
        ? rawOfferings.map((e) => e.toString()).join(', ')
        : (rawOfferings as String? ?? '');

    return PrayerModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      meaning: (json['meaning'] ?? json['target_deity']) as String? ?? '',
      offerings: offeringsStr,
      bestTime: (json['best_time'] ?? json['occasion']) as String? ?? '',
      content: (json['content'] ?? json['prayer_body']) as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'meaning': meaning,
        'offerings': offerings,
        'best_time': bestTime,
        'content': content,
      };
}
