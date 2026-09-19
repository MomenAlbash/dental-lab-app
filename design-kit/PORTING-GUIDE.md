# دليل النقل — من تطبيق المخبر إلى تطبيق الدكتور

> هذا الدليل يشرح **ماذا تنسخ بالضبط**، **بأي ترتيب**، **وما الذي يجب ألّا
> تنسخه**. الفرز أدناه مبني على فحص فعلي لاعتماديات كل ملف، لا على تخمين.
>
> المصطلح المستعمل: `<doctor_pkg>` = اسم الحزمة في `pubspec.yaml` لمشروع
> الدكتور (مثلاً `doctor_app`).

---

## قبل أن تبدأ — المقايضة التي قبلتَها

النسخ يعني وجود **نسختين** من نظام التصميم في مستودعين منفصلين. أي تعديل لاحق
على الهوية (لون، خط، سلوك ويدجت زجاجية) يجب تطبيقه **مرّتين**.

لتبقى إعادة النسخ ممكنة دفعةً واحدة لاحقاً:

- **لا تعدّل ملفات الطبقة (أ) محلياً في مشروع الدكتور.** إن احتجت اختلافاً،
  أضف ويدجت جديدة فوقها بدل تعديلها.
- سجّل في مشروع الدكتور تاريخ آخر نسخة (سطر في `README` أو commit واضح) حتى
  تعرف ما تغيّر في الأصل بعده.

---

## الخطوة ١ — إنشاء المشروع وتثبيت الحزم

```bash
flutter create --org com.m2dental --project-name doctor_app doctor_app
cd doctor_app
```

### الحزم التي يحتاجها نظام التصميم فقط

هذه هي **كل** الحزم الخارجية التي يستوردها الكود المنسوخ في الطبقتين (أ) و(ب):

```bash
flutter pub add flutter_bloc shared_preferences flutter_animate fluttertoast dartz
```

| الحزمة | لماذا |
|---|---|
| `flutter_bloc` | `ThemeCubit` و`FontScaleCubit` و`ConnectivityCubit` |
| `shared_preferences` | `CacheHelper` — حفظ الثيم ومقياس النص |
| `flutter_animate` | حركات الدخول والتدرّج في القوائم |
| `fluttertoast` | `ShowToast` |
| `dartz` | `cacheable_fetch.dart` (إن نسخته) |

### حزم الميزات — تُضاف عند الحاجة لا الآن

`dio`، `get_it`، `go_router`، `path_provider`، `url_launcher`، `file_picker`،
`record`، `audioplayers`، `mobile_scanner`، `qr_flutter`، `share_plus`،
`flutter_localizations`.

> `flutter_localizations` مطلوبة فوراً إن أردت `MaterialApp` عربية كاملة (وهو
> المتوقّع) — أضفها مع المجموعة الأولى.

---

## الخطوة ٢ — الخطوط والأصول

انسخ من مشروع المخبر:

```
assets/fonts/Tajawal-Regular.ttf
assets/fonts/Tajawal-Medium.ttf
assets/fonts/Tajawal-Bold.ttf
```

وأضف إلى `pubspec.yaml` تحت `flutter:` **حرفياً**:

```yaml
  fonts:
    - family: Tajawal
      fonts:
        - asset: assets/fonts/Tajawal-Regular.ttf
          weight: 400
        - asset: assets/fonts/Tajawal-Medium.ttf
          weight: 500
        - asset: assets/fonts/Tajawal-Bold.ttf
          weight: 700
```

> إن نسيت هذه الكتلة سيبدو التطبيق شبيهاً لكن **بخط النظام** — وهو أول ما
> يكشف أن التطبيقين ليسا نفس المنتج.

انسخ أيضاً شعار التطبيق وأي صور مشتركة، وحدّث `lib/core/theming/assets.dart`
بمساراتها.

---

## الخطوة ٣ — بيان النسخ

### الطبقة (أ) — تُنسخ كما هي

لا تعتمد على أي `feature` ولا على أي شيء خارج `core/theming`.

**`lib/core/theming/` — انسخ المجلد كاملاً عدا ملفَّي الكيوبت:**

```
colors.dart            app_theme.dart        glass.dart
styles.dart            font_weight_helper.dart
app_dimensions.dart    app_motion.dart       badge_variant.dart
assets.dart
```

**`lib/core/widgets/glass/` — انسخ المجلد كاملاً (13 ملف):**

