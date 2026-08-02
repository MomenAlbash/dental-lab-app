/// Border-radius and spacing tokens from the `Dental-Lab-Admin` design
/// system (base radius `8px`, base spacing unit `4px`). Reference these
/// instead of hardcoding numbers so every screen stays in sync with the web
/// dashboard.
class AppRadius {
  AppRadius._();

  /// Buttons (default size), select items, checkbox.
  static const double sm = 4;

  /// Inputs, selects, badges, nav items, small/large buttons, tab triggers,
  /// tooltips, popovers, dropdowns.
  static const double md = 6;

  /// Compact/stat cards, dialogs, tables, tab bar track, empty states, icon
  /// tiles, drawers.
  static const double lg = 8;

  /// The standard `Card` component.
  static const double xl = 12;

  /// Avatars, switch, pills, circular icon containers.
  static const double full = 9999;
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  /// Standard screen content padding (mobile).
  static const double screen = 16;

  /// Card padding (all sides), dialog padding.
  static const double cardPadding = 24;

  /// Vertical gap between page sections.
  static const double sectionGap = 24;

  /// Grid gap between cards.
  static const double gridGap = 16;

  /// Table/list cell padding.
  static const double cellHorizontal = 12;
  static const double cellVertical = 6;
}
