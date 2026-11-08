import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'iconly_icons.dart';

/// Renders app icon identifiers with the Hugeicons stroke set.
/// Existing Material icon parameters remain compatible during the migration.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    this.color,
    this.size,
    this.semanticLabel,
    super.key,
  });

  final Object icon;
  final Color? color;
  final double? size;
  final String? semanticLabel;

  static final _boldIcons = <Object>{
    IconlyBold.bag,
    IconlyBold.bag2,
    IconlyBold.heart,
    IconlyBold.home,
    IconlyBold.play,
    IconlyBold.profile,
  };

  static final _hugeIcons = <Object, List<List<dynamic>>>{
    // Main navigation and commonly used actions.
    IconlyLight.arrowLeftCircle: HugeIcons.strokeRoundedCircleArrowLeft01,
    IconlyLight.arrowRightCircle: HugeIcons.strokeRoundedCircleArrowRight01,
    IconlyLight.bag2: HugeIcons.strokeRoundedShoppingBag01,
    IconlyLight.call: HugeIcons.strokeRoundedCall,
    IconlyLight.camera: HugeIcons.strokeRoundedCamera01,
    IconlyLight.delete: HugeIcons.strokeRoundedDelete02,
    IconlyLight.download: HugeIcons.strokeRoundedDownload01,
    IconlyLight.edit: HugeIcons.strokeRoundedEdit01,
    IconlyLight.heart: HugeIcons.strokeRoundedFavourite,
    IconlyLight.home: HugeIcons.strokeRoundedHome01,
    IconlyLight.image: HugeIcons.strokeRoundedImage01,
    IconlyLight.infoSquare: HugeIcons.strokeRoundedInformationSquare,
    IconlyLight.login: HugeIcons.strokeRoundedLogin01,
    IconlyLight.message: HugeIcons.strokeRoundedMessage01,
    IconlyLight.moreCircle: HugeIcons.strokeRoundedMoreHorizontalCircle01,
    IconlyLight.play: HugeIcons.strokeRoundedPlay,
    IconlyLight.profile: HugeIcons.strokeRoundedUser03,
    IconlyLight.search: HugeIcons.strokeRoundedSearch01,
    IconlyLight.upload: HugeIcons.strokeRoundedUpload01,
    IconlyLight.user3: HugeIcons.strokeRoundedUserGroup03,
    IconlyLight.wallet: HugeIcons.strokeRoundedWallet01,
    IconlyBold.bag: HugeIcons.strokeRoundedShoppingBag01,
    IconlyBold.bag2: HugeIcons.strokeRoundedShoppingBag01,
    IconlyBold.heart: HugeIcons.strokeRoundedFavourite,
    IconlyBold.home: HugeIcons.strokeRoundedHome01,
    IconlyBold.play: HugeIcons.strokeRoundedPlay,
    IconlyBold.profile: HugeIcons.strokeRoundedUser03,

    // Material and Cupertino identifiers used by existing screens.
    Icons.add_rounded: HugeIcons.strokeRoundedAdd01,
    Icons.arrow_back_ios_new_rounded: HugeIcons.strokeRoundedArrowLeft01,
    Icons.camera_alt_outlined: HugeIcons.strokeRoundedCamera01,
    Icons.check_circle: HugeIcons.strokeRoundedCheckmarkCircle01,
    Icons.check_circle_rounded: HugeIcons.strokeRoundedCheckmarkCircle01,
    Icons.check_rounded: HugeIcons.strokeRoundedCheck,
    Icons.chevron_right_rounded: HugeIcons.strokeRoundedArrowRight01,
    Icons.close: HugeIcons.strokeRoundedCancel01,
    Icons.close_rounded: HugeIcons.strokeRoundedCancel01,
    Icons.dark_mode_outlined: HugeIcons.strokeRoundedMoon01,
    Icons.done: HugeIcons.strokeRoundedCheck,
    Icons.done_all: HugeIcons.strokeRoundedCheckCheck,
    Icons.done_all_rounded: HugeIcons.strokeRoundedCheckCheck,
    Icons.download: HugeIcons.strokeRoundedDownload01,
    Icons.downloading: HugeIcons.strokeRoundedDownloadCircle01,
    Icons.edit_rounded: HugeIcons.strokeRoundedEdit01,
    Icons.error: HugeIcons.strokeRoundedAlertCircle,
    Icons.error_outline: HugeIcons.strokeRoundedAlertCircle,
    Icons.error_rounded: HugeIcons.strokeRoundedAlertCircle,
    Icons.file_upload_rounded: HugeIcons.strokeRoundedFileUpload,
    Icons.filter_list: HugeIcons.strokeRoundedFilterHorizontal,
    Icons.folder_open_rounded: HugeIcons.strokeRoundedFolderOpen,
    Icons.help_outline: HugeIcons.strokeRoundedHelpCircle,
    Icons.hourglass_empty: HugeIcons.strokeRoundedHourglass,
    Icons.image_outlined: HugeIcons.strokeRoundedImage01,
    Icons.inbox_outlined: HugeIcons.strokeRoundedInbox,
    Icons.info_outline: HugeIcons.strokeRoundedInformationCircle,
    Icons.keyboard_arrow_down_rounded: HugeIcons.strokeRoundedArrowDown01,
    Icons.language_rounded: HugeIcons.strokeRoundedLanguages,
    Icons.looks_one_rounded: HugeIcons.strokeRounded1Circle,
    Icons.looks_two_rounded: HugeIcons.strokeRounded2Circle,
    Icons.looks_3_rounded: HugeIcons.strokeRounded3Circle,
    Icons.pause_circle_filled: HugeIcons.strokeRoundedPauseCircle,
    Icons.pause_rounded: HugeIcons.strokeRoundedPause,
    Icons.play_arrow_rounded: HugeIcons.strokeRoundedPlay,
    Icons.play_circle_filled: HugeIcons.strokeRoundedPlayCircle,
    Icons.play_circle_outline: HugeIcons.strokeRoundedPlayCircle,
    Icons.print_rounded: HugeIcons.strokeRoundedPrinter,
    Icons.question_mark_outlined: HugeIcons.strokeRoundedQuestion,
    Icons.refresh: HugeIcons.strokeRoundedRefresh,
    Icons.remove_done_rounded: HugeIcons.strokeRoundedCancelCircle,
    Icons.search: HugeIcons.strokeRoundedSearch01,
    Icons.send: HugeIcons.strokeRoundedSend,
    CupertinoIcons.add: HugeIcons.strokeRoundedAdd01,
    CupertinoIcons.minus: HugeIcons.strokeRoundedMinus,
    CupertinoIcons.xmark_circle: HugeIcons.strokeRoundedCancelCircle,
  };

  @override
  Widget build(BuildContext context) {
    final hugeIcon = _hugeIcons[icon];
    if (hugeIcon == null) {
      if (icon is IconData) {
        return Icon(
          icon as IconData,
          color: color,
          size: size,
          semanticLabel: semanticLabel,
        );
      }
      throw ArgumentError.value(icon, 'icon', 'No Hugeicons glyph mapped');
    }
    final result = HugeIcon(
      icon: hugeIcon,
      color: color,
      size: size,
      strokeWidth: _boldIcons.contains(icon) ? 2.5 : 1.8,
    );
    return semanticLabel == null
        ? result
        : Semantics(label: semanticLabel, child: result);
  }
}
