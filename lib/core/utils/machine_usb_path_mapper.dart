class MachineUsbPathMapper {
  static const Map<String, String> pathsByMachine = {
    'DST 20X28 MASYNLAR UCIN': '',
    '15 INNE UCIN': '',
    'JANOME MB4-MB4S': 'emb',
    'JANOME 450E-500E': 'emb',
    'JANOME 350E-370E': 'embf5',
    'JANOME 200E-230E': 'emb',
    'BROTHER V3': '',
    'BERNETTA 340': 'embf5',
  };

  static String downloadRelativePath({
    required String machineName,
    required String productName,
  }) {
    final productPath = _cleanPathSegment(productName);
    final usbRoot = folderForMachine(machineName);

    if (usbRoot == null || usbRoot.isEmpty) {
      return productPath;
    }
    return '$usbRoot/$productPath';
  }

  static String usbRelativePath({
    required String machineName,
    required String productName,
  }) {
    return downloadRelativePath(
      machineName: machineName,
      productName: productName,
    );
  }

  static String? folderForMachine(String machineName) {
    return pathsByMachine[_normalize(machineName)];
  }

  static String _normalize(String value) {
    return value
        .toUpperCase()
        .replaceAll('Ş', 'S')
        .replaceAll('Ň', 'N')
        .replaceAll('Ü', 'U')
        .replaceAll('Ç', 'C')
        .replaceAll('Ý', 'Y')
        .replaceAll('Ä', 'A')
        .replaceAll('Ö', 'O')
        .replaceAll('İ', 'I')
        .replaceAll('Åž', 'S')
        .replaceAll('Å‡', 'N')
        .replaceAll('Ãœ', 'U')
        .replaceAll('Ã‡', 'C')
        .replaceAll('Ã', 'Y')
        .replaceAll('Ã„', 'A')
        .replaceAll('Ã–', 'O')
        .replaceAll('Ä°', 'I')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _cleanPathSegment(String value) {
    final cleaned = value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return cleaned.isEmpty ? 'YAKA' : cleaned;
  }
}
