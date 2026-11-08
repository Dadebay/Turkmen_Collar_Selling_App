import Flutter
import UIKit
import UniformTypeIdentifiers

/// iOS counterpart of the Android `UsbStorageBridge`. It exposes the same
/// `com.example.usb_storage` MethodChannel surface the Dart USB-transfer flow
/// calls, backed by a user-picked folder (via `UIDocumentPickerViewController`)
/// which can be a connected USB drive / SD card in the Files app (iOS 13+).
///
/// Access to that folder is persisted with a security-scoped bookmark — the
/// iOS analogue of Android's persisted SAF tree URI — so the drive only has to
/// be picked once. Files are copied with `FileManager`, preserving the
/// `machine/version/...` folder hierarchy, unlike a flat share sheet.
final class UsbStorageBridge: NSObject {
  private let bookmarkKey = "usb_folder_bookmark"
  private let fixedSourceRoot = "YAKA"

  private weak var controller: UIViewController?
  private var pendingResult: FlutterResult?

  init(channel: FlutterMethodChannel, controller: UIViewController?) {
    self.controller = controller
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestUsbFolderAccess", "pickSAFDirectory":
      requestUsbFolderAccess(result)
    case "hasUsbFolderAccess":
      result(resolveFolderURL() != nil)
    case "hasSourceFolderAccess":
      result(true)
    case "getUsbFolderName":
      result(usbFolderName())
    case "getUSBPath", "refreshUSB":
      // iOS has no USB mount path; folder access alone drives the UI status.
      result(nil)
    case "clearUsbFolderAccess", "clearSourceFolderAccess":
      UserDefaults.standard.removeObject(forKey: bookmarkKey)
      result(nil)
    case "openSourceFolder", "openDownloadsFolder":
      openSourceFolder(result)
    case "listSourceFiles":
      DispatchQueue.global(qos: .userInitiated).async {
        let files = self.listSourceFiles()
        DispatchQueue.main.async { result(files) }
      }
    case "copyDocumentToUsb":
      guard let args = call.arguments as? [String: Any],
            let documentUri = args["documentUri"] as? String,
            let fileName = args["fileName"] as? String, !fileName.isEmpty
      else {
        result(FlutterError(
          code: "invalid_arguments",
          message: "documentUri and fileName are required", details: nil))
        return
      }
      let relativePath = (args["relativePath"] as? String) ?? ""
      let expectedSize = (args["expectedSize"] as? NSNumber)?.int64Value ?? -1
      DispatchQueue.global(qos: .userInitiated).async {
        self.copyDocumentToUsb(
          documentUri: documentUri, relativePath: relativePath,
          fileName: fileName, expectedSize: expectedSize, result: result)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Folder selection

  private func requestUsbFolderAccess(_ result: @escaping FlutterResult) {
    if pendingResult != nil {
      result(FlutterError(
        code: "request_in_progress",
        message: "USB folder selection is already open", details: nil))
      return
    }
    guard let controller = controller else {
      result(FlutterError(
        code: "no_view_controller",
        message: "No view controller available to present the picker",
        details: nil))
      return
    }
    pendingResult = result
    let picker = UIDocumentPickerViewController(
      forOpeningContentTypes: [UTType.folder], asCopy: false)
    picker.delegate = self
    picker.allowsMultipleSelection = false
    controller.present(picker, animated: true)
  }

  private func finishPicker(with value: Any?) {
    let pending = pendingResult
    pendingResult = nil
    DispatchQueue.main.async { pending?(value) }
  }

  // MARK: - Bookmark helpers

  private func resolveFolderURL() -> URL? {
    guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else {
      return nil
    }
    var stale = false
    guard let url = try? URL(
      resolvingBookmarkData: data, options: [], relativeTo: nil,
      bookmarkDataIsStale: &stale) else {
      return nil
    }
    return url
  }

  private func usbFolderName() -> String? {
    return resolveFolderURL()?.lastPathComponent
  }

  // MARK: - Source files (app Documents/YAKA)

  private func sourceRootURL() -> URL {
    let docs = FileManager.default.urls(
      for: .documentDirectory, in: .userDomainMask)[0]
    return docs.appendingPathComponent(fixedSourceRoot, isDirectory: true)
  }

  private func listSourceFiles() -> [[String: Any?]] {
    let root = sourceRootURL()
    let fm = FileManager.default
    guard fm.fileExists(atPath: root.path),
          let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey])
    else {
      return []
    }

    var files: [[String: Any?]] = []
    for case let fileURL as URL in enumerator {
      let values = try? fileURL.resourceValues(
        forKeys: [.isRegularFileKey, .fileSizeKey])
      guard values?.isRegularFile == true else { continue }
      // Folder path relative to the YAKA root (filename excluded).
      let relativeDir = fileURL.deletingLastPathComponent().path
        .replacingOccurrences(of: root.path, with: "")
        .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
      files.append([
        "uri": fileURL.path,
        "name": fileURL.lastPathComponent,
        "relativePath": relativeDir,
        "size": values?.fileSize,
      ])
    }
    return files
  }

