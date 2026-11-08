// ignore_for_file: always_put_control_body_on_new_line
part of 'usb_transfer_bloc.dart';

class UsbTransferState {
  const UsbTransferState({
    this.loading = true,
    this.androidOnly = false,
    this.items = const <DownloadManagerItem>[],
    this.localFilesByPath = const <String, List<LocalDownloadFile>>{},
    this.availableVersions = const <int, List<String>>{},
    this.selectedVersions = const <int, Set<String>>{},
    this.usbConnected = false,
    this.usbFolderSelected = false,
    this.usbFolderName,
    this.activeProductId,
    this.isTransferring = false,
    this.copiedFiles = 0,
    this.skippedFiles = 0,
    this.failedFiles = 0,
    this.totalTransferItems = 0,
    this.processedTransferItems = 0,
    this.transferComplete = false,
    this.errorMessage,
    this.successMessage,
  });

  final bool loading;
  final bool androidOnly;
  final List<DownloadManagerItem> items;
  final Map<String, List<LocalDownloadFile>> localFilesByPath;
  final Map<int, List<String>> availableVersions;
  final Map<int, Set<String>> selectedVersions;
  final bool usbConnected;
  final bool usbFolderSelected;
  final String? usbFolderName;
  final int? activeProductId;
  final bool isTransferring;
  final int copiedFiles;
  final int skippedFiles;
  final int failedFiles;
  final int totalTransferItems;
  final int processedTransferItems;
  final bool transferComplete;
  final String? errorMessage;
  final String? successMessage;

  bool get hasUsbAccess => usbConnected && usbFolderSelected;

  /// Distinct products that have at least one downloaded item; matches the
  /// "downloaded collars" grid in the old view.
  List<UsbProductSummary> get products {
    final byId = <int, UsbProductSummary>{};
    for (final item in items) {
      byId.putIfAbsent(
        item.productId,
        () => UsbProductSummary(
          id: item.productId,
          name: item.productName,
          image: item.image,
        ),
      );
    }
    return byId.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  UsbProductSummary? productById(int id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  int totalSelectedMachineCount() {
    return selectedVersions.values.fold<int>(0, (sum, set) => sum + set.length);
  }

  UsbTransferState copyWith({
    bool? loading,
    bool? androidOnly,
    List<DownloadManagerItem>? items,
    Map<String, List<LocalDownloadFile>>? localFilesByPath,
    Map<int, List<String>>? availableVersions,
    Map<int, Set<String>>? selectedVersions,
    bool? usbConnected,
    bool? usbFolderSelected,
    String? usbFolderName,
    int? activeProductId,
    bool? isTransferring,
    int? copiedFiles,
    int? skippedFiles,
    int? failedFiles,
    int? totalTransferItems,
    int? processedTransferItems,
    bool? transferComplete,
    String? errorMessage,
    String? successMessage,
  }) {
    return UsbTransferState(
      loading: loading ?? this.loading,
      androidOnly: androidOnly ?? this.androidOnly,
      items: items ?? this.items,
      localFilesByPath: localFilesByPath ?? this.localFilesByPath,
      availableVersions: availableVersions ?? this.availableVersions,
      selectedVersions: selectedVersions ?? this.selectedVersions,
      usbConnected: usbConnected ?? this.usbConnected,
      usbFolderSelected: usbFolderSelected ?? this.usbFolderSelected,
      usbFolderName: usbFolderName ?? this.usbFolderName,
      activeProductId: activeProductId ?? this.activeProductId,
      isTransferring: isTransferring ?? this.isTransferring,
      copiedFiles: copiedFiles ?? this.copiedFiles,
      skippedFiles: skippedFiles ?? this.skippedFiles,
      failedFiles: failedFiles ?? this.failedFiles,
      totalTransferItems: totalTransferItems ?? this.totalTransferItems,
      processedTransferItems:
          processedTransferItems ?? this.processedTransferItems,
      transferComplete: transferComplete ?? this.transferComplete,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  UsbTransferState clearActiveProduct() {
    return UsbTransferState(
      loading: loading,
      androidOnly: androidOnly,
      items: items,
      localFilesByPath: localFilesByPath,
      availableVersions: availableVersions,
      selectedVersions: selectedVersions,
      usbConnected: usbConnected,
      usbFolderSelected: usbFolderSelected,
      usbFolderName: usbFolderName,
      isTransferring: isTransferring,
      copiedFiles: copiedFiles,
      skippedFiles: skippedFiles,
      failedFiles: failedFiles,
      totalTransferItems: totalTransferItems,
      processedTransferItems: processedTransferItems,
      transferComplete: transferComplete,
    );
  }
}

class UsbProductSummary {
  const UsbProductSummary({
    required this.id,
    required this.name,
    required this.image,
  });

  final int id;
  final String name;
  final String image;
}
