import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/prayer_model.dart';

/// Repository đọc danh sách bài văn khấn từ `assets/data/prayers.json`
class PrayerRepository {
  List<PrayerModel>? _cachedPrayers;

  Future<List<PrayerModel>> getAllPrayers() async {
    if (_cachedPrayers != null) {
      return _cachedPrayers!;
    }
    final raw = await rootBundle.loadString('assets/data/prayers.json');
    final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
    _cachedPrayers = decoded
        .map((item) => PrayerModel.fromJson(item as Map<String, dynamic>))
        .toList();
    return _cachedPrayers!;
  }

  Future<List<String>> getCategories() async {
    final prayers = await getAllPrayers();
    final categories = <String>{'Tất cả'};
    for (final p in prayers) {
      categories.add(p.category);
    }
    return categories.toList();
  }
}
