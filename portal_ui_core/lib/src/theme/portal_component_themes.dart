import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/design_tokens.dart';
import '../tokens/portal_radii_utils.dart';
import 'portal_theme_helpers.dart';
import 'portal_ui_theme.dart';

/// Optional overrides applied on top of scheme-derived component themes.
@immutable
class PortalComponentThemeOptions {
  const PortalComponentThemeOptions({
    this.scaffoldBackgroundColor,
    this.canvasColor,
    this.navigationBarBackgroundColor,
    this.bottomNavigationBarBackgroundColor,
    this.appBarBackgroundColor,
    this.cardColor,
    this.centerAppBarTitle = true,
    this.systemUiOverlayStyle,
  });

  final Color? scaffoldBackgroundColor;
  final Color? canvasColor;
  final Color? navigationBarBackgroundColor;
  final Color? bottomNavigationBarBackgroundColor;
  final Color? appBarBackgroundColor;
  final Color? cardColor;
  final bool centerAppBarTitle;
  final SystemUiOverlayStyle? systemUiOverlayStyle;
}

SystemUiOverlayStyle portalSystemUiOverlay(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness:
        isDark ? Brightness.light : Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );
}

/// Applies shared Material component themes derived from [colorScheme] and
/// [tokens]. Returns [base] merged with component theme fields.
ThemeData applyPortalComponentThemes({
  required ThemeData base,
  required ColorScheme colorScheme,
  required DesignTokens tokens,
  required TextTheme textTheme,
  PortalComponentThemeOptions options = const PortalComponentThemeOptions(),
}) {
  final cs = colorScheme;
  final r = tokens.radii;
  final s = tokens.spacing;
  final borderWidth = tokens.borderWidth;
  final muted = cs.onSurfaceVariant;
  final border = cs.outline;
  final elevated = cs.surfaceContainerHigh;
  // A button's textStyle replaces the label style outright, so it has to
  // carry the app typeface itself (the family lives on [base]'s text theme).
  final buttonLabel = (base.textTheme.labelLarge ?? const TextStyle())
      .copyWith(fontWeight: FontWeight.w600, fontSize: 15);
  // Tonal: a card is a tone step off the page, not a bordered box.
  final cardSurface = options.cardColor ??
      (cs.brightness == Brightness.dark
          ? cs.surfaceContainerHigh
          : cs.surfaceContainerLow);
  // Floating panels (dialog, sheet, popup) sit one tone above a card.
  final panelSurface = options.cardColor ?? cs.surfaceContainerHigh;
  final scaffold =
      options.scaffoldBackgroundColor ?? cs.surface;
  final canvas = options.canvasColor ?? cs.surfaceContainerHighest;
  final navBar = options.navigationBarBackgroundColor ?? cs.surface;
  final bottomNavBar =
      options.bottomNavigationBarBackgroundColor ?? cs.surface;
  final appBarBg = options.appBarBackgroundColor ?? scaffold;
  final overlay =
      options.systemUiOverlayStyle ?? portalSystemUiOverlay(cs.brightness);
  // A field is one tone off whatever holds it: page, card or panel. Highest
  // by default; a surface palette folds Highest into its card colour, so
  // there the field steps to High instead of vanishing into the card.
  final inputFill =
      {scaffold, cardSurface, panelSurface}.contains(cs.surfaceContainerHighest)
          ? cs.surfaceContainerHigh
          : cs.surfaceContainerHighest;
  final borderSide = BorderSide(
    color: border.withValues(alpha: 0.75),
    width: borderWidth,
  );
  final focusedBorder = BorderSide(
    color: cs.primary,
    width: borderWidth + 0.5,
  );

  OutlineInputBorder outlineBorder({BorderSide? side}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(r.md),
        borderSide: side ?? borderSide,
      );
  // Dialogs and the date/time pickers share one shell: radii.xl, hairline.
  final panelShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(r.xl),
    side: BorderSide(color: border.withValues(alpha: 0.35)),
  );

  return base.copyWith(
    primaryColor: cs.primary,
    scaffoldBackgroundColor: scaffold,
    canvasColor: canvas,
    dividerColor: border.withValues(alpha: 0.45),
    // copyWith, not a fresh IconThemeData: the Symbols axes (weight, fill,
    // grade, opticalSize) come from buildPortalTheme and must survive.
    iconTheme: base.iconTheme.copyWith(color: muted, size: 22),
    primaryIconTheme:
        base.primaryIconTheme.copyWith(color: cs.onPrimary, size: 22),
    splashColor: cs.primary.withValues(alpha: 0.08),
    highlightColor: cs.primary.withValues(alpha: 0.04),
    hoverColor: cs.primary.withValues(alpha: 0.04),
    focusColor: cs.primary.withValues(alpha: 0.08),
    dividerTheme: DividerThemeData(
      color: border.withValues(alpha: 0.45),
      space: s.lg,
      thickness: 1,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cardSurface,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.symmetric(vertical: s.xs),
      shape: tokens.expressiveCorners
          ? r.continuousBorder(borderRadius: r.circular(r.lg))
          : r.roundedBorder(borderRadius: r.circular(r.lg)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: appBarBg,
      foregroundColor: cs.onSurface,
      elevation: 0,
      centerTitle: options.centerAppBarTitle,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: overlay,
      iconTheme: IconThemeData(color: cs.onSurface, size: 24),
      actionsIconTheme: IconThemeData(color: muted, size: 22),
      titleTextStyle: textTheme.titleLarge,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      elevation: 0,
      highlightElevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.lg),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: navBar,
      indicatorColor: cs.primary.withValues(alpha: 0.16),
      elevation: 0,
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? cs.primary : muted,
          size: 22,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          letterSpacing: 0.1,
          color: selected ? cs.primary : muted,
        );
      }),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: bottomNavBar,
      selectedItemColor: cs.primary,
      unselectedItemColor: muted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 11,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFill,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: s.lg, vertical: s.md),
      hintStyle: TextStyle(color: muted),
      labelStyle: TextStyle(color: muted),
      border: outlineBorder(side: BorderSide.none),
      enabledBorder: outlineBorder(side: BorderSide.none),
      disabledBorder: outlineBorder(side: BorderSide.none),
      focusedBorder: outlineBorder(side: focusedBorder),
      errorBorder: outlineBorder(side: BorderSide(color: cs.error)),
      focusedErrorBorder: outlineBorder(
        side: BorderSide(color: cs.error, width: borderWidth + 0.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        disabledBackgroundColor: cs.primary.withValues(alpha: 0.35),
        disabledForegroundColor: cs.onPrimary.withValues(alpha: 0.7),
        padding: EdgeInsets.symmetric(horizontal: s.xl, vertical: s.md),
        minimumSize: Size(tokens.minTapTarget, tokens.minTapTarget),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(r.full),
        ),
        textStyle: buttonLabel.copyWith(letterSpacing: 0.1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        disabledBackgroundColor: cs.primary.withValues(alpha: 0.35),
        padding: EdgeInsets.symmetric(horizontal: s.xl, vertical: s.md),
        minimumSize: Size(tokens.minTapTarget, tokens.minTapTarget),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(r.full),
        ),
        textStyle: buttonLabel,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.onSurface,
        disabledForegroundColor: muted.withValues(alpha: 0.5),
        padding: EdgeInsets.symmetric(horizontal: s.xl, vertical: s.md),
        minimumSize: Size(tokens.minTapTarget, tokens.minTapTarget),
        side: BorderSide(color: border.withValues(alpha: 0.85)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(r.md),
        ),
        textStyle: buttonLabel,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: cs.primary,
        padding: EdgeInsets.symmetric(horizontal: s.lg, vertical: s.sm),
        minimumSize: Size(tokens.minTapTarget, tokens.minTapTarget),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(r.sm),
        ),
        textStyle: buttonLabel,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: elevated,
      disabledColor: cs.surfaceContainerLow,
      selectedColor: cs.primary.withValues(alpha: 0.16),
      secondarySelectedColor: cs.primary.withValues(alpha: 0.16),
      labelStyle: TextStyle(
        color: cs.onSurface,
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
      secondaryLabelStyle: TextStyle(
        color: cs.primary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
      side: BorderSide(color: border.withValues(alpha: 0.5)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.full),
      ),
      showCheckmark: false,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: s.lg, vertical: s.xs),
      minLeadingWidth: 40,
      iconColor: muted,
      textColor: cs.onSurface,
      titleTextStyle: TextStyle(
        color: cs.onSurface,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      subtitleTextStyle: TextStyle(
        color: muted,
        fontSize: 13,
        height: 1.35,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.md),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: panelSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: panelShape,
      titleTextStyle: TextStyle(
        color: cs.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 20,
        letterSpacing: -0.2,
      ),
      contentTextStyle: TextStyle(
        color: muted,
        fontSize: 15,
        height: 1.45,
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: panelSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: panelShape,
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: panelSurface,
      elevation: 0,
      shape: panelShape,
      // The dial and the hour/minute fields are fields: one tone off the
      // panel, like inputFill. M3's unselected default is Highest, which a
      // surface palette folds into the panel itself.
      dialBackgroundColor: inputFill,
      hourMinuteColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? cs.primaryContainer
            : inputFill,
      ),
      hourMinuteShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.md),
      ),
      dayPeriodShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.md),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: panelSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      // Styles the handle; does not force it on. Apps still hand-draw one on
      // a transparent sheet, and a theme handle would float 48dp above it.
      // C1's PortalSheet passes showDragHandle itself.
      dragHandleColor: border,
      dragHandleSize: const Size(36, 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(r.xl)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: cs.surface,
      contentTextStyle: TextStyle(
        color: cs.onSurface,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      actionTextColor: cs.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.md),
        side: BorderSide(color: border.withValues(alpha: 0.65)),
      ),
      elevation: 3,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return muted.withValues(alpha: 0.4);
        }
        if (states.contains(WidgetState.selected)) return cs.onPrimary;
        return muted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        // A disabled track is still a track (onSurface 12% shows on any page);
        // a selected one is solid primary, never a washed-out tint.
        if (states.contains(WidgetState.disabled)) {
          return states.contains(WidgetState.selected)
              ? cs.primary.withValues(alpha: 0.35)
              : cs.onSurface.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.selected)) return cs.primary;
        return cs.outlineVariant;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return cs.primary;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(cs.onPrimary),
      side: BorderSide(color: cs.outline, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.sm / 2),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return cs.primary;
        return cs.outline;
      }),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return cs.primary.withValues(alpha: 0.14);
          }
          return elevated;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary;
          return cs.onSurface;
        }),
        side: WidgetStateProperty.all(
          BorderSide(color: border.withValues(alpha: 0.55)),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(r.md),
          ),
        ),
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(horizontal: s.md, vertical: s.sm),
        ),
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    ),
    // Indicator left to M3: a 3dp rounded label-width primary bar with the
    // elastic slide. An explicit `indicator` here would override
    // TabBar.indicatorColor and give TabBar.secondary the primary pill too.
    tabBarTheme: TabBarThemeData(
      dividerColor: Colors.transparent,
      labelColor: cs.onSurface,
      unselectedLabelColor: muted,
      overlayColor: WidgetStatePropertyAll(cs.primary.withValues(alpha: 0.08)),
    ),
    // M3's 2024 slider spelled out (`year2023: false` is deprecated): a
    // 4x44 pill handle that narrows under the finger, a tall track with a
    // gap either side of it, and a rounded value label.
    sliderTheme: SliderThemeData(
      trackHeight: 16,
      trackGap: 6,
      thumbShape: const HandleThumbShape(),
      trackShape: const GappedSliderTrackShape(),
      rangeThumbShape: const HandleRangeSliderThumbShape(),
      rangeTrackShape: const GappedRangeSliderTrackShape(),
      tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2),
      valueIndicatorShape: const RoundedRectSliderValueIndicatorShape(),
      thumbSize: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.pressed)
            ? const Size(2, 44)
            : const Size(4, 44),
      ),
      activeTrackColor: cs.primary,
      // Tinted like the progress track, not M3's secondaryContainer: a surface
      // palette maps that to surfacePanel, a hair off the card in dark mode.
      inactiveTrackColor: cs.primary.withValues(alpha: 0.15),
      activeTickMarkColor: cs.onPrimary,
      inactiveTickMarkColor: cs.primary,
      thumbColor: cs.primary,
      overlayColor: cs.primary.withValues(alpha: 0.12),
      valueIndicatorColor: cs.primary,
      valueIndicatorTextStyle: TextStyle(
        color: cs.onPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: cs.primary,
      linearTrackColor: cs.primary.withValues(alpha: 0.15),
      circularTrackColor: cs.primary.withValues(alpha: 0.15),
      refreshBackgroundColor: cs.portalElevatedSurface,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: panelSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.lg),
        side: BorderSide(color: border.withValues(alpha: 0.35)),
      ),
      textStyle: TextStyle(
        color: cs.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: cs.onSurface,
        borderRadius: BorderRadius.circular(r.sm),
      ),
      textStyle: TextStyle(
        color: scaffold,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
      waitDuration: const Duration(milliseconds: 500),
    ),
    scrollbarTheme: portalUiThemeFrom(base) != null
        ? portalScrollbarTheme(portalUiThemeFrom(base)!)
        : ScrollbarThemeData(
            crossAxisMargin: 1,
            mainAxisMargin: 1,
            thickness: const WidgetStatePropertyAll(8),
            radius: const Radius.circular(999),
            thumbColor: WidgetStatePropertyAll(border.withValues(alpha: 0.65)),
          ),
  );
}

/// Convenience accessor when building custom component themes in app code.
extension PortalThemeBuildContextColors on ColorScheme {
  Color get portalMuted => onSurfaceVariant;
  Color get portalBorder => outline;
  Color get portalElevatedSurface => surfaceContainerHigh;
  Color get portalPanelSurface => surfaceContainer;
}

/// Reads [PortalUiTheme] from a built [ThemeData] if present.
PortalUiTheme? portalUiThemeFrom(ThemeData theme) =>
    theme.extension<PortalUiTheme>();
