import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../models/enums.dart';

/// One colour pair (+ icon) for a status or priority.
class SemanticStyle {
  const SemanticStyle({required this.container, required this.onContainer, required this.icon, this.border});

  final Color container;
  final Color onContainer;
  final IconData icon;

  /// Only Low/Medium priority badges have a hairline border.
  final Color? border;

  SemanticStyle lerp(SemanticStyle other, double t) => SemanticStyle(
        container: Color.lerp(container, other.container, t)!,
        onContainer: Color.lerp(onContainer, other.onContainer, t)!,
        icon: t < 0.5 ? icon : other.icon,
        border: Color.lerp(border, other.border, t),
      );
}

/// Issue status palette. Filled pill, icon + label always.
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({required this.reported, required this.acknowledged, required this.inProgress, required this.resolved});

  final SemanticStyle reported;
  final SemanticStyle acknowledged;
  final SemanticStyle inProgress;
  final SemanticStyle resolved;

  static const light = StatusColors(
    reported: SemanticStyle(container: Color(0xFFFDE2E7), onContainer: Color(0xFF8C1537), icon: Symbols.flag_rounded),
    acknowledged: SemanticStyle(container: Color(0xFFFFEFC2), onContainer: Color(0xFF6A4800), icon: Symbols.visibility_rounded),
    inProgress: SemanticStyle(container: Color(0xFFDAE8FF), onContainer: Color(0xFF0B4A8F), icon: Symbols.construction_rounded),
    resolved: SemanticStyle(container: Color(0xFFD4F1DF), onContainer: Color(0xFF0E5C35), icon: Symbols.check_circle_rounded),
  );

  SemanticStyle of(IssueStatus status) => switch (status) {
        IssueStatus.reported => reported,
        IssueStatus.acknowledged => acknowledged,
        IssueStatus.inProgress => inProgress,
        IssueStatus.resolved => resolved,
      };

  @override
  StatusColors copyWith({SemanticStyle? reported, SemanticStyle? acknowledged, SemanticStyle? inProgress, SemanticStyle? resolved}) =>
      StatusColors(
        reported: reported ?? this.reported,
        acknowledged: acknowledged ?? this.acknowledged,
        inProgress: inProgress ?? this.inProgress,
        resolved: resolved ?? this.resolved,
      );

  @override
  StatusColors lerp(StatusColors? other, double t) {
    if (other == null) return this;
    return StatusColors(
      reported: reported.lerp(other.reported, t),
      acknowledged: acknowledged.lerp(other.acknowledged, t),
      inProgress: inProgress.lerp(other.inProgress, t),
      resolved: resolved.lerp(other.resolved, t),
    );
  }
}

/// Priority palette. Square 4dp badge so it never reads as a status;
/// signal bars encode the level.
class PriorityColors extends ThemeExtension<PriorityColors> {
  const PriorityColors({required this.low, required this.medium, required this.high});

  final SemanticStyle low;
  final SemanticStyle medium;
  final SemanticStyle high;

  static const light = PriorityColors(
    low: SemanticStyle(
        container: Color(0xFFFFFFFF), onContainer: Color(0xFF3E4A56), border: Color(0xFFC4CAD0), icon: Symbols.signal_cellular_alt_1_bar_rounded),
    medium: SemanticStyle(
        container: Color(0xFFFFF1E3), onContainer: Color(0xFF7F3D00), border: Color(0xFFEDC39B), icon: Symbols.signal_cellular_alt_2_bar_rounded),
    // Tonal rather than solid red, so a list of high-priority issues doesn't shout.
    high: SemanticStyle(
        container: Color(0xFFFCE8E6), onContainer: Color(0xFFA3241B), border: Color(0xFFF4C7C2), icon: Symbols.signal_cellular_alt_rounded),
  );

  SemanticStyle of(IssuePriority priority) => switch (priority) {
        IssuePriority.low => low,
        IssuePriority.medium => medium,
        IssuePriority.high => high,
      };

  @override
  PriorityColors copyWith({SemanticStyle? low, SemanticStyle? medium, SemanticStyle? high}) =>
      PriorityColors(low: low ?? this.low, medium: medium ?? this.medium, high: high ?? this.high);

  @override
  PriorityColors lerp(PriorityColors? other, double t) {
    if (other == null) return this;
    return PriorityColors(low: low.lerp(other.low, t), medium: medium.lerp(other.medium, t), high: high.lerp(other.high, t));
  }
}

extension SemanticColorsContext on BuildContext {
  StatusColors get statusColors => Theme.of(this).extension<StatusColors>()!;
  PriorityColors get priorityColors => Theme.of(this).extension<PriorityColors>()!;
}
