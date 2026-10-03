// SPDX-FileCopyrightText: 2026 Frank Martínez <mnesarco at gmail>
// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

/// Brand palette documented in the launcher icon master
/// (`packaging/appimage/freecad-launcher.svg`).
abstract final class AppBrandColors {
  static const tuftsBlue = Color(0xFF418FDE);
  static const lightRed = Color(0xFFFF585D);
  static const darkRed = Color(0xFFCB333B);
  static const offBlack = Color(0xFF212529);
}

/// Semantic status colors that are not part of the Material scheme
/// (success/warning/info/running), provided for every theme.
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.running,
    required this.runningContainer,
    required this.onRunningContainer,
  });

  static const light = AppStatusColors(
    success: Color(0xFF1B6E3C),
    successContainer: Color(0xFFD3EFDF),
    onSuccessContainer: Color(0xFF0B3D22),
    warning: Color(0xFF8A5300),
    warningContainer: Color(0xFFFFE7C4),
    onWarningContainer: Color(0xFF4A2C00),
    info: Color(0xFF0B5FA5),
    infoContainer: Color(0xFFD2E7FB),
    onInfoContainer: Color(0xFF0A3A63),
    running: Color(0xFFB93A43),
    runningContainer: Color(0xFFFFE0E1),
    onRunningContainer: Color(0xFF7A1218),
  );

  static const dark = AppStatusColors(
    success: Color(0xFF7BD3A0),
    successContainer: Color(0xFF17402A),
    onSuccessContainer: Color(0xFFB9EFCD),
    warning: Color(0xFFF3BE63),
    warningContainer: Color(0xFF4C3512),
    onWarningContainer: Color(0xFFFFDFA6),
    info: Color(0xFF8CC6FF),
    infoContainer: Color(0xFF123C61),
    onInfoContainer: Color(0xFFC4E1FF),
    running: Color(0xFFFF8A8E),
    runningContainer: Color(0xFF63202A),
    onRunningContainer: Color(0xFFFFD9DB),
  );

  static AppStatusColors of(BuildContext context) =>
      Theme.of(context).extension<AppStatusColors>() ?? light;

  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color running;
  final Color runningContainer;
  final Color onRunningContainer;

  @override
  AppStatusColors copyWith({
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? running,
    Color? runningContainer,
    Color? onRunningContainer,
  }) {
    return AppStatusColors(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      running: running ?? this.running,
      runningContainer: runningContainer ?? this.runningContainer,
      onRunningContainer: onRunningContainer ?? this.onRunningContainer,
    );
  }

  @override
  AppStatusColors lerp(AppStatusColors? other, double t) {
    if (other == null) {
      return this;
    }
    return AppStatusColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      running: Color.lerp(running, other.running, t)!,
      runningContainer: Color.lerp(runningContainer, other.runningContainer, t)!,
      onRunningContainer: Color.lerp(onRunningContainer, other.onRunningContainer, t)!,
    );
  }
}
