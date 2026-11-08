import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/sync_engine.dart';
import '../../data/models/prayer_model.dart';
import '../../data/repositories/prayer_repository.dart';
import 'prayer_detail_screen.dart';

/// Màn hình Kho Văn Khấn Cổ Truyền Việt Nam:
/// - Đọc 22 bài văn khấn chuẩn cổ truyền từ `assets/data/prayers.json` chia theo 4 nhóm lớn:
///   + Lễ Tết & Đầu năm
///   + Tiết lễ trong năm
///   + Gia đình & Đời sống
///   + Kinh doanh & Điền trạch
/// - Tích hợp bộ điền nhanh `[Họ tên]` và `[Địa chỉ]` (tự động lưu qua `shared_preferences`
///   và thay thế trực tiếp vào lời văn khấn).
/// - Thanh tăng / giảm kích thước chữ rõ nét cho người lớn tuổi.
class PrayersScreen extends StatefulWidget {
  const PrayersScreen({super.key});

  @override
  State<PrayersScreen> createState() => _PrayersScreenState();
}

class _PrayersScreenState extends State<PrayersScreen> {
  static const String _prefFontSizeKey = 'prayer_font_size';
  static const String _prefUserNameKey = 'prayer_user_fullname';
  static const String _prefUserAddressKey = 'prayer_user_address';

  final PrayerRepository _repository = PrayerRepository();
  List<PrayerModel> _allPrayers = [];

  static const List<String> _chipCategories = [
    'Tất cả',
    'Lễ Tết & Đầu năm',
    'Tiết lễ trong năm',
    'Gia đình & Đời sống',
    'Kinh doanh & Điền trạch',
  ];

  String _selectedChip = 'Tất cả';
  String _searchQuery = '';
  PrayerModel? _selectedPrayer;
  double _fontSize = 18.0;
  String _userName = '';
  String _userAddress = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final p = SyncEngine.instance.profile;
    _userName = p.fullName;
    _userAddress = p.address;
    _fontSize = p.prayerFontSize.clamp(12.0, 36.0);
    SyncEngine.instance.addListener(_onSyncedProfileChanged);
    _loadData();
  }

  @override
  void dispose() {
    SyncEngine.instance.removeListener(_onSyncedProfileChanged);
    super.dispose();
  }

  void _onSyncedProfileChanged() {
    if (!mounted) return;
    final p = SyncEngine.instance.profile;
    final clampedSize = p.prayerFontSize.clamp(12.0, 36.0);
    if (p.fullName != _userName ||
        p.address != _userAddress ||
        clampedSize != _fontSize) {
      setState(() {
        _userName = p.fullName;
        _userAddress = p.address;
        _fontSize = clampedSize;
      });
    }
  }

  Future<void> _loadData() async {
    final prayers = await _repository.getAllPrayers();
    double savedFontSize = _fontSize;
    String savedName = '';
    String savedAddress = '';

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedSize = prefs.getDouble(_prefFontSizeKey);
      if (storedSize != null && storedSize >= 12.0 && storedSize <= 36.0) {
        savedFontSize = storedSize;
      }
      savedName = prefs.getString(_prefUserNameKey) ?? '';
      savedAddress = prefs.getString(_prefUserAddressKey) ?? '';
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _allPrayers = prayers;
      _fontSize = savedFontSize;
      _userName = savedName;
      _userAddress = savedAddress;
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
    SyncEngine.instance.updateProfileLocalFirst(prayerFontSize: newSize);
  }

  Future<void> _updateUserInfo(String name, String address) async {
    setState(() {
      _userName = name.trim();
      _userAddress = address.trim();
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefUserNameKey, _userName);
      await prefs.setString(_prefUserAddressKey, _userAddress);
    } catch (_) {}
    SyncEngine.instance.updateProfileLocalFirst(
      fullName: _userName,
      address: _userAddress,
    );
  }

  Future<void> _showPersonalizeDialog() async {
    final nameController = TextEditingController(text: _userName);
    final addressController = TextEditingController(text: _userAddress);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF7),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: Color(0xFFA61C1C)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Điền sẵn [Họ tên] & [Địa chỉ] Tín chủ',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8E0000),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Thông tin này sẽ tự động điền vào vị trí [Họ tên] và [Địa chỉ] trong tất cả bài văn khấn để bạn thuận tiện đọc khi hành lễ.',
              style: TextStyle(fontSize: 13, color: Color(0xFF5D4037)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Họ và tên Tín chủ',
                hintText: 'Ví dụ: Nguyễn Văn A',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ cư ngụ / hành lễ',
                hintText: 'Ví dụ: Số 10 phố..., phường..., TP...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFA61C1C),
            ),
            onPressed: () {
              _updateUserInfo(nameController.text, addressController.text);
              Navigator.of(context).pop();
            },
            child: const Text('Lưu thông tin'),
          ),
        ],
      ),
    );
  }

  List<PrayerModel> get _filteredPrayers {
    return _allPrayers.where((p) {
      final matchesCategory =
          _selectedChip == 'Tất cả' || p.category == _selectedChip;
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          p.title.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.meaning.toLowerCase().contains(q) ||
          p.offerings.toLowerCase().contains(q) ||
          p.content.toLowerCase().contains(q);
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
          builder: (context, setModalState) => PrayerDetailScreen(
            prayer: prayer,
            fontSize: _fontSize,
            userName: _userName,
            userAddress: _userAddress,
            scrollController: scrollController,
            onFontSizeChanged: (newSize) {
              _updateFontSize(newSize);
              setModalState(() {});
            },
            onEditUserInfo: () async {
              await _showPersonalizeDialog();
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
          // Thanh tìm kiếm + Nút điền sẵn [Họ tên] & [Địa chỉ]
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText:
                        'Tìm bài văn khấn (Táo Quân, Giao thừa, Vu Lan, Khai trương, Thần Tài...)',
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
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _showPersonalizeDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8E0000),
                  backgroundColor: const Color(0xFFFFF8E7),
                  side: const BorderSide(color: Color(0xFFD4AF37)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.person_pin_rounded, size: 18),
                label: Text(
                  _userName.isEmpty ? 'Điền Họ tên' : _userName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Danh mục lọc theo Chip (Tất cả + 4 nhóm nghi lễ truyền thống)
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
                                child: PrayerDetailScreen(
                                  prayer: _selectedPrayer!,
                                  fontSize: _fontSize,
                                  userName: _userName,
                                  userAddress: _userAddress,
                                  onFontSizeChanged: _updateFontSize,
                                  onEditUserInfo: _showPersonalizeDialog,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prayer.category,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFA61C1C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    prayer.meaning,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.brown.shade700,
                    ),
                  ),
                ],
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
