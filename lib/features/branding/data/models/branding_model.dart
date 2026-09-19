import 'package:flutter/material.dart';

/// The backdrop a laboratory dresses its surfaces in (`backgroundStyle`).
///
/// A closed set, and the server validates it against exactly this list — an
/// unknown value from a newer backend falls back to [charcoal] rather than
/// leaving the screen with no ground at all.
enum BrandingBackground {
  charcoal('charcoal', 'فحمي'),
  white('white', 'أبيض'),
  midnight('midnight', 'ليلي'),
  forest('forest', 'أخضر داكن'),
  clinic('clinic', 'عيادة');

  const BrandingBackground(this.key, this.label);

  final String key;
  final String label;

  static BrandingBackground fromKey(String? key) {
    for (final style in BrandingBackground.values) {
      if (style.key == key) return style;
    }
    return BrandingBackground.charcoal;
  }
}

/// How controls are shaped (`controlStyle`).
enum BrandingControlStyle {
  classic('classic', 'كلاسيكي'),
  soft('soft', 'ناعم'),
  pill('pill', 'دائري'),
  square('square', 'مربّع');

  const BrandingControlStyle(this.key, this.label);

  final String key;
  final String label;

  static BrandingControlStyle fromKey(String? key) {
    for (final style in BrandingControlStyle.values) {
      if (style.key == key) return style;
    }
    return BrandingControlStyle.classic;
  }
}

/// Which surface a branding record dresses.
///
/// The same laboratory brands three different audiences, and this app is only
/// ever the [admin] one — but the value is sent explicitly rather than left to
/// a server default, so a future screen for the other two has somewhere to go.
enum BrandingScope {
  admin('admin'),
  doctor('doctor'),
  website('website');

  const BrandingScope(this.key);

  final String key;
}

/// One laboratory's visual identity (`BrandingDto`).
///
/// `GET /Branding` is anonymous on purpose: the login screen has to be dressed
/// in the lab's own colour **before** anybody has a token, and a hardcoded
/// palette there is the one place every white-labelled app gives itself away.
class BrandingModel {
  const BrandingModel({
    this.presetId,
    this.primaryColorHex,
    this.scope,
    this.backgroundStyle = BrandingBackground.charcoal,
    this.controlStyle = BrandingControlStyle.classic,
    this.logoPath,
  });

  /// What the app looks like with nothing fetched — its own default brand.
  static const fallback = BrandingModel();

  final String? presetId;

  /// `#RRGGBB`. Null means the lab never chose one and the app's own brand
  /// colour stands.
  final String? primaryColorHex;

  /// Echoed back by the server, so a client can tell which scope it actually
  /// received when it asked for one.
  final String? scope;

  final BrandingBackground backgroundStyle;
  final BrandingControlStyle controlStyle;

  /// Relative path — resolved through the app's media-url helper like every
  /// other uploaded file.
  final String? logoPath;

  /// The primary colour as a [Color], or null when the hex is missing or
  /// malformed. Malformed is treated as absent rather than as black: a
  /// mistyped brand colour should leave the app looking like itself.
  Color? get primaryColor {
    final hex = primaryColorHex?.trim();
    if (hex == null || hex.length != 7 || !hex.startsWith('#')) return null;

    final value = int.tryParse(hex.substring(1), radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }

  bool get hasLogo => logoPath?.trim().isNotEmpty ?? false;

  Map<String, dynamic> toJson() => {
    'presetId': presetId,
    'primaryColorHex': primaryColorHex,
    'scope': scope,
    'backgroundStyle': backgroundStyle.key,
    'controlStyle': controlStyle.key,
    'logoPath': logoPath,
  };

  factory BrandingModel.fromJson(Map<String, dynamic> json) {
    return BrandingModel(
      presetId: json['presetId'] as String?,
      primaryColorHex: json['primaryColorHex'] as String?,
      scope: json['scope'] as String?,
      backgroundStyle: BrandingBackground.fromKey(
        json['backgroundStyle'] as String?,
      ),
      controlStyle: BrandingControlStyle.fromKey(
        json['controlStyle'] as String?,
      ),
      logoPath: json['logoPath'] as String?,
    );
  }
}

/// `UpdateBrandingRequest`.
///
/// The server enforces `^#[0-9A-Fa-f]{6}$` on the colour and a closed set on
/// the two styles, so the form validates the same way rather than discovering
/// it in a 400.
class UpdateBrandingRequestModel {
  const UpdateBrandingRequestModel({
    required this.presetId,
    required this.primaryColorHex,
    required this.backgroundStyle,
    this.controlStyle,
  });

  final String presetId;
  final String primaryColorHex;
  final BrandingBackground backgroundStyle;
  final BrandingControlStyle? controlStyle;

  Map<String, dynamic> toJson() => {
    'presetId': presetId,
    'primaryColorHex': primaryColorHex,
    'backgroundStyle': backgroundStyle.key,
    'controlStyle': controlStyle?.key,
  };
}
