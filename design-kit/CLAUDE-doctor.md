# CLAUDE.md — تطبيق الدكتور

> **انسخ هذا الملف إلى جذر مشروع الدكتور باسم `CLAUDE.md`.**
>
> هو نسخة من قواعد مشروع المخبر، معدّلة لمجال الدكتور. القواعد الهندسية نفسها
> عمداً: التطبيقان منتج واحد، ويجب أن يُقرأ كودهما بالطريقة نفسها.

---

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
- **The design system in `core/theming/` and `core/widgets/glass/` is ported from
  the lab app. Do not edit those files locally** — if the doctor app needs a
  different look, build a new widget on top of them. Editing them makes the next
  re-sync a manual merge.

## 3) Error Handling

- Errors flow cleanly across layers.
- Handle null, empty, loading, and error states explicitly — no silent failures.
- Catch errors at the boundary (data layer), not deep inside logic.
- The API's `message` field is always the line to show the user.

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
- Persist the JWT securely, and clear the session on any `401`.

## 7) Testing

- Write Unit Tests for the logic layer (Cubit/Bloc) and data layer (Repositories/Models).
- Bug fixes must include a reproducing test case.
- Tests must be deterministic — no flaky or timing-dependent tests.
- One behavior per test case.
- Use mocktail or mockito for mocking dependencies in the logic and data layers.

---

# Section B — Flutter / Dart Specific Rules

## 1) State Management

- Use Cubit/Bloc for feature and application state (located in the logic/ folder).
- Cubits depend on repositories or data sources defined in the data/ folder.
- setState is allowed ONLY for local UI state (e.g., toggles, form focus) — never for business logic.

## 2) No Code Generation

- No Freezed. No build_runner. Use Dart 3+ native features instead:
- sealed class for state unions with exhaustive pattern matching.
- switch expressions and records for lightweight data.

## 3) Feature Folder Structure

- features/{feature_name}/data/ (models, repo)
- features/{feature_name}/logic/ (cubit, state)
- features/{feature_name}/ui/ (pages, widgets)

## 4) Dependency Injection

- Use get_it as the service locator.
- Register dependencies in a single core/di/ setup file.
- Cubits and repositories are resolved via get_it, not instantiated manually.

## 5) Build Method Discipline

- Prefer const constructors wherever possible.
- NEVER create TextEditingController, AnimationController, or FocusNode inside build().
- Dispose controllers and focus nodes in StatefulWidget.dispose().
- Use BlocBuilder/BlocSelector on the smallest widget that needs the state.

---

# Section C — Cross-Platform (iOS/Android)

## 1) Unified Design, Responsive Layout

- One consistent design system across iOS and Android — no platform-specific look
  (no Cupertino widgets, no adaptive icons/switches). Same fonts, colors,
  components, and interaction patterns on both.
- Never hardcode pixel dimensions for layout — use `MediaQuery`, `LayoutBuilder`,
  or flexible widgets so screens adapt.
- Design against three breakpoints: small phones (~360dp), standard phones
  (~390–430dp), and tablets/foldables (~600dp+).
- Text must scale properly — respect `MediaQuery.textScaler` and never disable it.
- Respect safe areas on both platforms.
- Images/icons must be resolution-independent (SVG or multi-density assets).

## 1a) Adaptive Layout — tablet is a first-class target

Tablet is a primary target, not a phone build on a bigger screen.

- **Breakpoints live in `AppBreakpoints`** (`core/widgets/adaptive_layout.dart`):
  `< 600` phone, `600–899` tablet, `>= 900` desktop. Never write a bare `600` /
  `900` comparison — branch with `AdaptiveLayout`, or `AdaptiveLayout.of(context)`.
- **BANNED: `final contentWidth = isWide ? 700.0 : constraints.maxWidth;`** and
  every variant of capping content and centring it as the *only* response to a
  wide screen.
- **Lists/grids of cards → `AdaptiveCollection`.** It handles the phone list, the
  tablet grid, pull-to-refresh, padding, the stagger, and row height under the
  user's text setting.
- **Detail screens → `AdaptiveDetailSections`.** Split by role, not order:
  `main` = what the record *is*, `side` = what the user can *do* about it. On a
  phone `side` renders first.
- **Navigation is already handled**: any screen on `GlassScaffold` with a `drawer`
  gets the pinned navigation column from tablet up.
- **Forms and body text stay capped and centred** (~560dp).
- **Anything pinned beside the page is outside the page's `Navigator`.** Such a
  widget must not call `Navigator.pop()` to dismiss itself, and must read the form
  factor off the *window* (`AdaptiveLayout.of`), not its own constraints.
- **Test both shapes.** Widget tests default to an 800dp window, which is a
  tablet — a test meaning the phone layout must set `tester.view.physicalSize`.

## 1b) Visual identity — non-negotiable

See `DESIGN-SYSTEM.md` (ported alongside this file). In short:

- Every colour comes from `context.glass` or `Theme.of(context).colorScheme` —
  **never a hardcoded colour**, and never `AppColorsManger` read directly in a
  screen (those are compile-time constants and do not follow the theme).
