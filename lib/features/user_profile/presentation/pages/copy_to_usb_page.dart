import 'usb_transfer_page.dart';

/// `CopyToUsbPage` is the legacy entry-point. The behaviour and UI live in
/// [UsbTransferPage] now (UI from old `usb_transfer_view.dart`, business logic
/// from old `copy_to_usb_view.dart`). The router still references this name,
/// so we keep an alias to avoid changing route wiring.
typedef CopyToUsbPage = UsbTransferPage;
