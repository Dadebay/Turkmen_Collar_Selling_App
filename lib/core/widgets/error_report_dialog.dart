import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../features/ai_chat/data/datasources/chat_service.dart';
import '../constants/api_constants.dart';
import '../l10n/app_translations.dart';
import '../router/app_router.dart';
import '../storage/local_storage.dart';
import '../theme/app_palette.dart';
import '../theme/color_constants.dart';

class ErrorReportDialog extends StatefulWidget {
  const ErrorReportDialog({
    required this.title,
    required this.details,
    required this.screenshot,
    super.key,
  });

  final String title;
  final String details;
  final File? screenshot;

  @override
  State<ErrorReportDialog> createState() => _ErrorReportDialogState();
}

class _ErrorReportDialogState extends State<ErrorReportDialog> {
  bool _sending = false;
  String? _error;

  Future<void> _send() async {
    if (_sending) {
      return;
    }

    final storage = LocalStorage();
    final token = storage.token;
    final customerId = storage.customerId;
    if (token == null || token.isEmpty || customerId == null) {
      setState(() => _error = 'reportErrorSignInRequired'.tr);
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      String version;
      try {
        final package = await PackageInfo.fromPlatform();
        version = '${package.version}+${package.buildNumber}';
      } catch (_) {
        version = 'unknown';
      }
      final message = [
        'YAKA error report',
        'Version: $version',
        'Time: ${DateTime.now().toIso8601String()}',
        'Error: ${widget.title}',
        'Details: ${widget.details}',
      ].join('\n');
      final chat = ChatService(baseUrl: ApiConstants.baseUrl, token: token);
      final screenshot = widget.screenshot;
      final imageUrls = screenshot == null
          ? null
          : await chat.sendImages(imageFiles: [screenshot]);
      await chat.sendMessage(
        customerId: customerId,
        adminId: 1,
        message: message,
        senderType: 'customer',
        imageUrls: imageUrls,
      );
      if (!mounted) {
        return;
      }

      setState(() => _sending = false);
      final router = GoRouter.of(context);
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text('reportErrorSent'.tr)));
      unawaited(router.push<void>(AppRoutes.aiChat));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'reportErrorSendFailed'.tr);
      }
    } finally {
      if (mounted && _sending) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  void dispose() {
    final screenshot = widget.screenshot;
    if (screenshot != null) {
      unawaited(screenshot.delete().catchError((Object _) => screenshot));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return PopScope(
      canPop: !_sending,
      child: AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'reportErrorTitle'.tr,
          style: TextStyle(color: palette.text, fontWeight: FontWeight.w700),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'reportErrorDescription'.tr,
                  style: TextStyle(color: palette.muted),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorConstants.redColor.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.title}\n${widget.details}',
                    style: TextStyle(color: palette.text, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'reportErrorScreenshot'.tr,
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.screenshot case final screenshot?)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 240,
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: Image.file(screenshot, fit: BoxFit.contain),
                      ),
                    ),
                  )
                else
                  Text(
                    'reportErrorNoScreenshot'.tr,
                    style: TextStyle(color: palette.muted),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _sending ? null : () => Navigator.of(context).pop(),
            child: Text('close'.tr),
          ),
          FilledButton(
            onPressed: _sending ? null : _send,
            child: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('reportErrorSend'.tr),
          ),
        ],
      ),
    );
  }
}
