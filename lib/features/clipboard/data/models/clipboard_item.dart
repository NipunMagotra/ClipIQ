/// Model mirroring a row in the `clipboards` Supabase table.
class ClipboardItem {
  const ClipboardItem({
    required this.id,
    required this.userId,
    required this.contentType,
    this.textContent,
    this.storagePath,
    required this.copiedAt,
    required this.deviceId,
  });

  final String id;
  final String userId;

  /// One of: 'text', 'html', 'image'
  final String contentType;

  final String? textContent;
  final String? storagePath;
  final DateTime copiedAt;
  final String deviceId;

  // ── Factory ───────────────────────────────────────────────────────────────

  factory ClipboardItem.fromMap(Map<String, dynamic> map) {
    return ClipboardItem(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      contentType: map['content_type'] as String,
      textContent: map['text_content'] as String?,
      storagePath: map['storage_path'] as String?,
      copiedAt: DateTime.parse(map['copied_at'] as String),
      deviceId: map['device_id'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'content_type': contentType,
      'text_content': textContent,
      'storage_path': storagePath,
      'copied_at': copiedAt.toIso8601String(),
      'device_id': deviceId,
    };
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// The displayable text preview of this item.
  String get preview => textContent ?? storagePath ?? '';

  /// Whether this item was copied on the current device.
  bool isFromDevice(String currentDeviceId) => deviceId == currentDeviceId;

  ClipboardItem copyWith({
    String? id,
    String? userId,
    String? contentType,
    String? textContent,
    String? storagePath,
    DateTime? copiedAt,
    String? deviceId,
  }) {
    return ClipboardItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contentType: contentType ?? this.contentType,
      textContent: textContent ?? this.textContent,
      storagePath: storagePath ?? this.storagePath,
      copiedAt: copiedAt ?? this.copiedAt,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClipboardItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ClipboardItem(id: $id, type: $contentType, at: $copiedAt)';
}
