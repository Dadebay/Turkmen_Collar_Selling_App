// ignore_for_file: always_put_control_body_on_new_line

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sms_autofill/sms_autofill.dart';

/// Permission-free SMS OTP retriever built on Google's **SMS Retriever API**.
/// https://developers.google.com/identity/sms-retriever/verify
///
/// No SMS permissions (`READ_SMS`/`RECEIVE_SMS`) are requested or required —
/// Google Play services hands the app the matching message directly.
///
/// For silent SMS Retriever delivery, the OTP SMS **must** follow Google's
/// format:
///  * be no longer than 140 bytes,
///  * contain the one-time code the client sends back,
///  * end with an 11-character app hash obtained from [getAppSignature].
///
/// Messages without the hash can use SMS User Consent on Android, which shows
/// a one-time approval prompt.
///
/// Example message the backend should send:
/// ```
/// <#> Your Yaka code is 12345
/// FA+9qCX9VSu
/// ```
///
/// The trailing `FA+9qCX9VSu` is this app's hash — call [getAppSignature] once
/// (it is stable per signing key + package) and give the value to the backend.
class SmsOtpService {
  SmsOtpService({SmsAutoFill? autoFill})
    : _autoFill = autoFill ?? SmsAutoFill() {
    _consentChannel.setMethodCallHandler((call) async {
      if (call.method == 'smsMessage' && call.arguments is String) {
        _captureCode(call.arguments as String, source: 'user_consent');
      } else if (call.method == 'diagnostic' && call.arguments is String) {
        _log('android: ${call.arguments}');
      }
    });
  }

  static void _log(String message) {
    if (kDebugMode) debugPrint('[SMS OTP] $message');
  }

  static const _consentChannel = MethodChannel('com.gurbanov.yaka/sms_consent');
  final SmsAutoFill _autoFill;
  final ValueNotifier<String?> _latestCode = ValueNotifier(null);
  StreamSubscription<String>? _subscription;
  void Function(String code)? _onCode;
  int _codeLength = 5;
  bool _listening = false;

  ValueListenable<String?> get latestCode => _latestCode;
  bool get isListening => _listening;

  /// Extracts the first run of exactly [length] digits from [text], ignoring
  /// longer digit sequences. The retriever hands back the whole matched SMS, so
  /// this pulls the bare code out of it.
  static String? extractCode(String text, {int length = 5}) {
    final match = RegExp('(?<!\\d)\\d{$length}(?!\\d)').firstMatch(text);
    if (match != null) return match.group(0);
    // Fallback: some senders emit just the digits with no surrounding text.
    final trimmed = text.trim();
    if (trimmed.length == length && RegExp(r'^\d+$').hasMatch(trimmed)) {
      return trimmed;
    }
    return null;
  }

  /// The 11-character app hash the backend must append to every OTP SMS.
  /// Returns an empty string on non-Android platforms.
  Future<String> getAppSignature() => _autoFill.getAppSignature;

  /// Starts listening for the OTP SMS and calls [onCode] with the extracted
  /// code when it arrives. Any previous listener is cancelled first.
  Future<void> startListening({
    void Function(String code)? onCode,
    int length = 5,
  }) async {
    _log('start requested; expectedDigits=$length');
    await stopListening();
    _listening = true;
    _codeLength = length;
    _onCode = onCode;
    _latestCode.value = null;
    _subscription = _autoFill.code.listen(
      (raw) => _captureCode(raw, source: 'retriever'),
      onError: (Object error) =>
          _log('retriever stream error: ${error.runtimeType}'),
    );
    // Start before POST /login: an SMS can arrive before the OTP route opens.
    await Future.wait([_startRetriever(length), _startConsent()]);
    _log('listeners ready; active=$_listening');
  }

  void _captureCode(String raw, {required String source}) {
    _log('$source message delivered; active=$_listening');
    if (!_listening) return;
    final code = extractCode(raw, length: _codeLength);
    if (code == null) {
      _log('$source message has no exact $_codeLength-digit code');
      return;
    }
    if (code == _latestCode.value) {
      _log('$source code already received');
      return;
    }
    _log('$source code extracted; notifying OTP screen');
    _latestCode.value = code;
    _onCode?.call(code);
    unawaited(_stopConsent());
  }

  Future<void> _startRetriever(int length) async {
    try {
      await _autoFill.listenForCode(smsCodeRegexPattern: '\\d{$length}');
      _log('retriever started');
    } catch (error) {
      _log('retriever start failed: ${error.runtimeType}');
      // The field remains usable if Google Play services is unavailable.
    }
  }

  Future<void> _startConsent() async {
    try {
      await _consentChannel.invokeMethod<void>('start');
      _log('user consent started');
    } catch (error) {
      _log('user consent start failed: ${error.runtimeType}');
      // SMS Retriever and manual entry still work without User Consent.
    }
  }

  Future<void> _stopConsent() async {
    try {
      await _consentChannel.invokeMethod<void>('stop');
    } catch (_) {
      // The native channel does not exist on iOS.
    }
  }

  /// Stops listening and releases the retriever registration. Safe to call
  /// multiple times.
  Future<void> stopListening() async {
    _log('stop requested; wasActive=$_listening');
    _listening = false;
    _onCode = null;
    await _subscription?.cancel();
    _subscription = null;
    _latestCode.value = null;
    try {
      await _autoFill.unregisterListener();
    } catch (_) {
      // The retriever may not have started on this platform.
    }
    await _stopConsent();
    _log('listeners stopped');
  }

  /// One-shot helper: resolves with the code as soon as it arrives, or `null`
  /// after [timeout]. Registers and tears down its own listener.
  Future<String?> waitForOtp({
    int length = 5,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final completer = Completer<String?>();
    await startListening(
      onCode: (code) {
        if (!completer.isCompleted) completer.complete(code);
      },
      length: length,
    );
    final timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) completer.complete(null);
    });
    try {
      return await completer.future;
    } finally {
      timeoutTimer.cancel();
      await stopListening();
    }
  }

  /// Logs the app hash in debug builds so it can be configured on the backend.
  Future<void> debugPrintAppSignature() async {
    if (!kDebugMode) return;
    final signature = await getAppSignature();
    debugPrint(
      '[SmsOtpService] SMS Retriever app hash: "$signature" — '
      'the OTP SMS must end with this 11-char string.',
    );
  }
}
