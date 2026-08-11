# CLAUDE.md

<!--
This file loads into context on EVERY message in this project.
Apply the Golden Test before adding any rule:
"Would removing this cause Claude to make mistakes?" If not — cut it.
Do not restate language defaults Claude already knows. Only write rules
that override defaults or encode decisions specific to this project.
-->




# Section A — General Engineering Rules

## 1) Architecture & Separation of Concerns (PROJECT SPECIFIC)

- Follow the project's established structure: data → logic → ui

- data: Contains models, repositories (implementation), and data sources.

- logic: Contains state management (Cubit/Bloc) and business logic.

- ui: Contains screens (pages) and reusable widgets.

- Never bypass layers or mix responsibilities.

- UI layer has ZERO business logic — only rendering, interaction, and state observation.

- Business logic lives in the logic layer.

- Data access (APIs, databases, storage) lives in the data layer.

## 2) Shared Code

- Any reusable logic, utility, constant, extension, or helper used in 2+ places goes in core/

- Check core/ before creating new shared code — never duplicate across features.

## 3) Error Handling

- Errors flow cleanly across layers.

- Handle null, empty, loading, and error states explicitly — no silent failures.

- Catch errors at the boundary (data layer), not deep inside logic.

## 4) Change Discipline

- Make the smallest change that solves the problem.

- Fix root causes, not symptoms.

- Don't refactor unrelated code unless explicitly requested.

- Never break existing functionality, APIs, flows, or UX unless explicitly instructed.

## 5) Dependencies

- Don't add new packages without justification.

- Any new package must be: latest stable, well-maintained, production-grade.

## 6) Security

- Never hardcode secrets, tokens, or credentials.

- Never log sensitive information.

- Validate all external and API input.

7) Testing

- Write Unit Tests for the logic layer (Cubit/Bloc) and data layer (Repositories/Models).

- Bug fixes must include a reproducing test case.

- Tests must be deterministic — no flaky or timing-dependent tests.

- One behavior per test case.

- Use mocktail or mockito for mocking dependencies in the logic and data layers.


Section B — Flutter / Dart Specific Rules

## 1) State Management

- Use Cubit/Bloc for feature and application state (located in the logic/ folder).

- Cubits depend on repositories or data sources defined in the data/ folder.

- setState is allowed ONLY for local UI state (e.g., toggles, form focus) — never for business logic.

## 2) No Code Generation

- No Freezed. No build_runner. Use Dart 3+ native features instead:

- sealed class for state unions with exhaustive pattern matching.

- switch expressions and records for lightweight data.



## 3) Feature Folder Structure

•features/{feature_name}/data/ (models, repo)

•features/{feature_name}/logic/ (cubit, state)

•features/{feature_name}/ui/ (pages, widgets)

## 4) Dependency Injection

•Use get_it as the service locator.

•Register dependencies in a single core/di/ setup file.

•Cubits and repositories are resolved via get_it, not instantiated manually.

## 5) Build Method Discipline

•Prefer const constructors wherever possible.

•NEVER create TextEditingController, AnimationController, or FocusNode inside build().

•Dispose controllers and focus nodes in StatefulWidget.dispose().

•Use BlocBuilder/BlocSelector on the smallest widget that needs the state.


# Section C — Cross-Platform (iOS/Android)

## 1) Unified Design, Responsive Layout
- One consistent design system across iOS and Android — no platform-specific look (no Cupertino widgets, no adaptive icons/switches). Same fonts, colors, components, and interaction patterns on both.
- Never hardcode pixel dimensions for layout — use `MediaQuery`, `LayoutBuilder`, or flexible widgets (`Expanded`, `Flexible`, `FractionallySizedBox`) so screens adapt to different widths/heights.
- Design against at least three breakpoints in mind: small phones (~360dp width), standard phones (~390–430dp), and tablets/foldables (~600dp+) — use `LayoutBuilder`/`MediaQuery` to branch layout at these breakpoints, not to change platform styling.
- Text must scale properly — respect system font scaling (`MediaQuery.textScaler`) and never disable it unless explicitly instructed; test layouts at larger text scale factors.
- Respect safe areas on both platforms — wrap screens with `SafeArea`, account for iOS notch/Dynamic Island and Android gesture nav/status bar, regardless of design being unified.
- Images/icons must be resolution-independent (SVG or multi-density assets) — never ship a single fixed-size raster asset used across all screen densities.

