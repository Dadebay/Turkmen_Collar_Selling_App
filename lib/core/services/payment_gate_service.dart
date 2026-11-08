// ignore_for_file: avoid_slow_async_io
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Persistence and payload parsing for the "you topped up less than 20 TMT"
/// gate pushed by the backend as an FCM data message.
///
/// Deliberately free of Flutter UI imports: the FCM background handler runs in
/// a separate isolate that has no widget tree, and cannot reach the Hive boxes
/// opened by `LocalStorage.init()` on the main isolate either — hence a plain
/// JSON file in the documents directory as the cross-isolate channel.
class PaymentGateService {
  const PaymentGateService._();

  /// The user paid, but under the minimum: block them behind the gate dialog.
  static const String statusAmountTooLow = 'AMOUNT_TOO_LOW';

  /// The balance was topped up properly: release the gate.
  static const String statusCompleted = 'COMPLETED';

  static const String _syncFileName = 'notification_status_sync.json';

  /// FCM delivers the transaction fields either at the top level or nested
  /// under a `data` key holding a JSON string. Merge the nested map over the
  /// top level so callers only ever deal with one shape.
  static Map<String, dynamic> flatten(Map<String, dynamic> data) {
    try {
      final flattened = Map<String, dynamic>.from(data);
      final nested = data['data'];
      if (nested is String && nested.isNotEmpty) {
        final decoded = json.decode(nested);
        if (decoded is Map<String, dynamic>) {
          flattened.addAll(decoded);
        }
      } else if (nested is Map<String, dynamic>) {
        flattened.addAll(nested);
      }
      return flattened;
    } catch (e) {
      log('⚠️ [PAYMENT GATE] Failed to flatten data: $e');
      return data;
    }
  }

  static String? statusOf(Map<String, dynamic> data) =>
      flatten(data)['status']?.toString();

  /// True for the two statuses the gate owns. Those suppress the visible
  /// notification — the dialog is the whole message.
  static bool isGateStatus(String? status) =>
      status == statusAmountTooLow || status == statusCompleted;

  static Future<File> _syncFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_syncFileName');
  }

  /// Persists an `AMOUNT_TOO_LOW` payload so the gate survives a cold start.
  /// Anything else is ignored, so callers can hand over a raw message.
  static Future<void> save(Map<String, dynamic> data) async {
    try {
      final flattened = flatten(data);
      if (flattened['status'] != statusAmountTooLow) {
        return;
      }
      final file = await _syncFile();
      await file.writeAsString(json.encode(flattened), flush: true);
      log('💾 [PAYMENT GATE] Saved AMOUNT_TOO_LOW state');
    } catch (e) {
      log('⚠️ [PAYMENT GATE] Failed to save state: $e');
    }
  }

  static Future<void> clear() async {
    try {
      final file = await _syncFile();
      if (await file.exists()) {
        await file.delete();
        log('🧹 [PAYMENT GATE] Cleared AMOUNT_TOO_LOW state');
      }
    } catch (e) {
      log('⚠️ [PAYMENT GATE] Failed to clear state: $e');
    }
  }

  /// The stored payload, or `null` when nothing is pending (or the file is
  /// unreadable — a corrupt file must not wedge the app behind the gate).
  static Future<Map<String, dynamic>?> readPending() async {
    try {
      final file = await _syncFile();
      if (!await file.exists()) {
        return null;
      }
      final content = await file.readAsString();
      if (content.isEmpty) {
        return null;
      }
      final decoded = json.decode(content);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      log('⚠️ [PAYMENT GATE] Failed to read pending state: $e');
      return null;
    }
  }
}
