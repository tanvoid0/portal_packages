import 'package:flutter/material.dart';

/// App-wide layout insets beyond the spacing scale (page padding, nav clearance).
@immutable
class PortalLayoutInsets {
  const PortalLayoutInsets({
    this.pageHorizontal = 16,
    this.sectionGap = 24,
    this.listBottomInset = 96,
  });

  final double pageHorizontal;
  final double sectionGap;
  final double listBottomInset;

  PortalLayoutInsets copyWith({
    double? pageHorizontal,
    double? sectionGap,
    double? listBottomInset,
  }) {
    return PortalLayoutInsets(
      pageHorizontal: pageHorizontal ?? this.pageHorizontal,
      sectionGap: sectionGap ?? this.sectionGap,
      listBottomInset: listBottomInset ?? this.listBottomInset,
    );
  }
}