  // MARK: - Copy to USB

  private func copyDocumentToUsb(
    documentUri: String, relativePath: String, fileName: String,
    expectedSize: Int64, result: @escaping FlutterResult
  ) {
    guard let folderURL = resolveFolderURL() else {
      DispatchQueue.main.async {
        result(FlutterError(
          code: "usb_permission_missing",
          message: "Select a USB folder before saving files", details: nil))
      }
      return
    }

    let accessed = folderURL.startAccessingSecurityScopedResource()
    defer { if accessed { folderURL.stopAccessingSecurityScopedResource() } }

    let fm = FileManager.default
    do {
      var targetDir = folderURL
      for segment in sanitizeRelativePath(relativePath) {
        targetDir = targetDir.appendingPathComponent(segment, isDirectory: true)
      }
      try fm.createDirectory(at: targetDir, withIntermediateDirectories: true)

      let targetFile = targetDir.appendingPathComponent(
        sanitizeSegment(fileName))

      // Skip re-copying a file already on the USB with the same size —
      // makes re-transferring a collar near-instant.
      if expectedSize > 0, fm.fileExists(atPath: targetFile.path) {
        let attrs = try? fm.attributesOfItem(atPath: targetFile.path)
        if let size = attrs?[.size] as? NSNumber,
           size.int64Value == expectedSize {
          DispatchQueue.main.async { result("skipped") }
          return
        }
      }

      let sourceURL = URL(fileURLWithPath: documentUri)
      if fm.fileExists(atPath: targetFile.path) {
        try fm.removeItem(at: targetFile)
      }
      try fm.copyItem(at: sourceURL, to: targetFile)
      DispatchQueue.main.async { result(targetFile.path) }
    } catch {
      DispatchQueue.main.async {
        result(FlutterError(
          code: "usb_write_failed", message: error.localizedDescription,
          details: nil))
      }
    }
  }

  // MARK: - Open Files app at the app's Documents folder

  private func openSourceFolder(_ result: @escaping FlutterResult) {
    let docs = FileManager.default.urls(
      for: .documentDirectory, in: .userDomainMask)[0]
    var components = URLComponents(url: docs, resolvingAgainstBaseURL: false)
    components?.scheme = "shareddocuments"
    guard let url = components?.url else {
      result(false)
      return
    }
    DispatchQueue.main.async {
      UIApplication.shared.open(url, options: [:]) { opened in
        result(opened)
      }
    }
  }

  // MARK: - Sanitizing

  private func sanitizeRelativePath(_ path: String) -> [String] {
    return path.split(separator: "/")
      .map { sanitizeSegment(String($0)) }
      .filter { !$0.isEmpty }
  }

  private func sanitizeSegment(_ value: String) -> String {
    let invalid = CharacterSet(charactersIn: "\\/:*?\"<>|")
    let cleaned = value.components(separatedBy: invalid)
      .joined(separator: "_")
      .trimmingCharacters(in: .whitespaces)
    return cleaned.isEmpty ? fixedSourceRoot : cleaned
  }
}

// MARK: - UIDocumentPickerDelegate

extension UsbStorageBridge: UIDocumentPickerDelegate {
  func documentPicker(
    _ controller: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    guard let url = urls.first else {
      finishPicker(with: FlutterError(
        code: "folder_cancelled", message: "No folder selected", details: nil))
      return
    }
    let accessed = url.startAccessingSecurityScopedResource()
    defer { if accessed { url.stopAccessingSecurityScopedResource() } }
    do {
      let data = try url.bookmarkData(
        options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
      UserDefaults.standard.set(data, forKey: bookmarkKey)
      finishPicker(with: url.lastPathComponent)
    } catch {
      finishPicker(with: FlutterError(
        code: "folder_permission_failed",
        message: error.localizedDescription, details: nil))
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    finishPicker(with: FlutterError(
      code: "folder_cancelled", message: "Folder selection was cancelled",
      details: nil))
  }
}
