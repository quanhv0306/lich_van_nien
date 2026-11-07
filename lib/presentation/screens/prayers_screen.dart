import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/prayer_model.dart';
import '../../data/repositories/prayer_repository.dart';

/// 1. Trang Văn Khấn:
/// - Đọc dữ liệu từ `assets/data/prayers.json`.
/// - Thanh tìm kiếm theo tên hoặc dịp lễ.
/// - Danh mục lọc theo chip (Tất cả, Tết, Rằm/Mùng 1, Thần Tài, Gia Đình).
/// - Màn hình chi tiết văn khấn có nút tăng/giảm kích thước chữ rõ ràng để người lớn tuổi dễ đọc.
class PrayersScreen extends StatefulWidget {
  const PrayersScreen({super.key});

  @override
  State<PrayersScreen> createState() => _PrayersScreenState();
}

class _PrayersScreenState extends State<PrayersScreen> {
  static const String _prefFontSizeKey = 'prayer_font_size';

  final PrayerRepository _repository = PrayerRepository();
  List<PrayerModel> _allPrayers = [];

  static const List<String> _chipCategories = [
    'Tất cả',
    'Tết',
    'Rằm/Mùng 1',
    'Thần Tài',
    'Gia Đình',
  ];

  String _selectedChip = 'Tất cả';
  String _searchQuery = '';
  PrayerModel? _selectedPrayer;
  double _fontSize = 18.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prayers = await _repository.getAllPrayers();
    double savedFontSize = _fontSize;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getDouble(_prefFontSizeKey);
      if (stored != null && stored >= 12.0 && stored <= 36.0) {
        savedFontSize = stored;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _allPrayers = prayers;
      _fontSize = savedFontSize;
      if (prayers.isNotEmpty) {
        _selectedPrayer = prayers.first;
      }
      _isLoading = false;
    });
  }

  Future<void> _updateFontSize(double newSize) async {
    setState(() => _fontSize = newSize);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefFontSizeKey, newSize);
    } catch (_) {}
  }

  /// Ánh xạ danh mục gốc trong JSON sang 4 nhóm Chip (Tết, Rằm/Mùng 1, Thần Tài, Gia Đình)
  bool _matchesCategoryChip(PrayerModel prayer, String chip) {
    if (chip == 'Tất cả') return true;
    final cat = prayer.category.toLowerCase();
    switch (chip) {
      case 'Tết':
        return cat.contains('tất niên') ||
            cat.contains('giao thừa') ||
            cat.contains('tết');
      case 'Rằm/Mùng 1':
        return cat.contains('mùng 1') || cat.contains('rằm');
      case 'Thần Tài':
        return cat.contains('thần tài') || cat.contains('khai trương');
      case 'Gia Đình':
        return cat.contains('động thổ') ||
            cat.contains('nhập trạch') ||
            cat.contains('giỗ') ||
            cat.contains('gia đình');
      default:
        return cat == chip.toLowerCase();
    }
  }

  List<PrayerModel> get _filteredPrayers {
    return _allPrayers.where((p) {
      final matchesCategory = _matchesCategoryChip(p, _selectedChip);
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          p.title.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.targetDeity.toLowerCase().contains(q) ||
          p.prayerBody.toLowerCase().contains(q);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _openPrayerDetailSheet(PrayerModel prayer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFDF7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.90,
        minChildSize: 0.55,
        maxChildSize: 0.96,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setModalState) => _PrayerDetailContent(
            prayer: prayer,
            fontSize: _fontSize,
            scrollController: scrollController,
            onFontSizeChanged: (newSize) {
              _updateFontSize(newSize);
              setModalState(() {});
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final filtered = _filteredPrayers;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thanh tìm kiếm theo tên hoặc dịp lễ
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên bài khấn hoặc dịp lễ (Tết, Rằm, Thần Tài, Nhập trạch...)',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFFA61C1C),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () => setState(() => _searchQuery = ''),
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Danh mục lọc theo Chip (Tất cả, Tết, Rằm/Mùng 1, Thần Tài, Gia Đình)
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _chipCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final chip = _chipCategories[index];
                final selected = chip == _selectedChip;
                return ChoiceChip(
                  label: Text(chip),
                  selected: selected,
                  selectedColor: const Color(0xFFA61C1C),
                  backgroundColor: const Color(0xFFFFF8E7),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFFA61C1C)
                        : const Color(0xFFD4AF37),
                  ),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF4A2511),
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) => setState(() {
                    _selectedChip = chip;
                    final nextList = _filteredPrayers;
                    if (nextList.isNotEmpty) {
                      _selectedPrayer = nextList.first;
                    }
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Nội dung chính: Master-Detail trên màn hình rộng hoặc danh sách trên Mobile
          Expanded(
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: _buildPrayerList(filtered, isWide: true),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 6,
                        child: _selectedPrayer == null
                            ? const Center(
                                child: Text('Chọn một bài văn khấn để đọc'),
                              )
                            : Card(
                                elevation: 0,
                                color: const Color(0xFFFFFDF7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: const Color(0xFFD4AF37)
                                        .withValues(alpha: 0.55),
                                  ),
                                ),
                                child: _PrayerDetailContent(
                                  prayer: _selectedPrayer!,
                                  fontSize: _fontSize,
                                  onFontSizeChanged: _updateFontSize,
                                ),
                              ),
                      ),
                    ],
                  )
                : _buildPrayerList(filtered, isWide: false),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerList(List<PrayerModel> items, {required bool isWide}) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy bài văn khấn phù hợp.'),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final prayer = items[index];
        final isSelected = isWide && _selectedPrayer?.id == prayer.id;

        return Card(
          elevation: 0,
          color: isSelected ? const Color(0xFFFFF3CD) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFFA61C1C)
                  : const Color(0xFFD4AF37).withValues(alpha: 0.35),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFA61C1C),
              child: Icon(
                Icons.menu_book_rounded,
                color: Color(0xFFFFD54F),
                size: 20,
              ),
            ),
            title: Text(
              prayer.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF3E2723),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${prayer.category} • ${prayer.targetDeity}',
                style: TextStyle(fontSize: 12.5, color: Colors.brown.shade600),
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              setState(() => _selectedPrayer = prayer);
              if (!isWide) {
                _openPrayerDetailSheet(prayer);
              }
            },
          ),
        );
      },
    );
  }
}

