import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart' hide CalendarEvent;
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/sync_engine.dart';

/// Màn hình Đồng bộ Đa thiết bị (PC, Android, iOS) theo kiến trúc LOCAL-FIRST TUYỆT ĐỐI:
/// - Mọi thao tác đọc/ghi chỉ làm việc với Local Storage (`SyncEngine.instance`), phản hồi 0ms.
/// - Không bao giờ bắt UI `await` kết quả mạng từ Supabase.
/// - Hỗ trợ tạo mã 6 số + hiển thị QR Code (`qr_flutter`) hoặc nhập mã / quét QR (`mobile_scanner`).
class SyncScreen extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime>? onSelectEventDate;

  const SyncScreen({
    super.key,
    required this.selectedDate,
    this.onSelectEventDate,
  });

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final TextEditingController _codeInputController = TextEditingController();
  String? _inputHintError;

  @override
  void dispose() {
    _codeInputController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateSyncCode() async {
    setState(() => _inputHintError = null);
    await SyncEngine.instance.createNewSyncCode();
  }

  Future<void> _handleConnectCode([String? rawOverride]) async {
    final raw = (rawOverride ?? _codeInputController.text).trim();
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 6) {
      setState(() {
        _inputHintError = 'Vui lòng nhập đủ 6 chữ số mã đồng bộ (ví dụ: 123456).';
      });
      return;
    }
    setState(() => _inputHintError = null);
    _codeInputController.clear();
    await SyncEngine.instance.connectWithSyncCode(digits);
  }

  Future<void> _openQrScannerModal() async {
    final scannedCode = await showDialog<String>(
      context: context,
      builder: (context) => const _QrScannerDialog(),
    );

    if (scannedCode != null && scannedCode.isNotEmpty && mounted) {
      final digits = scannedCode.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length == 6) {
        _codeInputController.text = digits;
        await _handleConnectCode(digits);
      } else {
        setState(() {
          _inputHintError = 'Mã QR không hợp lệ (cần chứa đúng 6 chữ số).';
        });
      }
    }
  }

  Future<void> _showAddOrEditEventDialog({CalendarEvent? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    DateTime chosenDate = existing != null
        ? (DateTime.tryParse(existing.solarDateKey) ?? widget.selectedDate)
        : widget.selectedDate;
    bool isLunarRecurring = existing?.isLunarRecurring ?? false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFFFDF7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFD4AF37)),
              ),
              title: Row(
                children: [
                  const Icon(Icons.event_note_rounded, color: Color(0xFFA61C1C)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      existing == null
                          ? 'Thêm Sự Kiện / Ghi Chú'
                          : 'Chỉnh Sửa Sự Kiện',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8E0000),
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Tiêu đề sự kiện / ghi chú *',
                        hintText: 'VD: Giỗ tổ, Họp gia đình, Cúng Rằm...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Nội dung chi tiết',
                        hintText: 'Ghi chú lễ vật, giờ giấc, địa điểm...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: chosenDate,
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => chosenDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        'Ngày Dương lịch: ${chosenDate.day.toString().padLeft(2, '0')}/${chosenDate.month.toString().padLeft(2, '0')}/${chosenDate.year}',
                      ),
                    ),
                    const SizedBox(height: 6),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: isLunarRecurring,
                      activeColor: const Color(0xFFA61C1C),
                      title: const Text(
                        'Nhắc định kỳ hàng năm theo Âm lịch',
                        style: TextStyle(fontSize: 13.5),
                      ),
                      onChanged: (val) {
                        setDialogState(() => isLunarRecurring = val ?? false);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFA61C1C),
                    foregroundColor: const Color(0xFFFFD54F),
                  ),
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    // Cập nhật Local-First 0ms (không await Supabase)
                    SyncEngine.instance.upsertEventLocalFirst(
                      id: existing?.id,
                      title: title,
                      note: noteCtrl.text.trim(),
                      solarDate: chosenDate,
                      isLunarRecurring: isLunarRecurring,
                    );
                    Navigator.of(dialogContext).pop();
                  },
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Lưu ngay (Local-First)'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SyncEngine.instance,
      builder: (context, _) {
        final engine = SyncEngine.instance;
        final isPaired = engine.isPaired;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildArchitectureBanner(engine),
                  const SizedBox(height: 16),
                  if (!isPaired)
                    _buildUnpairedSection(engine)
                  else
                    _buildPairedSection(engine),
                  const SizedBox(height: 18),
                  _buildSyncedProfileSummaryCard(engine),
                  const SizedBox(height: 18),
                  _buildSyncedEventsCard(engine),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Banner giới thiệu kiến trúc Local-First / Offline-First
  Widget _buildArchitectureBanner(SyncEngine engine) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E0000), Color(0xFFA61C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.4),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.offline_bolt_rounded,
              color: Color(0xFFFFD54F),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ĐỒNG BỘ ĐA THIẾT BỊ • LOCAL-FIRST TUYỆT ĐỐI',
                  style: TextStyle(
                    color: Color(0xFFFFD54F),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Mọi dữ liệu Lịch, Hồ sơ Bản mệnh & Sự kiện luôn được lưu trực tiếp trên máy (0ms) và tự động hợp nhất 2 chiều ngầm qua đám mây khi có mạng.',
                  style: TextStyle(
                    color: Color(0xFFFFF8E1),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Giao diện khi CHƯA có `sync_code`:
  /// - Nút "Tạo mã đồng bộ"
  /// - Khung "Kết nối thiết bị khác" (Ô nhập 6 số + Nút mở Camera quét QR)
  Widget _buildUnpairedSection(SyncEngine engine) {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFDF7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA61C1C).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.devices_rounded,
                    color: Color(0xFFA61C1C),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ghép Đôi Thiết Bị (PC • Android • iOS)',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A2511),
                        ),
                      ),
                      Text(
                        'Chưa kết nối mã đồng bộ. Dữ liệu hiện tại đang lưu an toàn trên thiết bị này.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF795548),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 1. Khung khởi tạo mã đồng bộ mới
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1. Thiết bị này là máy chính?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: Color(0xFF8E0000),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tạo một mã ngẫu nhiên gồm 6 chữ số kèm mã QR để các thiết bị khác (điện thoại, máy tính bảng, PC) quét hoặc nhập vào.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF5D4037)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _handleCreateSyncCode,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFA61C1C),
                        foregroundColor: const Color(0xFFFFD54F),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.qr_code_2_rounded, size: 22),
                      label: const Text(
                        'Tạo mã đồng bộ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Khung Kết nối thiết bị khác
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '2. Kết nối thiết bị khác',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: Color(0xFF4A2511),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Nhập mã 6 chữ số đang hiển thị trên thiết bị kia hoặc dùng Camera để quét mã QR:',
                    style: TextStyle(fontSize: 13, color: Color(0xFF5D4037)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 240,
                        child: TextField(
                          controller: _codeInputController,
                          keyboardType: TextInputType.number,
                          maxLength: 7,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9\-]'),
                            ),
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'Nhập 6 số (VD: 123456)',
                            prefixIcon: const Icon(
                              Icons.pin_outlined,
                              color: Color(0xFFA61C1C),
                            ),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onSubmitted: (_) => _handleConnectCode(),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _handleConnectCode,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4A2511),
                          foregroundColor: const Color(0xFFFFD54F),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.link_rounded, size: 19),
                        label: const Text(
                          'Kết nối',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _openQrScannerModal,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFA61C1C),
                          side: const BorderSide(color: Color(0xFFA61C1C)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 19,
                        ),
                        label: const Text(
                          'Quét mã QR',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (_inputHintError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _inputHintError!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Giao diện khi ĐÃ có `sync_code`:
  /// - Hiển thị mã đang kết nối (`xxx-xxx`) + QR Code lớn (`QrImageView`)
  /// - Icon trạng thái: Xanh lá (Đã đồng bộ) / Vàng cam (Đang chờ đồng bộ do offline)
  /// - Nút "Đồng bộ thủ công" (kèm vòng xoay nhỏ tinh tế khi đang sync) và nút "Ngắt kết nối"
  Widget _buildPairedSection(SyncEngine engine) {
    final isSyncedClean = !engine.isDirty;
    final statusColor = isSyncedClean
        ? const Color(0xFF2E7D32)
        : const Color(0xFFE65100);
    final statusBgColor = isSyncedClean
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFF3E0);
    final statusText = isSyncedClean
        ? 'Đã đồng bộ'
        : 'Đang chờ đồng bộ (Offline / Chưa đẩy lên mây)';
    final statusIcon = isSyncedClean
        ? Icons.cloud_done_rounded
        : Icons.cloud_queue_rounded;

    return Card(
      elevation: 0,
      color: const Color(0xFFFFFDF7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hàng trạng thái kết nối
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          if (engine.lastSyncedAt != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              'Lần đồng bộ gần nhất: ${_formatTime(engine.lastSyncedAt!)}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF795548),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // Nhóm nút Đồng bộ thủ công & Ngắt kết nối
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: engine.isSyncing
                          ? null
                          : () => SyncEngine.instance.syncNow(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFA61C1C),
                        foregroundColor: const Color(0xFFFFD54F),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: engine.isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFFD54F),
                              ),
                            )
                          : const Icon(Icons.sync_rounded, size: 18),
                      label: Text(
                        engine.isSyncing
                            ? 'Đang đồng bộ...'
                            : 'Đồng bộ thủ công',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => SyncEngine.instance.disconnectSyncCode(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8E0000),
                        side: const BorderSide(color: Color(0xFF8E0000)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.link_off_rounded, size: 18),
                      label: const Text('Ngắt kết nối'),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 28),

            // Hiển thị Mã 6 số thật to + Mã QR để thiết bị khác quét
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 24,
              runSpacing: 20,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'MÃ ĐỒNG BỘ ĐANG KẾT NỐI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Color(0xFF795548),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8EC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFA61C1C),
                          width: 1.6,
                        ),
                      ),
                      child: SelectableText(
                        engine.formattedSyncCode,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                          color: Color(0xFFA61C1C),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        final code = engine.syncCode ?? '';
                        Clipboard.setData(ClipboardData(text: code));
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Sao chép mã 6 số'),
                    ),
                  ],
                ),

                // Khung QR Code từ `qr_flutter`
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFD4AF37),
                      width: 1.4,
                    ),
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: engine.syncCode ?? '',
                        version: QrVersions.auto,
                        size: 160.0,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF8E0000),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF2D1E17),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Quét QR trên thiết bị khác',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Thẻ tóm tắt Hồ sơ Bản mệnh & Tín chủ đang lưu Local
  Widget _buildSyncedProfileSummaryCard(SyncEngine engine) {
    final p = engine.profile;
    final genderLabel = p.gender == 'female' ? 'Nữ mệnh' : 'Nam mệnh';
    final calType = p.isLunar ? 'Âm lịch' : 'Dương lịch';

    return Card(
      elevation: 0,
      color: const Color(0xFFFFFDF7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.badge_rounded, color: Color(0xFFA61C1C), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hồ Sơ Bản Mệnh & Tín Chủ (Local-First)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A2511),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  Icons.cake_rounded,
                  'Ngày sinh: ${p.birthDay.toString().padLeft(2, '0')}/${p.birthMonth.toString().padLeft(2, '0')}/${p.birthYear} ($calType)',
                ),
                _buildInfoChip(Icons.person_rounded, 'Giới tính: $genderLabel'),
                _buildInfoChip(
                  Icons.edit_note_rounded,
                  'Tín chủ: ${p.fullName.isEmpty ? "Chưa điền" : p.fullName}',
                ),
                _buildInfoChip(
                  Icons.home_work_rounded,
                  'Địa chỉ khấn: ${p.address.isEmpty ? "Chưa điền" : p.address}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFA61C1C)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A2511),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Danh sách Sự kiện & Ghi chú Lịch (Hỗ trợ Merge 2 chiều theo ID + Tombstone `is_deleted`)
  Widget _buildSyncedEventsCard(SyncEngine engine) {
    final events = engine.activeEvents;

    return Card(
      elevation: 0,
      color: const Color(0xFFFFFDF7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.event_available_rounded,
                      color: Color(0xFFA61C1C),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Sự Kiện & Ghi Chú Cá Nhân (${events.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A2511),
                        ),
                      ),
                    ),
                  ],
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _showAddOrEditEventDialog(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFECB3),
                    foregroundColor: const Color(0xFF8E0000),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Thêm ghi chú sự kiện',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (events.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8EC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Chưa có sự kiện hoặc ghi chú nào. Bạn có thể bấm "Thêm ghi chú sự kiện" ngay cả khi không có mạng — ứng dụng sẽ lưu tức thì vào máy và tự động hợp nhất 2 chiều khi kết nối mạng.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF5D4037)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length,
                separatorBuilder: (_, _) => const Divider(height: 12),
                itemBuilder: (context, index) {
                  final evt = events[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA61C1C),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        evt.solarDateKey,
                        style: const TextStyle(
                          color: Color(0xFFFFD54F),
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    title: Text(
                      evt.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF2D1E17),
                      ),
                    ),
                    subtitle: evt.note.isNotEmpty
                        ? Text(
                            evt.note,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF5D4037),
                            ),
                          )
                        : null,
                    onTap: () {
                      final parsed = DateTime.tryParse(evt.solarDateKey);
                      if (parsed != null && widget.onSelectEventDate != null) {
                        widget.onSelectEventDate!(parsed);
                      }
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Sửa sự kiện',
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 19,
                            color: Color(0xFF5D4037),
                          ),
                          onPressed: () =>
                              _showAddOrEditEventDialog(existing: evt),
                        ),
                        IconButton(
                          tooltip: 'Xóa sự kiện (Tombstone Sync)',
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 19,
                            color: Colors.redAccent,
                          ),
                          onPressed: () =>
                              SyncEngine.instance.deleteEventLocalFirst(evt.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final ss = local.second.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    return '$hh:$mm:$ss ($dd/$mo/${local.year})';
  }
}

/// Hộp thoại mở Camera quét mã QR 6 số bằng `mobile_scanner`
class _QrScannerDialog extends StatefulWidget {
  const _QrScannerDialog();

  @override
  State<_QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<_QrScannerDialog> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _hasPopped = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFFFDF7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFD4AF37)),
      ),
      title: const Row(
        children: [
          Icon(Icons.qr_code_scanner_rounded, color: Color(0xFFA61C1C)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Quét Mã QR Đồng Bộ',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8E0000),
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        height: 320,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              if (_hasPopped) return;
              for (final barcode in capture.barcodes) {
                final raw = barcode.rawValue;
                if (raw != null && raw.trim().isNotEmpty) {
                  _hasPopped = true;
                  Navigator.of(context).pop(raw.trim());
                  break;
                }
              }
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
