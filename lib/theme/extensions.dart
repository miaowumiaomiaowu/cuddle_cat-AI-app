import 'package:flutter/material.dart';

/// Theme extensions for gradients, shadows, and state layers.
/// Keep these generic; values are provided from AppTheme.lightTheme.

class AppGradients extends ThemeExtension<AppGradients> {
  final Gradient mistSky; // soft background gradient
  final Gradient fieldGreen; // CTA/celebration gradient

  const AppGradients({
    required this.mistSky,
    required this.fieldGreen,
  });

  @override
  AppGradients copyWith({Gradient? mistSky, Gradient? fieldGreen}) => AppGradients(
        mistSky: mistSky ?? this.mistSky,
        fieldGreen: fieldGreen ?? this.fieldGreen,
      );

  @override
  ThemeExtension<AppGradients> lerp(ThemeExtension<AppGradients>? other, double t) {
    if (other is! AppGradients) return this;
    // Gradients don't lerp trivially; just switch by threshold
    return t < 0.5 ? this : other;
  }
}

class AppShadows extends ThemeExtension<AppShadows> {
  final List<BoxShadow> soft; // card default
  final List<BoxShadow> elevated; // elevated components

  const AppShadows({
    required this.soft,
    required this.elevated,
  });

  @override
  AppShadows copyWith({List<BoxShadow>? soft, List<BoxShadow>? elevated}) => AppShadows(
        soft: soft ?? this.soft,
        elevated: elevated ?? this.elevated,
      );

  @override
  ThemeExtension<AppShadows> lerp(ThemeExtension<AppShadows>? other, double t) {
    if (other is! AppShadows) return this;
    // Shadows lerp: approximate by linear interpolation of the first shadow pair
    List<BoxShadow> _lerpList(List<BoxShadow> a, List<BoxShadow> b) {
      final len = (a.length > b.length) ? a.length : b.length;
      return List.generate(len, (i) {
        final sa = i < a.length ? a[i] : const BoxShadow();
        final sb = i < b.length ? b[i] : const BoxShadow();
        return BoxShadow(
          color: Color.lerp(sa.color, sb.color, t) ?? sa.color,
          blurRadius: lerpDouble(sa.blurRadius, sb.blurRadius, t),
          spreadRadius: lerpDouble(sa.spreadRadius, sb.spreadRadius, t),
          offset: Offset.lerp(sa.offset, sb.offset, t) ?? sa.offset,
        );
      });
    }

    return AppShadows(
      soft: _lerpList(soft, other.soft),
      elevated: _lerpList(elevated, other.elevated),
    );
  }

  double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

class AppStateLayers extends ThemeExtension<AppStateLayers> {
  final double hovered;
  final double focused;
  final double pressed;
  final double dragged;

  const AppStateLayers({
    required this.hovered,
    required this.focused,
    required this.pressed,
    required this.dragged,
  });

  @override
  AppStateLayers copyWith({double? hovered, double? focused, double? pressed, double? dragged}) => AppStateLayers(
        hovered: hovered ?? this.hovered,
        focused: focused ?? this.focused,
        pressed: pressed ?? this.pressed,
        dragged: dragged ?? this.dragged,
      );

  @override
  ThemeExtension<AppStateLayers> lerp(ThemeExtension<AppStateLayers>? other, double t) {
    if (other is! AppStateLayers) return this;
    double _lerp(double a, double b) => a + (b - a) * t;
    return AppStateLayers(
      hovered: _lerp(hovered, other.hovered),
      focused: _lerp(focused, other.focused),
      pressed: _lerp(pressed, other.pressed),
      dragged: _lerp(dragged, other.dragged),
    );
  }
}