```
glass_scaffold.dart          glass_app_bar.dart        glass_bottom_sheet.dart
glass_card.dart              glass_container.dart      glass_section_title.dart
glass_save_bar.dart          glass_add_button.dart     glass_filter_button.dart
glass_skeleton.dart          glass_info_tiles.dart     glass_attachments_section.dart
glass_summary_strip.dart
```

**`lib/core/widgets/` — الملفات التالية فقط:**

```
adaptive_layout.dart          adaptive_collection.dart
adaptive_detail_sections.dart custom_button_widget.dart
custom_text_field_widget.dart custom_circle_progress_indiacator_widget.dart
confirm_dialog_widget.dart    show_toast_widget.dart
detail_info_row_widget.dart   coming_soon_body.dart
unsaved_changes_guard.dart    app_bottom_nav_bar.dart
```

**اعتماديات داخلية بين ملفات هذه الطبقة** (انسخها كمجموعة، لا ملفاً منفرداً):

| الملف | يستورد |
|---|---|
| `glass_scaffold.dart` | `adaptive_layout.dart` |
| `glass_save_bar.dart` | `custom_button_widget.dart` |
| `adaptive_collection.dart`, `adaptive_detail_sections.dart` | `adaptive_layout.dart` |
| `unsaved_changes_guard.dart` | `confirm_dialog_widget.dart` |

### الطبقة (ب) — تُنسخ مع تبعيتها

| انسخ | ويجب أن تنسخ معه |
|---|---|
| `core/theming/theme_cubit.dart` | `core/helper/local/cached_helper.dart` + `cache_keys.dart` |
| `core/theming/font_scale_cubit.dart` | نفس الملفين أعلاه |
| `core/widgets/offline_banner_wrapper.dart` | `core/connectivity/connectivity_cubit.dart` |

**`cache_keys.dart` يحتاج تنظيفاً:** فيه مفاتيح كاش خاصة بالمخبر (قوائم
الحالات، الأطباء، المراحل…). أبقِ مفتاحَي `theme` و`fontScale` وما يخصّ الجلسة،
واحذف الباقي — أو أبقِه كما هو مؤقتاً (مفاتيح غير مستعملة غير ضارّة) ونظّفه لاحقاً.

**`cacheable_fetch.dart`** اختياري: انسخه فقط إن أردت نمط "الرجوع للكاش عند
انقطاع الشبكة" في طبقة البيانات (يحتاج `dartz`).

### الطبقة (ج) — لا تنسخها

| الملف | السبب |
|---|---|
| `core/widgets/app_drawer_widget.dart` | قائمة تنقّل المخبر + صلاحياته + مساراته. **أعد كتابته** بقائمة الدكتور مع الحفاظ على الشكل: خلفية `brandCharcoal`، الصف النشط `brandCharcoalLight` مع مؤشّر برتقالي 3px على الحافة البادئة |
| `core/widgets/doctor_audience_sheet.dart` | يعتمد على ميزة الأطباء في المخبر |
| `core/widgets/stage_assignees_sheet.dart` | يعتمد على الأقسام والمستخدمين |
| `core/widgets/stage_assignees_field.dart` | تابع للسابق |
| `core/widgets/graph_fork.dart` | مستقلّ عن أي ميزة تقنياً (رسّام وصلات مخطّط)، لكن لا حاجة له في تطبيق الدكتور — انسخه فقط إن رسمت مخطّطاً شجرياً |
| `core/widgets/cached_network_image_widget.dart` | معطّل بالكامل (كود معلّق) |

---

## الخطوة ٤ — الاستبدال الميكانيكي لاسم الحزمة

كل ملف منسوخ يستورد `package:dental_lab_app/...`. بعد النسخ، من جذر مشروع
الدكتور:

```bash
grep -rl "package:dental_lab_app/" lib/ \
  | xargs sed -i "s|package:dental_lab_app/|package:doctor_app/|g"
```

ثم تحقّق أنه لم يبقَ شيء:

```bash
grep -rn "dental_lab_app" lib/ || echo "نظيف"
```

---

## الخطوة ٥ — تركيب `main.dart`

الحدّ الأدنى لتشغيل الهوية كاملة (الثيم + مقياس النص + العربية + شريط انقطاع
الاتصال). هذه نسخة مبسّطة من `main.dart` في المخبر بلا التوجيه وحقن التبعيات:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheHelper.init();          // قبل أي كيوبت يقرأ التفضيلات
  runApp(const DoctorApp());
}