class _PrayerDetailContent extends StatelessWidget {
  final PrayerModel prayer;
  final double fontSize;
  final ValueChanged<double> onFontSizeChanged;
  final ScrollController? scrollController;

  const _PrayerDetailContent({
    required this.prayer,
    required this.fontSize,
    required this.onFontSizeChanged,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        // Thanh công cụ điều chỉnh kích thước chữ nổi bật cho người lớn tuổi
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3CD),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD4AF37)),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.format_size_rounded,
                    size: 18,
                    color: Color(0xFF8E0000),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Cỡ chữ đọc khấn: ${fontSize.toInt()}pt',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: Color(0xFF4A2511),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: fontSize > 14
                        ? () => onFontSizeChanged(fontSize - 2.0)
                        : null,
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: const Color(0xFF8E0000),
                    ),
                    icon: const Icon(Icons.text_decrease_rounded, size: 16),
                    label: const Text('Chữ nhỏ'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: fontSize < 32
                        ? () => onFontSizeChanged(fontSize + 2.0)
                        : null,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: const Color(0xFFA61C1C),
                    ),
                    icon: const Icon(Icons.text_increase_rounded, size: 16),
                    label: const Text('Chữ to'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Tiêu đề & Đối tượng khấn
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFA61C1C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              prayer.category,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD54F),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          prayer.title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: Color(0xFF4A2511),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Đối tượng khấn: ${prayer.targetDeity}',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Colors.brown.shade700,
          ),
        ),

        const SizedBox(height: 16),

        // Sắm lễ tham khảo
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF6E4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: Color(0xFFA61C1C),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Lễ vật sắm lễ tham khảo:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A2511),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...prayer.offerings.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(fontSize: (fontSize * 0.82).clamp(13.5, 22.0)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),
        const Text(
          'BÀI VĂN KHẤN CỔ TRUYỀN',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: Color(0xFFA61C1C),
          ),
        ),
        const Divider(height: 16),
        SelectableText(
          prayer.prayerBody,
          style: TextStyle(
            fontSize: fontSize,
            height: 1.75,
            color: const Color(0xFF2D1E17),
          ),
        ),
      ],
    );
  }
}
