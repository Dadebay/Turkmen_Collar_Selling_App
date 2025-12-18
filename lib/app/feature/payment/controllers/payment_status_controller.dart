import 'package:get/get.dart';
import 'package:yaka2/app/feature/payment/services/payment_status_service.dart';

class PaymentStatusController extends GetxController {
  final PaymentStatusService _service = PaymentStatusService();

  // Observable: true if payments should be disabled
  final RxBool isPaymentDisabled = false.obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    initializePaymentStatus();
  }

  /// Initialize payment status on app start
  Future<void> initializePaymentStatus() async {
    try {
      isLoading.value = true;
      print('🔵 [PAYMENT_CONTROLLER] Initializing payment status...');

      final status = await _service.fetchPaymentStatus();
      isPaymentDisabled.value = status;

      print('✅ [PAYMENT_CONTROLLER] Payment status initialized: disabled = $status');
    } catch (e) {
      print('❌ [PAYMENT_CONTROLLER] Error initializing payment status: $e');
      // On error, keep payments enabled (safe default)
      isPaymentDisabled.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh payment status from API
  Future<void> refreshPaymentStatus() async {
    try {
      print('🔄 [PAYMENT_CONTROLLER] Refreshing payment status...');

      final status = await _service.fetchPaymentStatus();
      isPaymentDisabled.value = status;

      print('✅ [PAYMENT_CONTROLLER] Payment status refreshed: disabled = $status');
    } catch (e) {
      print('❌ [PAYMENT_CONTROLLER] Error refreshing payment status: $e');
    }
  }

  /// Check if payments are enabled
  bool get isPaymentEnabled => !isPaymentDisabled.value;

  /// Clear cache (for testing)
  Future<void> clearCache() async {
    await _service.clearCache();
    await initializePaymentStatus();
  }
}