class DoctorApp extends StatelessWidget {
  const DoctorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => FontScaleCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => BlocBuilder<FontScaleCubit, FontScale>(
            builder: (context, fontScale) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  textScaler: applyFontScale(media.textScaler, fontScale),
                ),
                child: OfflineBannerWrapper(
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
          ),
          home: const _Probe(),   // شاشة التحقّق، الخطوة ٦
        ),
      ),
    );
  }
}
```

**ثلاث نقاط لا تُهمَل:**

1. `CacheHelper.init()` **قبل** إنشاء أي كيوبت — الكيوبتان يقرآن التفضيل
   المحفوظ في مُنشئهما، ووميض الافتراضي ثم التصحيح يُقرأ كعطل.
2. `applyFontScale` تُلفّ حول `MediaQuery` في `builder` لا في `home` — وإلا لن
   تصل إلى الحوارات والشيتات لأنها تُبنى في `Overlay` أعلى الشجرة.
3. `locale: Locale('ar')` مع `GlobalMaterialLocalizations` — بدونها تبقى
   الحوارات وأزرار النظام بالإنجليزية داخل واجهة عربية.

---

## الخطوة ٦ — شاشة التحقّق

اكتب شاشة واحدة تستعمل كل طبقات النظام، وقارنها جنباً إلى جنب مع شاشة تسجيل
الدخول في تطبيق المخبر:

```dart
class _Probe extends StatelessWidget {
  const _Probe({super.key});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(
          'تحقّق الهوية',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            const GlassSectionTitle('عناصر'),
            const SizedBox(height: AppSpacing.md),
            AppTextFormField(
              hintText: 'حقل نصّي',
              controller: TextEditingController(),
              validator: (_) => null,
            ),
            const SizedBox(height: AppSpacing.lg),
            CustomButtonWidget(buttonText: 'زر أساسي', onPressed: () {}),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'نص ثانوي',
              style: AppTextStyles.font12RegularHint
                  .copyWith(color: glass.onGlassMuted),
            ),
          ],
        ),
      ),
    );
  }
}
```

### قائمة التحقّق

| # | ما تفحصه | المتوقّع |
|---|---|---|
| 1 | `flutter analyze` | **نظيف** — أي بقايا استيراد أو ملف طبقة (ب) منسي تظهر هنا |
| 2 | الشاشة جنباً إلى جنب مع المخبر | نفس الخط، نفس الزوايا، نفس الظلال، نفس الخلفية المتدرّجة |
| 3 | تبديل الوضع الداكن | كل الألوان تتبع؛ **لا نص شبه أسود على خلفية شبه سوداء** |
| 4 | مقياس النص `large` | لا تجاوز (overflow) في أي صف |
| 5 | عرض 360dp | التخطيط سليم على هاتف صغير |
| 6 | عرض 800dp (تابلت) | يتكيّف عبر `AdaptiveLayout` لا بحشوة أكبر |
| 7 | الاتجاه | كل شيء منعكس صحيحاً؛ الأيقونات والحواف بالجهة الصحيحة |
| 8 | إعادة التشغيل بعد تغيير الثيم | التفضيل محفوظ ويُقرأ فوراً بلا وميض |

---

## الخطوة ٧ — قواعد الهندسة

انسخ `design-kit/CLAUDE-doctor.md` إلى **جذر مشروع الدكتور** باسم `CLAUDE.md`.
هو نسخة من قواعد المخبر معدّلة لمجال الدكتور (`/api/doctor`، لا شاشات مخبر).

---

## ما بعد الهوية — نقل الميزات

الميزات نفسها (الحالات، المواعيد، الجلسات، الملف الشخصي) تُبنى ميزةً ميزة من
`swagger/doctor`، بنفس بنية `data / logic / ui`.

**تحذير من فخّ متكرّر:** لا تنسخ موديلات المخبر كما هي. تعريفات الدكتور
(`DoctorCaseDto` مثلاً) **أضيق**: السيرفر نفسه يحذف حقولاً (الأسعار، سجلّ
المراحل، بيانات الطبيب الأخرى). انسخ الشكل وتحقّق من كل حقل مقابل
`swagger/doctor` قبل الاعتماد عليه.
