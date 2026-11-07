class PrayerModel {
  final String id;
  final String title;
  final String category;
  final String targetDeity;
  final List<String> offerings;
  final String prayerBody;

  const PrayerModel({
    required this.id,
    required this.title,
    required this.category,
    required this.targetDeity,
    required this.offerings,
    required this.prayerBody,
  });

  factory PrayerModel.fromJson(Map<String, dynamic> json) {
    return PrayerModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      targetDeity: (json['target_deity'] ?? json['occasion']) as String? ?? '',
      offerings: (json['offerings'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      prayerBody: (json['prayer_body'] ?? json['content']) as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'target_deity': targetDeity,
        'offerings': offerings,
        'prayer_body': prayerBody,
      };
}
