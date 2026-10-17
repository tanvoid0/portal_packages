import 'package:flutter/material.dart';

import '../format/portal_format.dart';
import '../theme/portal_icons.dart';
import 'portal_list_item.dart';
import 'portal_network_image.dart';

/// One logged food in a diary list: name, calories, servings, meal and where
/// the entry came from.
///
/// A [PortalListItem] underneath, so the row spacing, tap target and
/// semantics are the fleet's. [imageUrl] leads as a thumbnail; without one
/// [sourceIcon] (manual, scan, recipe: the app picks) leads in a tonal tile.
/// [mealType] is the row's overline; "x2" shows only when [servings] is not 1.
/// With [onDelete] the calories gain a delete button named [deleteTooltip].
/// [sourceSemanticLabel] ("Logged from a photo") is read with the row, since
/// the icon alone is not a name.
class PortalFoodLogTile extends StatelessWidget {
  const PortalFoodLogTile({
    super.key,
    required this.name,
    required this.calories,
    this.servings = 1,
    this.mealType,
    this.sourceIcon,
    this.sourceSemanticLabel,
    this.imageUrl,
    this.onTap,
    this.onDelete,
    this.deleteTooltip = 'Delete entry',
  });

  final String name;
  final int calories;
  final double servings;
  final String? mealType;
  final IconData? sourceIcon;
  final String? sourceSemanticLabel;

  /// A thumbnail; a failed or still-loading one falls back to [sourceIcon].
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final String deleteTooltip;

  @override
  Widget build(BuildContext context) {
    final fmt = PortalFormat.of(context);
    final icon = sourceIcon ?? PortalIcons.restaurant_rounded;
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final servingsText = servings == 1 ? null : 'x${fmt.count(servings)}';
    final kcal = fmt.count(calories);

    return PortalListItem(
      title: name,
      overline: mealType,
      subtitle: servingsText,
      leading: hasImage
          ? PortalListLeading.thumbnail(
              PortalNetworkImage(url: imageUrl, fallbackIcon: icon),
            )
          : PortalListLeading.tile(icon),
      // kcal is a text value (caps at 45% and ellipsizes), and delete is the
      // dedicated `remove` icon-action in its own trailing slot. Gluing them
      // with valueAndAction starves the title at narrow widths (the 48dp button
      // is a control and never shrinks), squeezing the food name out — see
      // PortalListItem's valueAndAction ~107dp known limit.
      trailing: PortalListAccessory.value(kcal, unit: 'kcal'),
      remove: onDelete == null
          ? null
          : PortalListIconAction(
              icon: PortalIcons.delete_rounded,
              tooltip: deleteTooltip,
              onPressed: onDelete,
            ),
      onTap: onTap,
      semanticLabel: [
        if (mealType != null) mealType!,
        name,
        if (servingsText != null) '$servingsText servings',
        '$kcal kcal',
        if (sourceSemanticLabel != null) sourceSemanticLabel!,
      ].join(', '),
    );
  }
}
