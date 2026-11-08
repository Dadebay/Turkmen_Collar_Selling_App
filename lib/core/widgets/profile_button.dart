import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

import '../l10n/app_translations.dart';
import '../theme/color_constants.dart';
import '../icons/app_icon.dart';

class ProfilButton extends StatelessWidget {
  final String name;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Object icon;
  final Widget? langIcon;
  final bool langIconStatus;
  final Widget? trailing;
  final bool isDestructive;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;

  const ProfilButton({
    required this.name,
    required this.onTap,
    required this.icon,
    this.onLongPress,
    this.langIcon,
    this.langIconStatus = false,
    this.trailing,
    this.isDestructive = false,
    this.switchValue,
    this.onSwitchChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDestructive
        ? ColorConstants.redColor
        : ColorConstants.primaryColor;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: langIconStatus && langIcon != null
                    ? ClipOval(
                        child: SizedBox(width: 34, height: 34, child: langIcon),
                      )
                    : AppIcon(icon, color: accent, size: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name.tr,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDestructive ? accent : AppPalette.of(context).text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (switchValue case final value?)
              Transform.scale(
                scale: 0.8,
                alignment: Alignment.centerRight,
                transformHitTests: false,
                child: CupertinoSwitch(
                  value: value,
                  onChanged: onSwitchChanged,
                  activeTrackColor: ColorConstants.primaryColor,
                ),
              )
            else if (onTap != null) ...[
              const SizedBox(width: 8),
              if (trailing case final widget?)
                widget
              else
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: AppIcon(
                    Icons.chevron_right_rounded,
                    size: 17,
                    color: accent,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
