import 'dart:async';
import 'dart:typed_data';
import 'package:super_clipboard/super_clipboard.dart';

/// Represents a normalised clipboard payload ClipQ can work with.
class ClipboardPayload {
  final String contentType; // 'text' | 'html' | 'image'
  final String? textContent;
  final String? htmlContent;
  final Uint8List? imageBytes;

  const ClipboardPayload({
    required this.contentType,
    this.textContent,
    this.htmlContent,
    this.imageBytes,
  });

  /// The display content: HTML first, fallback to plain text.
  String get displayContent {
    if (contentType == 'image') return '[Image]';
    return htmlContent ?? textContent ?? '';
  }

  /// The raw string to store in Supabase text_content.
  String get storageContent => textContent ?? htmlContent ?? '';

  @override
  String toString() {
    if (contentType == 'image') return 'ClipboardPayload(image, ${imageBytes?.length ?? 0} bytes)';
    return 'ClipboardPayload($contentType, "${storageContent.substring(0, storageContent.length.clamp(0, 40))}...")';
  }
}

/// Wraps [super_clipboard] for safe cross-platform clipboard read/write.
///
/// Matches the structural template specified in the project blueprint.
class ClipboardService {
  const ClipboardService();

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Reads the current system clipboard content.
  ///
  /// Returns a [ClipboardPayload] or null if clipboard is unavailable or empty.
  Future<ClipboardPayload?> readClipboard() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) return null;

    final reader = await clipboard.read();

    // 1. Prefer image if available (PNG/JPEG)
    SimpleFileFormat? imageFormat;
    if (reader.canProvide(Formats.png)) {
      imageFormat = Formats.png;
    } else if (reader.canProvide(Formats.jpeg)) {
      imageFormat = Formats.jpeg;
    }

    if (imageFormat != null) {
      final completer = Completer<Uint8List?>();
      reader.getFile(imageFormat, (file) async {
        try {
          final bytes = await file.readAll();
          completer.complete(bytes);
        } catch (_) {
          completer.complete(null);
        }
      });
      final bytes = await completer.future;
      if (bytes != null && bytes.isNotEmpty) {
        return ClipboardPayload(
          contentType: 'image',
          imageBytes: bytes,
        );
      }
    }

    // 2. Prefer HTML (richer format), fall back to plain text.
    if (reader.canProvide(Formats.htmlText)) {
      final html = await reader.readValue(Formats.htmlText);
      final text = reader.canProvide(Formats.plainText)
          ? await reader.readValue(Formats.plainText)
          : null;
      if (html != null && html.isNotEmpty) {
        return ClipboardPayload(
          contentType: 'html',
          textContent: text,
          htmlContent: html,
        );
      }
    }

    // 3. Fallback to plain text.
    if (reader.canProvide(Formats.plainText)) {
      final text = await reader.readValue(Formats.plainText);
      if (text != null && text.isNotEmpty) {
        return ClipboardPayload(
          contentType: 'text',
          textContent: text,
        );
      }
    }

    return null;
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Writes a [ClipboardPayload] to the system clipboard.
  Future<void> writeClipboard(ClipboardPayload payload) async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) return;

    final item = DataWriterItem();

    if (payload.contentType == 'image' && payload.imageBytes != null) {
      item.add(Formats.png(payload.imageBytes!));
      item.add(Formats.jpeg(payload.imageBytes!));
    } else if (payload.contentType == 'html' && payload.htmlContent != null) {
      item.add(Formats.htmlText(payload.htmlContent!));
      if (payload.textContent != null) {
        item.add(Formats.plainText(payload.textContent!));
      }
    } else {
      item.add(Formats.plainText(payload.storageContent));
    }

    await clipboard.write([item]);
  }

  // ── Deduplication helper ──────────────────────────────────────────────────

  /// Returns true if [a] and [b] represent the same clipboard content.
  bool isSameContent(ClipboardPayload? a, ClipboardPayload? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.contentType != b.contentType) return false;
    if (a.contentType == 'image') {
      if (a.imageBytes == null || b.imageBytes == null) return false;
      if (a.imageBytes!.length != b.imageBytes!.length) return false;
      // Quick sample check to verify identity
      for (int i = 0; i < a.imageBytes!.length.clamp(0, 100); i++) {
        if (a.imageBytes![i] != b.imageBytes![i]) return false;
      }
      return true;
    }
    return a.storageContent == b.storageContent;
  }
}