## 1a) Adaptive Layout — tablet is a first-class target
Tablet is a primary target, not a phone build that happens to run on a bigger screen. A screen that fills a tablet with one centred column is NOT done.

- **Breakpoints live in `AppBreakpoints`** (`core/widgets/adaptive_layout.dart`): `< 600` phone, `600–899` tablet, `>= 900` desktop. Never write a bare `600` / `900` comparison — branch with `AdaptiveLayout`, or with `AdaptiveLayout.formFactorFor(width)` / `AdaptiveLayout.of(context)` when the widget already has a `LayoutBuilder`.
- **BANNED: `final contentWidth = isWide ? 700.0 : constraints.maxWidth;`** and every variant of capping content and centring it as the *only* response to a wide screen. That pattern was removed from the whole app on purpose — do not reintroduce it. (Capping is still right for forms and body text; see below.)
- **Lists/grids of cards → `AdaptiveCollection`** (`core/widgets/adaptive_collection.dart`). Never hand-roll a `ListView.builder` for a collection of cards: it already handles the phone list, the tablet grid, pull-to-refresh, padding, the stagger animation, and scaling the grid's row height by the user's text setting. Pass `cardHeight` when the card is taller or shorter than the default 132.
- **Detail screens → `AdaptiveDetailSections`** (`core/widgets/adaptive_detail_sections.dart`). Split sections by role, not by order: `main` = what the record *is* (info tiles, attachments, the edit form), `side` = what the user can *do* about it (quick actions, pending decisions). On a phone `side` renders first — something waiting on the user comes before what they read.
- **Navigation is already handled**: any screen built on `GlassScaffold` with a `drawer` gets the pinned navigation column from tablet up for free. Do not add per-screen tablet navigation.
- **Forms and body text stay capped and centred** (~560dp). A 1000dp-wide text field is worse, not better. This is the one place a max width is the correct adaptive answer.
- **Anything pinned beside the page is outside the page's `Navigator`.** A widget that may be hosted there (the drawer is) must not call `Navigator.pop()` to dismiss itself — that pops the page. Read the form factor off the *window* (`AdaptiveLayout.of`), not the widget's own constraints, since a 280dp column reports itself as a phone.
- **Test both shapes.** Widget tests default to an 800dp window, which is a tablet — a test that means the phone layout must set `tester.view.physicalSize` to a phone size explicitly, or it will silently assert against the grid.

## 2) Permissions
- All permission requests (camera, location, notifications, photos, etc.) go through a single wrapper in `core/permissions/` — never call platform permission APIs directly from UI or logic.
- Handle "denied", "permanently denied", and "restricted" (iOS) states explicitly — don't assume a binary granted/denied.
- iOS requires usage-description strings in `Info.plist` for every permission used — any new permission must come with the matching `Info.plist` entry AND `AndroidManifest.xml` entry in the same change.

## 3) Platform Channels / Native Code
- Avoid platform channels unless a package doesn't cover the need — check pub.dev first (see dependency rule in Section A.5).
- If a platform channel is unavoidable, isolate it behind an interface in `data/` — logic and ui layers must never call `MethodChannel` directly.
- Any native code added (Swift/Kotlin) must be justified and documented — don't leave native logic undocumented.

## 4) Build & Config
- Keep `pubspec.yaml`, iOS `Info.plist`, and Android `AndroidManifest.xml` in sync for: app name, permissions, deep links/URL schemes, minimum OS version.
- Never change iOS deployment target or Android `minSdkVersion` without explicit instruction — this can silently break support for older devices.
- Environment-specific config (dev/staging/prod) goes through flavors — never hardcode API URLs or keys per platform.

## 5) Notifications & Background
- Push notification setup differs structurally (APNs vs FCM) — any notification-related code must handle both, never assume FCM-only behavior.
- Background execution limits differ heavily between iOS and Android — don't write logic that assumes Android-style unrestricted background tasks will work on iOS.

## 6) Testing on Both Platforms
- Widget/unit tests must not assume a specific platform — mock `Platform`/`defaultTargetPlatform` when testing platform-dependent branches.
- Include at least one test/screenshot check per screen at a small-width breakpoint to catch overflow issues.
- Any platform-specific bug fix must state which platform(s) it targets and must not silently change behavior on the other platform.