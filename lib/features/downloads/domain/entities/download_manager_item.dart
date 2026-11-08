import '../../../../core/utils/machine_usb_path_mapper.dart';
import '../../data/models/download_file_model.dart';
import '../../data/models/downloaded_product_model.dart';

enum DownloadManagerStatus { downloaded, downloading, failed, notDownloaded }

class DownloadManagerItem {
  final int productId;
  final int fileId;
  final String productName;
  final String machineName;
  final String machineLogo;
  final String productCreatedAt;
  final String fileCreatedAt;
  final String image;
  final String price;
  final List<String> productImages;
  final List<String> savedFileNames;
  final String requestedAt;
  final DownloadManagerStatus status;
  final double progress;

  /// Reason a download ended in [DownloadManagerStatus.failed]. Either a
  /// translation key (e.g. `downloadFailedNetwork`) or raw text; empty for any
  /// non-failed item. Persisted so the failure survives an app restart.
  final String errorMessage;

  const DownloadManagerItem({
    required this.productId,
    required this.fileId,
    required this.productName,
    required this.machineName,
    required this.productCreatedAt,
    required this.fileCreatedAt,
    required this.image,
    required this.price,
    required this.productImages,
    required this.savedFileNames,
    required this.requestedAt,
    required this.status,
    required this.progress,
    this.machineLogo = '',
    this.errorMessage = '',
  });

  String get storageKey => '$productId:$fileId';

  String get relativePath => MachineUsbPathMapper.downloadRelativePath(
    machineName: machineName,
    productName: productName,
  );

  String get iosRelativePath => 'YAKA/$relativePath';

  String get normalizedMachineName =>
      machineName.trim().isEmpty ? 'YAKA' : machineName.trim();

  String get displayDate {
    if (status != DownloadManagerStatus.downloaded && requestedAt.isNotEmpty) {
      return requestedAt;
    }
    if (fileCreatedAt.isNotEmpty) {
      return fileCreatedAt;
    }
    return productCreatedAt;
  }

  DownloadManagerItem copyWith({
    List<String>? savedFileNames,
    String? requestedAt,
    DownloadManagerStatus? status,
    double? progress,
    String? errorMessage,
  }) {
    return DownloadManagerItem(
      productId: productId,
      fileId: fileId,
      productName: productName,
      machineName: machineName,
      machineLogo: machineLogo,
      productCreatedAt: productCreatedAt,
      fileCreatedAt: fileCreatedAt,
      image: image,
      price: price,
      productImages: productImages,
      savedFileNames: savedFileNames ?? this.savedFileNames,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory DownloadManagerItem.fromBackend({
    required DownloadedProductModel product,
    required DownloadFileModel file,
    Map<String, dynamic>? localState,
  }) {
    final images = (product.images ?? [])
        .where((image) => image != null)
        .map((image) => image.toString())
        .toList();
    final savedFileNames =
        (localState?['savedFileNames'] as List?)
            ?.whereType<String>()
            .toList() ??
        <String>[];
    final statusName = localState?['status']?.toString();
    final status = DownloadManagerStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => DownloadManagerStatus.notDownloaded,
    );

    return DownloadManagerItem(
      productId: product.id ?? 0,
      fileId: file.id ?? 0,
      productName: product.name ?? '',
      machineName: file.machineName ?? product.machineName ?? '',
      machineLogo: file.machineLogo ?? '',
      productCreatedAt: product.createdAt ?? '',
      fileCreatedAt: file.createdAt ?? product.createdAt ?? '',
      image: images.isNotEmpty ? images.first : '',
      price: (product.price ?? 0).toString(),
      productImages: images,
      savedFileNames: savedFileNames,
      requestedAt: localState?['requestedAt']?.toString() ?? '',
      status: status == DownloadManagerStatus.downloading
          ? DownloadManagerStatus.notDownloaded
          : status,
      progress: 0,
      errorMessage: status == DownloadManagerStatus.failed
          ? (localState?['errorMessage']?.toString() ?? '')
          : '',
    );
  }

  factory DownloadManagerItem.fromProductFile({
    required int productId,
    required String productName,
    required String image,
    required DownloadFileModel file,
  }) {
    return DownloadManagerItem(
      productId: productId,
      fileId: file.id ?? 0,
      productName: productName,
      machineName: file.machineName ?? '',
      machineLogo: file.machineLogo ?? '',
      productCreatedAt: '',
      fileCreatedAt: file.createdAt ?? '',
      image: image,
      price: (file.price ?? 0).toString(),
      productImages: image.isEmpty ? <String>[] : <String>[image],
      savedFileNames: const <String>[],
      requestedAt: '',
      status: DownloadManagerStatus.notDownloaded,
      progress: 0,
    );
  }

  factory DownloadManagerItem.fromCache(Map<String, dynamic> json) {
    final statusName = json['status']?.toString();
    final status = DownloadManagerStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => DownloadManagerStatus.notDownloaded,
    );

    return DownloadManagerItem(
      productId: json['productId'] is int
          ? json['productId'] as int
          : int.tryParse(json['productId']?.toString() ?? '') ?? 0,
      fileId: json['fileId'] is int
          ? json['fileId'] as int
          : int.tryParse(json['fileId']?.toString() ?? '') ?? 0,
      productName: json['productName']?.toString() ?? '',
      machineName: json['machineName']?.toString() ?? '',
      machineLogo: json['machineLogo']?.toString() ?? '',
      productCreatedAt: json['productCreatedAt']?.toString() ?? '',
      fileCreatedAt: json['fileCreatedAt']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      productImages:
          (json['productImages'] as List?)
              ?.map((image) => image.toString())
              .toList() ??
          <String>[],
      savedFileNames:
          (json['savedFileNames'] as List?)
              ?.map((name) => name.toString())
              .toList() ??
          <String>[],
      requestedAt: json['requestedAt']?.toString() ?? '',
      status: status == DownloadManagerStatus.downloading
          ? DownloadManagerStatus.notDownloaded
          : status,
      progress: 0,
      errorMessage: status == DownloadManagerStatus.failed
          ? (json['errorMessage']?.toString() ?? '')
          : '',
    );
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'productId': productId,
      'fileId': fileId,
      'productName': productName,
      'machineName': machineName,
      'machineLogo': machineLogo,
      'productCreatedAt': productCreatedAt,
      'fileCreatedAt': fileCreatedAt,
      'image': image,
      'price': price,
      'productImages': productImages,
      'savedFileNames': savedFileNames,
      'requestedAt': requestedAt,
      'status': status.name,
      'errorMessage': errorMessage,
    };
  }

  Map<String, dynamic> toLocalState() {
    return {
      'productId': productId,
      'fileId': fileId,
      'status': status.name,
      'savedFileNames': savedFileNames,
      'requestedAt': requestedAt,
      'errorMessage': errorMessage,
    };
  }
}
