part of 'usb_transfer_bloc.dart';

sealed class UsbTransferEvent {
  const UsbTransferEvent();
}

final class UsbTransferStarted extends UsbTransferEvent {
  const UsbTransferStarted();
}

final class UsbTransferRefreshRequested extends UsbTransferEvent {
  const UsbTransferRefreshRequested();
}

final class UsbFolderRequested extends UsbTransferEvent {
  const UsbFolderRequested();
}

final class UsbProductOpened extends UsbTransferEvent {
  const UsbProductOpened(this.productId);
  final int productId;
}

final class UsbProductClosed extends UsbTransferEvent {
  const UsbProductClosed();
}

final class UsbVersionToggled extends UsbTransferEvent {
  const UsbVersionToggled({required this.productId, required this.machineName});
  final int productId;
  final String machineName;
}

/// Selects every available model of [productId] at once, or clears them all if
/// they are already fully selected.
final class UsbAllVersionsToggled extends UsbTransferEvent {
  const UsbAllVersionsToggled(this.productId);
  final int productId;
}

/// Clears the entire selection across all products.
final class UsbSelectionCleared extends UsbTransferEvent {
  const UsbSelectionCleared();
}

final class UsbTransferTriggered extends UsbTransferEvent {
  const UsbTransferTriggered();
}