- Every text style from `AppTextStyles`, every space from `AppSpacing`, every
  radius from `AppRadius`, every duration from `AppMotion`.
- Screens are built on `GlassScaffold`, not a bare `Scaffold`.
- Arabic is the primary language: `start`/`end` only, never `left`/`right`.
- Status colours are never re-hued to the brand, and colour is never the only
  signal — every status badge carries its label.

## 2) Permissions

- All permission requests go through a single wrapper in `core/permissions/` —
  never call platform permission APIs directly from UI or logic.
- Handle "denied", "permanently denied", and "restricted" (iOS) explicitly.
- Any new permission needs its `Info.plist` entry AND `AndroidManifest.xml` entry
  in the same change.

## 3) Platform Channels / Native Code

- Avoid platform channels unless a package doesn't cover the need.
- If unavoidable, isolate behind an interface in `data/`.
- Any native code added (Swift/Kotlin) must be justified and documented.

## 4) Build & Config

- Keep `pubspec.yaml`, iOS `Info.plist`, and Android `AndroidManifest.xml` in sync
  for: app name, permissions, deep links, minimum OS version.
- Never change the iOS deployment target or Android `minSdkVersion` without
  explicit instruction.
- **The API origin is a compile-time constant, never a literal in the transport
  layer**: `String.fromEnvironment('API_ORIGIN', defaultValue: ...)`, overridable
  with `--dart-define`. Media URLs derive from the same origin.

## 5) Notifications & Background

- Push setup differs structurally (APNs vs FCM) — handle both, never assume FCM.
- Background execution limits differ heavily between iOS and Android.

## 6) Testing on Both Platforms

- Widget/unit tests must not assume a platform — mock `defaultTargetPlatform`.
- Include at least one test per screen at a small-width breakpoint to catch overflow.
- Any platform-specific fix must state which platform(s) it targets.

---

# Section D — Doctor domain (تعديلات خاصة بهذا التطبيق)

## 1) Base URL and auth

- Base: `<API_ORIGIN>/api/doctor` — **not** `/api/clinic`.
- `POST /DoctorAuth/login` → JWT, sent as `Authorization: Bearer <token>`.
- `GET /DoctorAuth/me` → current doctor.
- `POST /DoctorAuth/change-password`, `POST /DoctorAuth/register`.
- Registration needs two public lookups: `GET /DoctorAuth/register/cities` and
  `GET /DoctorAuth/register/laboratories`.
- On any `401`: clear the session and hard-route to login.

> **The doctor registers and lands inactive** — the lab activates the account.
> The login screen must say that clearly instead of showing a bare "unauthorized".

## 2) The doctor sees less — by design, from the server

The API itself omits fields for a doctor; **do not rebuild the lab's models and
hide fields client-side.** Read each DTO from `swagger/doctor` before porting a
model across.

## 3) Feature surface (from the Doctor swagger)

| المجال | النقاط |
|---|---|
| الحالات | `GET/POST /Cases`, `GET /Cases/{id}`, `GET /Cases/status-counts`, `GET /Cases/{id}/pdf` |
| ملفات ورسائل الحالة | `/Cases/{id}/files`, `/Cases/{id}/messages` |
| التجربة | `PUT /Cases/{id}/trying/approve`, `PUT /Cases/{id}/trying/reject` |
| إعادة العمل | `GET /Cases/{id}/restorations/{restorationId}/rework-stages` |
| التسليم | `PUT /Cases/{id}/collection-method`, `PUT /Cases/{id}/finish` |
| الكتالوج | `GET /Catalog/restoration-types` (بأسعار هذا الطبيب), `GET /Catalog/delivery-quote` |
| المرضى | `GET/POST /Patients`, `GET /Patients/{id}` |
| العيادات | `GET /Clinics` |
| الملف الشخصي | `GET/PUT /Profile`, `POST /Profile/image` |
| جلسات السكانر | `/scanner-sessions` (+ `availability`, `by-number`, `cancel`, `messages`, `case`) |
| رفع المسوحات | `POST /cases/{caseId}/scans` |
| حصة الأولويات | `GET /priority-quota`, `GET /priority-quota/preview` |
| الهوية البصرية | `GET /Branding` — **`?scope=doctor`** |

## 4) Pricing — the one bug a doctor never forgives

Quote from `GET /Catalog/restoration-types`, which returns the catalogue **priced
for this doctor** (their tier or negotiated rate). Never quote a default price:
showing a total different from the invoice is unforgivable.

`GET /priority-quota/preview` tells the doctor what a rush tier will cost **before**
they choose it — show it in the create-case form, not after saving.

## 5) Branding is server-driven

`GET /Branding?scope=doctor` returns the lab's accent colour and logo. Fetch it on
every boot, cache it, and paint the cached theme first — never flash the defaults.
The design tokens in `DESIGN-SYSTEM.md` are the fallback and the structure; the
accent may be overridden per laboratory.
