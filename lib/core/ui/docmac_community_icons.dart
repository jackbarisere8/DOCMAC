import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Named paths for the Community icon assets selected for DOCMAC.
///
/// The original export names are retained in assets so their source remains
/// traceable; this class provides stable, readable names for application code.
abstract final class DocmacCommunityIcons {
  static const _freePack = 'assets/icons/community/free_icon_pack/';
  static const _smooothOutline = 'assets/icons/community/smoooth/outline/';

  static const home = '${_smooothOutline}home.svg';
  static const talkPin = '${_smooothOutline}talk_pin.svg';
  static const seeMore = '${_smooothOutline}see_more.svg';
  static const archive = '${_smooothOutline}archive.svg';
  static const talk = '${_freePack}Chat_duotone_line.svg';
  static const live = '${_freePack}Phone_light.svg';
  static const profile = '${_freePack}User_duotone_line.svg';
  static const relay = '${_freePack}Message_open_duotone_line.svg';
  static const settings = '${_freePack}Setting_line_duotone.svg';
  static const notification = '${_freePack}Bell_duotone_line.svg';
  static const calendar = '${_freePack}Date_range_duotone_line.svg';
  static const camera = '${_freePack}Camera.svg';
  static const searchFile = '${_freePack}File_dock_search_line.svg';
  static const back = '${_freePack}Arrow_left_light.svg';
  static const send = '${_freePack}Message_open_duotone_line.svg';
}

/// Displays a Community SVG with the same theme-aware coloring as [Icon].
class DocmacCommunityIcon extends StatelessWidget {
  const DocmacCommunityIcon({
    super.key,
    required this.asset,
    this.color,
    this.size = 24,
    this.semanticLabel,
  });

  final String asset;
  final Color? color;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        color ??
        IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface;

    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      semanticsLabel: semanticLabel,
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
    );
  }
}
