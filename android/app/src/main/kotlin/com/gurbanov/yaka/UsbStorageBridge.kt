package com.gurbanov.yaka

import android.Manifest
import android.app.Activity
import android.app.DownloadManager
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.storage.StorageManager
import android.provider.DocumentsContract
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.documentfile.provider.DocumentFile
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.OutputStream
import java.util.concurrent.Executors

class UsbStorageBridge(private val activity: Activity) {
    private val pickDirRequestCode = 1234
    private val usbTreeRequestCode = 4102
    private val sourceTreeRequestCode = 4103
    private val storagePermissionRequestCode = 4104
    private val prefsName = "usb_storage"
    private val usbTreeUriKey = "usb_tree_uri"
    private val sourceTreeUriKey = "source_tree_uri"
    private val fixedSourceRoot = "YAKA"

    private var pendingPickDirResult: MethodChannel.Result? = null
    private var pendingUsbFolderResult: MethodChannel.Result? = null
    private var pendingSourceFolderResult: MethodChannel.Result? = null
    private var pendingStoragePermissionResult: MethodChannel.Result? = null

    // Heavy binder/IO work must not run on the platform (main) thread, or the
    // slow synchronous calls (SAF queries, file copies) trigger "slow binder
    // call" ANRs. A single worker serializes file operations; results are
    // marshaled back to the main thread, as MethodChannel.Result requires.
    private val ioExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    /** Posts every MethodChannel.Result callback back onto the main thread. */
    private inner class MainThreadResult(
        private val delegate: MethodChannel.Result
    ) : MethodChannel.Result {
        override fun success(value: Any?) = mainHandler.post { delegate.success(value) }.let { }
        override fun error(code: String, message: String?, details: Any?) =
            mainHandler.post { delegate.error(code, message, details) }.let { }
        override fun notImplemented() = mainHandler.post { delegate.notImplemented() }.let { }
    }

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // UI-thread bound: start activities / trivial work — keep on main.
            "pickSAFDirectory" -> pickSafDirectory(result)
            "requestUsbFolderAccess" -> requestUsbFolderAccess(result)
            "requestSourceFolderAccess" -> requestSourceFolderAccess(result)
            "hasSourceFolderAccess" -> result.success(hasSourceFolderAccess())
            "openSourceFolder" -> openSourceFolder(result)
            "openDownloadsFolder" -> openDownloadsFolder(result)
            // Everything else does blocking binder/IO — run off the main thread.
            else -> {
                val safeResult = MainThreadResult(result)
                ioExecutor.execute {
                    try {
                        handleOnWorker(call, safeResult)
                    } catch (error: Exception) {
                        safeResult.error("bridge_error", error.message, null)
                    }
                }
            }
        }
    }

    private fun handleOnWorker(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getUSBPath", "refreshUSB" -> result.success(detectUsbPath())
            "checkSavedSafUri" -> result.success(checkSavedSafUri(call.argument("uri")))
            "existsSAF" -> result.success(
                existsSaf(
                    uriString = call.argument("uri"),
                    relativePath = call.argument("relativePath")
                )
            )
            "isWritableSAF" -> result.success(isWritableSaf(call.argument("uri")))
            "writeFileToSAF" -> {
                val uriString = call.argument<String>("uri")
                val fileName = call.argument<String>("fileName")
                val bytes = call.argument<ByteArray>("bytes")
                if (uriString == null || fileName == null || bytes == null) {
                    result.error("invalid_arguments", "Missing arguments for writeFileToSAF", null)
                } else {
                    result.success(writeFileToSaf(uriString, fileName, bytes))
                }
            }
            "copyFileToSAF" -> {
                val sourcePath = call.argument<String>("sourcePath")
                val treeUri = call.argument<String>("treeUri")
                val relativePath = call.argument<String>("relativePath")
                if (sourcePath == null || treeUri == null || relativePath == null) {
                    result.error("invalid_arguments", "Missing arguments for copyFileToSAF", null)
                } else {
                    result.success(copyFileToSaf(sourcePath, treeUri, relativePath))
                }
            }
            "listFilesInDir" -> result.success(listFilesViaMediaStore(call.argument("dirPath")))
            "hasUsbFolderAccess" -> result.success(getPersistedUsbTreeUri() != null)
            "getUsbFolderName" -> result.success(getUsbFolderDisplay())
            "listSourceFiles" -> listSourceFiles(result)
            "clearSourceFiles" -> result.success(clearSourceFiles())
            "clearUsbFolderAccess" -> {
                clearUsbFolderAccess()
                result.success(null)
            }
            "clearSourceFolderAccess" -> {
                clearSourceFolderAccess()
                result.success(null)
            }
            "copyFileToUsb" -> {
                val filePath = call.argument<String>("filePath")
                val relativePath = call.argument<String>("relativePath").orEmpty()
                val fileName = call.argument<String>("fileName")
                if (filePath.isNullOrBlank() || fileName.isNullOrBlank()) {
                    result.error("invalid_arguments", "filePath and fileName are required", null)
                } else {
                    copyFileToUsb(filePath, relativePath, fileName, result)
                }
            }
            "copyFileToSource" -> {
                val filePath = call.argument<String>("filePath")
                val relativePath = call.argument<String>("relativePath").orEmpty()
                val fileName = call.argument<String>("fileName")
                if (filePath.isNullOrBlank() || fileName.isNullOrBlank()) {
                    result.error("invalid_arguments", "filePath and fileName are required", null)
                } else {
                    copyFileToSource(filePath, relativePath, fileName, result)
                }
            }
            "copyDocumentToUsb" -> {
                val documentUri = call.argument<String>("documentUri")
                val relativePath = call.argument<String>("relativePath").orEmpty()
                val fileName = call.argument<String>("fileName")
                val expectedSize = call.argument<Number>("expectedSize")?.toLong() ?: -1L
                if (documentUri.isNullOrBlank() || fileName.isNullOrBlank()) {
                    result.error("invalid_arguments", "documentUri and fileName are required", null)
                } else {
                    copyDocumentToUsb(documentUri, relativePath, fileName, expectedSize, result)
                }
            }
            else -> result.notImplemented()
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        return when (requestCode) {
            pickDirRequestCode -> {
                handleTreeSelection(
                    result = pendingPickDirResult,
                    resultCode = resultCode,
                    data = data,
                    preferenceKey = usbTreeUriKey,
                    requireUsb = true
                )
                pendingPickDirResult = null
                true
            }
            usbTreeRequestCode -> {
                handleTreeSelection(
                    result = pendingUsbFolderResult,
                    resultCode = resultCode,
                    data = data,
                    preferenceKey = usbTreeUriKey,
                    requireUsb = true
                )
                pendingUsbFolderResult = null
                true
            }
            sourceTreeRequestCode -> {
                handleTreeSelection(
                    result = pendingSourceFolderResult,
                    resultCode = resultCode,
                    data = data,
                    preferenceKey = sourceTreeUriKey,
                    requireUsb = false
                )
                pendingSourceFolderResult = null
                true
            }
            else -> false
        }
    }

    fun detectUsbPath(): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            return detectUsbPathFromExternalFilesDirs()
        }

        val storageManager = activity.getSystemService(Context.STORAGE_SERVICE) as StorageManager
        for (volume in storageManager.storageVolumes) {
            if (volume.isRemovable) {
                val file = volume.directory
                if (file != null && file.exists()) {
                    return file.absolutePath
                }
            }
        }

        return detectUsbPathFromExternalFilesDirs()
    }

    private fun detectUsbPathFromExternalFilesDirs(): String? {
        val internalPath = activity.getExternalFilesDir(null)?.absolutePath

        try {
            for (dir in ContextCompat.getExternalFilesDirs(activity, null)) {
                val path = dir?.absolutePath ?: continue
                if (path == internalPath || !path.contains("/storage/") || path.contains("/emulated/")) {
                    continue
                }

                val rootPath = path.substringBefore("/Android/data")
                if (rootPath.isNotBlank() && isMounted(dir)) {
                    return rootPath
                }
            }
        } catch (_: Exception) {
        }

        return null
    }

    private fun isMounted(directory: File): Boolean {
        return Environment.MEDIA_MOUNTED == Environment.getExternalStorageState(directory)
    }

    /**
     * A user-readable label for the currently selected USB folder, e.g.
     * "USB drive/MyCollars". Derived from the persisted tree URI: the document
     * id encodes "<volumeId>:<subPath>", and the volume id is mapped to the
     * OS-provided volume description when available. Returns null when no USB
     * folder is selected.
     */
    private fun getUsbFolderDisplay(): String? {
        val treeUri = getPersistedUsbTreeUri() ?: return null
        return try {
            val docId = DocumentsContract.getTreeDocumentId(treeUri)
            val parts = docId.split(":", limit = 2)
            val volumeId = parts.getOrNull(0).orEmpty()
            val subPath = parts.getOrNull(1).orEmpty().trim('/')
            val volumeLabel = usbVolumeLabel(volumeId) ?: volumeId
            if (subPath.isBlank()) volumeLabel else "$volumeLabel/$subPath"
        } catch (_: Exception) {
            null
        }
    }

    private fun usbVolumeLabel(volumeId: String): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N || volumeId.isBlank()) {
            return null
        }
        val storageManager = activity.getSystemService(Context.STORAGE_SERVICE) as StorageManager
        return storageManager.storageVolumes
            .firstOrNull { it.uuid?.equals(volumeId, ignoreCase = true) == true }
            ?.getDescription(activity)
            ?.takeIf { it.isNotBlank() }
    }

    private fun pickSafDirectory(result: MethodChannel.Result) {
        if (pendingPickDirResult != null) {
            result.error("request_in_progress", "Folder selection is already open", null)
            return
        }

        pendingPickDirResult = result
        activity.startActivityForResult(treeIntent(), pickDirRequestCode)
    }

    private fun requestUsbFolderAccess(result: MethodChannel.Result) {
        if (pendingUsbFolderResult != null) {
            result.error("request_in_progress", "USB folder selection is already open", null)
            return
        }

        pendingUsbFolderResult = result
        activity.startActivityForResult(treeIntent(), usbTreeRequestCode)
    }

    /**
     * Whether the app may write into `Download/YAKA` right now. On Android 10+
     * it always may: files go in as its own MediaStore Downloads rows, which
     * needs no permission. Below Q the bridge writes raw files into public
     * external storage, so the WRITE_EXTERNAL_STORAGE runtime grant (API 23-28)
     * must already be held.
     */
    private fun hasSourceFolderAccess(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            return true
        }
        return ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.WRITE_EXTERNAL_STORAGE
        ) == PackageManager.PERMISSION_GRANTED
    }

    /**
     * Prepares `Download/YAKA` for writing, asking for the storage permission
     * first when the device needs one and has not granted it yet. Answers with
     * the folder path on success, or an error the Dart side turns into a
     * "permission needed" / "enable it in Settings" message.
     */
    private fun requestSourceFolderAccess(result: MethodChannel.Result) {
        if (hasSourceFolderAccess()) {
            ensureFixedSourceDirectory()
            result.success(fixedSourceDirectory().absolutePath)
            return
        }

        if (pendingStoragePermissionResult != null) {
            result.error(
                "request_in_progress",
                "A storage permission request is already open",
                null
            )
            return
        }

        pendingStoragePermissionResult = result
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
            storagePermissionRequestCode
        )
    }

    /**
     * Delivers the outcome of the storage permission prompt started by
     * [requestSourceFolderAccess]. Returns true when this bridge owned the
     * request, so the host activity can stop forwarding it.
     */
    fun onRequestPermissionsResult(
        requestCode: Int,
        grantResults: IntArray
    ): Boolean {
        if (requestCode != storagePermissionRequestCode) {
            return false
        }

        val result = pendingStoragePermissionResult ?: return true
        pendingStoragePermissionResult = null

        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            ensureFixedSourceDirectory()
            result.success(fixedSourceDirectory().absolutePath)
            return true
        }

        // Once the system stops offering a rationale the dialog will never show
        // again ("Don't ask again" / policy block), so only App info can undo it.
        val permanentlyDenied = !ActivityCompat.shouldShowRequestPermissionRationale(
            activity,
            Manifest.permission.WRITE_EXTERNAL_STORAGE
        )
        result.error(
            if (permanentlyDenied) {
                "storage_permission_permanently_denied"
            } else {
                "storage_permission_denied"
            },
            "Storage permission is required to save downloads",
            null
        )
        return true
    }

    private fun treeIntent(): Intent {
        return Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PREFIX_URI_PERMISSION
            )
        }
    }

    private fun handleTreeSelection(
        result: MethodChannel.Result?,
        resultCode: Int,
        data: Intent?,
        preferenceKey: String,
        requireUsb: Boolean
    ) {
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result?.error("folder_cancelled", "Folder selection was cancelled", null)
            return
        }

        val treeUri = data.data!!
        if (requireUsb && !isUsbTreeUri(treeUri)) {
            result?.error("usb_folder_not_removable", "Select a folder on the connected USB storage", null)
            return
        }

        try {
            val flags = data.flags and (
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                )
            activity.contentResolver.takePersistableUriPermission(treeUri, flags)
            activity.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
                .edit()
                .putString(preferenceKey, treeUri.toString())
                .apply()
            result?.success(treeUri.toString())
        } catch (error: SecurityException) {
            result?.error("folder_permission_failed", error.message, null)
        }
    }

    private fun checkSavedSafUri(uriString: String?): Boolean {
        if (uriString == null) {
            return false
        }

        return try {
            val uri = Uri.parse(uriString)
            val hasPermission = activity.contentResolver.persistedUriPermissions.any {
                it.uri == uri && it.isReadPermission && it.isWritePermission
            }
            if (!hasPermission) {
                return false
            }

            val doc = DocumentFile.fromTreeUri(activity, uri)
            doc != null && doc.exists() && doc.canWrite()
        } catch (_: Exception) {
            false
        }
    }

    private fun existsSaf(uriString: String?, relativePath: String?): Boolean {
        if (uriString == null || relativePath == null) {
            return false
        }

        val rootDoc = DocumentFile.fromTreeUri(activity, Uri.parse(uriString)) ?: return false
        val target = findDocument(rootDoc, relativePath)
        return target != null && target.exists()
    }

    private fun isWritableSaf(uriString: String?): Boolean {
        if (uriString == null) {
            return false
        }

        val doc = DocumentFile.fromTreeUri(activity, Uri.parse(uriString))
        return doc?.canWrite() ?: false
    }

    private fun listFilesViaMediaStore(dirPath: String?): List<String> {
        if (dirPath.isNullOrBlank()) {
            return emptyList()
        }

        val results = mutableListOf<String>()
        val normalizedPath = if (dirPath.endsWith("/")) dirPath else "$dirPath/"
        val uri = MediaStore.Files.getContentUri("external")
        val projection = arrayOf(MediaStore.MediaColumns.DATA)
        val selection = "${MediaStore.MediaColumns.DATA} LIKE ?"
        val selectionArgs = arrayOf("$normalizedPath%")

        try {
            activity.contentResolver.query(uri, projection, selection, selectionArgs, null)?.use { cursor ->
                val col = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)
                while (cursor.moveToNext()) {
                    val filePath = cursor.getString(col)
                    if (filePath != null && !filePath.endsWith("/")) {
                        results.add(filePath)
                    }
                }
            }
        } catch (_: Exception) {
        }

        if (results.isEmpty()) {
            val dir = File(dirPath)
            if (dir.exists()) {
                dir.walkTopDown().filter { it.isFile }.forEach { results.add(it.absolutePath) }
            }
        }

        return results
    }

    private fun findDocument(root: DocumentFile, relativePath: String): DocumentFile? {
        var current = root
        for (part in relativePath.split("/").filter { it.isNotEmpty() }) {
            current = current.findFile(part) ?: return null
        }
        return current
    }

    private fun writeFileToSaf(uriString: String, fileName: String, bytes: ByteArray): Boolean {
        return try {
            val rootDoc = DocumentFile.fromTreeUri(activity, Uri.parse(uriString)) ?: return false
            val fileDoc = rootDoc.findFile(fileName)
                ?: rootDoc.createFile("application/octet-stream", fileName)
                ?: return false

            val outputStream: OutputStream? = activity.contentResolver.openOutputStream(fileDoc.uri)
            outputStream?.use { it.write(bytes) }
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun copyFileToSaf(sourcePath: String, treeUriString: String, relativePath: String): Boolean {
        return try {
            val rootDoc = DocumentFile.fromTreeUri(activity, Uri.parse(treeUriString)) ?: return false
            val pathParts = sanitizeRelativePath(relativePath).split("/").filter { it.isNotEmpty() }
            val fileName = pathParts.lastOrNull() ?: return false
            val dirParts = pathParts.dropLast(1)

            var currentDir = rootDoc
            for (part in dirParts) {
                val nextDir = currentDir.findFile(part)?.takeIf { it.isDirectory }
                    ?: currentDir.createDirectory(part)
                currentDir = nextDir ?: return false
            }

            // Reuse the existing file (override it) instead of creating a
            // duplicate. "wt" truncates first so overwriting a larger file with
            // a smaller one cannot leave stale trailing bytes.
            val fileDoc = currentDir.findFile(fileName)?.takeIf { it.isFile }
                ?: currentDir.createFile("application/octet-stream", fileName)
                ?: return false
            val outputStream = activity.contentResolver.openOutputStream(fileDoc.uri, "wt") ?: return false
            val inputStream = openSourceInputStream(sourcePath) ?: run {
                outputStream.close()
                return false
            }

            inputStream.use { input ->
                outputStream.use { output -> input.copyTo(output) }
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun openSourceInputStream(sourcePath: String) =
        try {
            val sourceFile = File(sourcePath)
            if (sourceFile.canRead()) {
                FileInputStream(sourceFile)
            } else {
                openMediaStoreInputStream(sourcePath) ?: FileInputStream(sourceFile)
            }
        } catch (_: Exception) {
            null
        }

    private fun openMediaStoreInputStream(sourcePath: String) =
        try {
            val mediaUri = MediaStore.Files.getContentUri("external")
            val projection = arrayOf(MediaStore.MediaColumns._ID)
            val selection = "${MediaStore.MediaColumns.DATA} = ?"
            activity.contentResolver.query(mediaUri, projection, selection, arrayOf(sourcePath), null)?.use { cursor ->
                if (!cursor.moveToFirst()) {
                    return@use null
                }

                val id = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID))
                activity.contentResolver.openInputStream(ContentUris.withAppendedId(mediaUri, id))
            }
        } catch (_: Exception) {
            null
        }

    private fun isUsbTreeUri(treeUri: Uri): Boolean {
        val treeVolumeId = try {
            DocumentsContract.getTreeDocumentId(treeUri).substringBefore(":")
        } catch (_: Exception) {
            return false
        }

        if (treeVolumeId.equals("primary", ignoreCase = true)) {
            return false
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val storageManager = activity.getSystemService(Context.STORAGE_SERVICE) as StorageManager
            val removableVolumeIds = storageManager.storageVolumes
                .filter { volume ->
                    volume.isRemovable &&
                        Environment.MEDIA_MOUNTED == volume.state &&
                        !volume.uuid.isNullOrBlank()
                }
                .mapNotNull { volume -> volume.uuid }

            if (removableVolumeIds.isEmpty()) {
                return true
            }

            return removableVolumeIds.any { it.equals(treeVolumeId, ignoreCase = true) }
        }

        return detectUsbPath() != null
    }

    private fun copyFileToUsb(
        filePath: String,
        relativePath: String,
        fileName: String,
        result: MethodChannel.Result
    ) {
        val treeUri = getPersistedUsbTreeUri()
        if (treeUri == null) {
            result.error("usb_permission_missing", "Select a USB folder before saving files", null)
            return
        }

        val sourceFile = File(filePath)
        if (!sourceFile.exists()) {
            result.error("source_missing", "Downloaded file does not exist", null)
            return
        }

        try {
            val targetDirectory = ensureDirectoryPath(treeUri, relativePath)
            val targetUri = createOrReplaceFile(targetDirectory, sanitizePathSegment(fileName))
            activity.contentResolver.openOutputStream(targetUri, "w").use { output ->
                if (output == null) {
                    result.error("usb_write_failed", "Could not open USB file for writing", null)
                    return
                }

                FileInputStream(sourceFile).use { input -> input.copyTo(output) }
            }
            result.success(targetUri.toString())
        } catch (error: Exception) {
            result.error("usb_write_failed", error.message, null)
        }
    }

    private fun copyFileToSource(
        filePath: String,
        relativePath: String,
        fileName: String,
        result: MethodChannel.Result
    ) {
        val sourceFile = File(filePath)
        if (!sourceFile.exists()) {
            result.error("source_missing", "Downloaded file does not exist", null)
            return
        }

        try {
            val targetUri = copyFileToFixedSource(sourceFile, relativePath, fileName)
            result.success(targetUri.toString())
        } catch (error: Exception) {
            result.error("source_write_failed", error.message, null)
        }
    }

    private fun copyDocumentToUsb(
        documentUriString: String,
        relativePath: String,
        fileName: String,
        expectedSize: Long,
        result: MethodChannel.Result
    ) {
        val treeUri = getPersistedUsbTreeUri()
        if (treeUri == null) {
            result.error("usb_permission_missing", "Select a USB folder before saving files", null)
            return
        }

        try {
            val sourceUri = Uri.parse(documentUriString)
            val targetDirectory = ensureDirectoryPath(treeUri, relativePath)
            val cleanFileName = sanitizePathSegment(fileName)

            // Skip re-copying a file that is already on the USB with the same
            // size — makes re-transferring a collar near-instant.
            if (expectedSize > 0) {
                val existingUri = findChildDocument(targetDirectory, cleanFileName, null)
                if (existingUri != null && documentSize(existingUri) == expectedSize) {
                    result.success("skipped")
                    return
                }
            }

            val targetUri = createOrReplaceFile(targetDirectory, cleanFileName)
            activity.contentResolver.openInputStream(sourceUri).use { input ->
                if (input == null) {
                    result.error("source_open_failed", "Could not open source file", null)
                    return
                }

                activity.contentResolver.openOutputStream(targetUri, "w").use { output ->
                    if (output == null) {
                        result.error("usb_write_failed", "Could not open USB file for writing", null)
                        return
                    }

                    input.copyTo(output)
                }
            }
            result.success(targetUri.toString())
        } catch (error: Exception) {
            result.error("usb_write_failed", error.message, null)
        }
    }

    private fun listSourceFiles(result: MethodChannel.Result) {
        try {
            result.success(listFixedSourceFiles())
        } catch (error: Exception) {
            result.error("source_list_failed", error.message, null)
        }
    }

    /**
     * One-time legacy cleanup: deletes everything under `Download/YAKA`, the
     * rebuildable source cache. Older app versions left wrong-case folders
     * (`EMB` vs `emb`) and `name(N).ext` duplicates here; wiping lets the new
     * pipeline rebuild a clean, correctly-cased, duplicate-free cache on
     * demand. The app owns these files, so no user prompt is required.
     * Returns the number of deleted MediaStore rows (0 on pre-Q / dir delete).
     */
    private fun clearSourceFiles(): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val selection = "${MediaStore.MediaColumns.RELATIVE_PATH} LIKE ?"
            val selectionArgs =
                arrayOf("${Environment.DIRECTORY_DOWNLOADS}/$fixedSourceRoot/%")
            return activity.contentResolver.delete(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                selection,
                selectionArgs
            )
        }

        val sourceDir = fixedSourceDirectory()
        if (sourceDir.exists()) {
            sourceDir.deleteRecursively()
        }
        return 0
    }

    private fun openSourceFolder(result: MethodChannel.Result) {
        try {
            ensureFixedSourceDirectory()
            val sourceUri = DocumentsContract.buildDocumentUri(
                "com.android.externalstorage.documents",
                "primary:${Environment.DIRECTORY_DOWNLOADS}/$fixedSourceRoot"
            )
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(sourceUri, DocumentsContract.Document.MIME_TYPE_DIR)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            activity.startActivity(intent)
            result.success(true)
        } catch (_: Exception) {
            result.success(false)
        }
    }

    private fun openDownloadsFolder(result: MethodChannel.Result) {
        try {
            activity.startActivity(Intent(DownloadManager.ACTION_VIEW_DOWNLOADS))
            result.success(true)
        } catch (_: Exception) {
            result.success(false)
        }
    }

    private fun fixedSourceDirectory(): File {
        return File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
            fixedSourceRoot
        )
    }

    private fun fixedSourceRelativePath(relativePath: String): String {
        return listOf(
            Environment.DIRECTORY_DOWNLOADS,
            fixedSourceRoot,
            sanitizeRelativePath(relativePath)
        )
            .filter { it.isNotBlank() }
            .joinToString("/")
            .trimEnd('/') + "/"
    }

    private fun ensureFixedSourceDirectory() {
        fixedSourceDirectory().mkdirs()
    }

    private fun copyFileToFixedSource(sourceFile: File, relativePath: String, fileName: String): Uri {
        val cleanFileName = sanitizePathSegment(fileName)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val targetRelativePath = fixedSourceRelativePath(relativePath)
            deleteExistingDownloadFile(targetRelativePath, cleanFileName)

            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, cleanFileName)
                put(MediaStore.MediaColumns.MIME_TYPE, "application/octet-stream")
                put(MediaStore.MediaColumns.RELATIVE_PATH, targetRelativePath)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val targetUri = activity.contentResolver.insert(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                values
            ) ?: throw IllegalStateException("Could not create download file: $cleanFileName")

            try {
                activity.contentResolver.openOutputStream(targetUri, "w").use { output ->
                    if (output == null) {
                        throw IllegalStateException("Could not open download file for writing")
                    }

                    FileInputStream(sourceFile).use { input -> input.copyTo(output) }
                }
                values.clear()
                values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                activity.contentResolver.update(targetUri, values, null, null)
                return targetUri
            } catch (error: Exception) {
                activity.contentResolver.delete(targetUri, null, null)
                throw error
            }
        }

        val targetDirectory = File(fixedSourceDirectory(), sanitizeRelativePath(relativePath))
        targetDirectory.mkdirs()
        val targetFile = File(targetDirectory, cleanFileName)
        FileInputStream(sourceFile).use { input ->
            targetFile.outputStream().use { output -> input.copyTo(output) }
        }
        return Uri.fromFile(targetFile)
    }

    private fun listFixedSourceFiles(): List<Map<String, Any?>> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            return listFixedSourceFilesFromMediaStore()
        }

        val files = mutableListOf<Map<String, Any?>>()
        collectRawFiles(fixedSourceDirectory(), "", files)
        return files
    }

    private fun listFixedSourceFilesFromMediaStore(): List<Map<String, Any?>> {
        val files = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
            MediaStore.MediaColumns._ID,
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.MediaColumns.RELATIVE_PATH,
            MediaStore.MediaColumns.SIZE
        )
        val rootPath = "${Environment.DIRECTORY_DOWNLOADS}/$fixedSourceRoot/%"
        val selection = "${MediaStore.MediaColumns.RELATIVE_PATH} LIKE ?"

        activity.contentResolver.query(
            MediaStore.Downloads.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            arrayOf(rootPath),
            null
        ).use { cursor ->
            if (cursor == null) {
                return files
            }

            val idIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
            val nameIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
            val pathIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.RELATIVE_PATH)
            val sizeIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)

            while (cursor.moveToNext()) {
                val id = cursor.getLong(idIndex)
                val name = cursor.getString(nameIndex).orEmpty()
                val storedPath = cursor.getString(pathIndex).orEmpty()
                val relativePath = storedPath
                    .removePrefix("${Environment.DIRECTORY_DOWNLOADS}/$fixedSourceRoot/")
                    .trim('/')
                val uri = ContentUris.withAppendedId(MediaStore.Downloads.EXTERNAL_CONTENT_URI, id)
                files.add(
                    mapOf(
                        "uri" to uri.toString(),
                        "name" to name,
                        "relativePath" to relativePath,
                        "size" to if (cursor.isNull(sizeIndex)) null else cursor.getLong(sizeIndex)
                    )
                )
            }
        }

        return files
    }

    private fun collectRawFiles(parent: File, relativePath: String, files: MutableList<Map<String, Any?>>) {
        parent.listFiles()?.forEach { file ->
            if (file.isDirectory) {
                val childPath = if (relativePath.isBlank()) file.name else "$relativePath/${file.name}"
                collectRawFiles(file, childPath, files)
            } else {
                files.add(
                    mapOf(
                        "uri" to Uri.fromFile(file).toString(),
                        "name" to file.name,
                        "relativePath" to relativePath,
                        "size" to file.length()
                    )
                )
            }
        }
    }

    private fun deleteExistingDownloadFile(relativePath: String, fileName: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return
        }

        // Delete tolerantly instead of matching RELATIVE_PATH/DISPLAY_NAME
        // exactly. An exact `=` match silently misses rows when:
        //   * the OEM stores RELATIVE_PATH without the trailing slash we append
        //     (common on EMUI/Huawei), or
        //   * the on-disk folder case differs (legacy "EMB" vs the "emb" we now
        //     request).
        // A missed row leaves the physical file in place, so the following
        // MediaStore.insert auto-appends " (1)", " (2)", ... — the duplicate
        // "1 (1).jef" pattern seen in Download/YAKA. Query the folder with a
        // case-insensitive prefix, then delete every row whose folder and name
        // match ignoring case, clearing any duplicates already accumulated.
        val targetPath = relativePath.trimEnd('/')
        val selection = "${MediaStore.MediaColumns.RELATIVE_PATH} LIKE ?"
        val selectionArgs = arrayOf("$targetPath%")
        val projection = arrayOf(
            MediaStore.MediaColumns._ID,
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.MediaColumns.RELATIVE_PATH
        )

        activity.contentResolver.query(
            MediaStore.Downloads.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            null
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
            val nameIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
            val pathIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.RELATIVE_PATH)

            while (cursor.moveToNext()) {
                val storedPath = cursor.getString(pathIndex).orEmpty().trimEnd('/')
                val storedName = cursor.getString(nameIndex).orEmpty()
                // The LIKE prefix can over-match sibling folders (e.g. "Y 7630"),
                // so confirm the exact folder and name ignoring case.
                if (!storedPath.equals(targetPath, ignoreCase = true)) continue
                if (!storedName.equals(fileName, ignoreCase = true)) continue

                val id = cursor.getLong(idIndex)
                val uri = ContentUris.withAppendedId(
                    MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                    id
                )
                try {
                    activity.contentResolver.delete(uri, null, null)
                } catch (_: Exception) {
                    // A row the app doesn't own (e.g. created by another signing
                    // key) throws; skip it rather than aborting the download.
                }
            }
        }
    }

    private fun sanitizeRelativePath(relativePath: String): String {
        return relativePath
            .split("/")
            .map { sanitizePathSegment(it) }
            .filter { it.isNotBlank() }
            .joinToString("/")
    }

    private fun sanitizePathSegment(value: String): String {
        return value
            .replace(Regex("""[\\/:*?"<>|]"""), "_")
            .trim()
            .ifBlank { "YAKA" }
    }

    private fun ensureDirectoryPath(treeUri: Uri, relativePath: String): Uri {
        var currentUri = DocumentsContract.buildDocumentUriUsingTree(
            treeUri,
            DocumentsContract.getTreeDocumentId(treeUri)
        )

        sanitizeRelativePath(relativePath)
            .split("/")
            .filter { it.isNotEmpty() }
            .forEach { directoryName ->
                currentUri = findChildDocument(
                    currentUri,
                    directoryName,
                    DocumentsContract.Document.MIME_TYPE_DIR
                ) ?: DocumentsContract.createDocument(
                    activity.contentResolver,
                    currentUri,
                    DocumentsContract.Document.MIME_TYPE_DIR,
                    directoryName
                ) ?: throw IllegalStateException("Could not create USB folder: $directoryName")
            }

        return currentUri
    }

    private fun createOrReplaceFile(parentUri: Uri, fileName: String): Uri {
        findChildDocument(parentUri, fileName, null)?.let { existingUri ->
            DocumentsContract.deleteDocument(activity.contentResolver, existingUri)
        }

        return DocumentsContract.createDocument(
            activity.contentResolver,
            parentUri,
            "application/octet-stream",
            fileName
        ) ?: throw IllegalStateException("Could not create USB file: $fileName")
    }

    /** Byte size of a SAF document, or -1 when unknown. */
    private fun documentSize(documentUri: Uri): Long {
        return try {
            activity.contentResolver.query(
                documentUri,
                arrayOf(DocumentsContract.Document.COLUMN_SIZE),
                null,
                null,
                null
            ).use { cursor ->
                if (cursor != null && cursor.moveToFirst() && !cursor.isNull(0)) {
                    cursor.getLong(0)
                } else {
                    -1L
                }
            }
        } catch (_: Exception) {
            -1L
        }
    }

    private fun findChildDocument(parentUri: Uri, displayName: String, mimeType: String?): Uri? {
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
            parentUri,
            DocumentsContract.getDocumentId(parentUri)
        )
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE
        )

        activity.contentResolver.query(childrenUri, projection, null, null, null).use { cursor ->
            if (cursor == null) {
                return null
            }

            val idIndex = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
            val nameIndex = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
            val mimeIndex = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_MIME_TYPE)

            while (cursor.moveToNext()) {
                val childName = cursor.getString(nameIndex)
                val childMimeType = cursor.getString(mimeIndex)
                // USB drives are FAT32/exFAT (case-insensitive). Match names
                // case-insensitively so an existing folder/file is reused
                // instead of spawning duplicate "emb (1)", "emb (2)" dirs when
                // the on-disk case (legacy "EMB") differs from the request.
                if (childName.equals(displayName, ignoreCase = true) &&
                    (mimeType == null || childMimeType == mimeType)) {
                    val documentId = cursor.getString(idIndex)
                    return DocumentsContract.buildDocumentUriUsingTree(parentUri, documentId)
                }
            }
        }

        return null
    }

    private fun getPersistedUsbTreeUri(): Uri? {
        val treeUri = getPersistedTreeUri(usbTreeUriKey, requireWrite = true)
        if (treeUri == null || !isUsbTreeUri(treeUri)) {
            return null
        }

        return treeUri
    }

    private fun getPersistedSourceTreeUri(): Uri? {
        return getPersistedTreeUri(sourceTreeUriKey, requireWrite = false)
    }

    private fun getPersistedTreeUri(key: String, requireWrite: Boolean): Uri? {
        val uriString = activity.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            .getString(key, null)
            ?: return null
        val uri = Uri.parse(uriString)
        val hasPermission = activity.contentResolver.persistedUriPermissions.any { permission ->
            permission.uri == uri &&
                permission.isReadPermission &&
                (!requireWrite || permission.isWritePermission)
        }

        return if (hasPermission) uri else null
    }

    private fun clearUsbFolderAccess() {
        clearFolderAccess(usbTreeUriKey, getPersistedUsbTreeUri())
    }

    private fun clearSourceFolderAccess() {
        clearFolderAccess(sourceTreeUriKey, getPersistedSourceTreeUri())
    }

    private fun clearFolderAccess(key: String, uri: Uri?) {
        uri?.let {
            try {
                activity.contentResolver.releasePersistableUriPermission(
                    it,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                )
            } catch (_: SecurityException) {
            }
        }

        activity.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            .edit()
            .remove(key)
            .apply()
    }
}
