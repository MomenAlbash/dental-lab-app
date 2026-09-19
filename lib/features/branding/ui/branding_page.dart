import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/helper/network_helper/media_url.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/branding/data/models/branding_model.dart';
import 'package:dental_lab_app/features/branding/logic/branding_cubit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The laboratory's own colour and logo.
///
/// What is set here dresses the **login screen too** — the branding read is
/// anonymous precisely so a lab's app does not show this app's brand to
/// somebody who has not signed in yet.
class BrandingPage extends StatefulWidget {
  const BrandingPage({super.key});

  @override
  State<BrandingPage> createState() => _BrandingPageState();
}

class _BrandingPageState extends State<BrandingPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _colorController;
  late final TextEditingController _presetController;

  late BrandingBackground _background;
  late BrandingControlStyle _controlStyle;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    final branding = getIt<BrandingCubit>().state;

    _colorController = TextEditingController(
      text: branding.primaryColorHex ?? '',
    );
    _presetController = TextEditingController(
      text: branding.presetId ?? 'custom',
    );
    _background = branding.backgroundStyle;
    _controlStyle = branding.controlStyle;
  }

  @override
  void dispose() {
    _colorController.dispose();
    _presetController.dispose();
    super.dispose();
  }

  /// The server enforces `^#[0-9A-Fa-f]{6}$`; saying so here beats a 400.
  String? _validateColor(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'اللون مطلوب';
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(text)) {
      return 'أدخل لوناً بصيغة #RRGGBB';
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isBusy = true);
    final saved = await getIt<BrandingCubit>().save(
      UpdateBrandingRequestModel(
        presetId: _presetController.text.trim().isEmpty
            ? 'custom'
            : _presetController.text.trim(),
        primaryColorHex: _colorController.text.trim(),
        backgroundStyle: _background,
        controlStyle: _controlStyle,
      ),
    );
    if (!mounted) return;

    setState(() => _isBusy = false);
    showToast(
      message: saved ? 'تم حفظ الهوية البصرية' : 'تعذّر حفظ الهوية البصرية',
      state: saved ? ToastState.success : ToastState.error,
    );
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    setState(() => _isBusy = true);
    final uploaded = await getIt<BrandingCubit>().uploadLogo(path);
    if (!mounted) return;

    setState(() => _isBusy = false);
    showToast(
      message: uploaded ? 'تم رفع الشعار' : 'تعذّر رفع الشعار',
      state: uploaded ? ToastState.success : ToastState.error,
    );
  }

  Future<void> _removeLogo() async {
    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'إزالة الشعار',
      message: 'سيعود المختبر لعرض الاسم بدل الشعار.',
      confirmText: 'إزالة',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    final removed = await getIt<BrandingCubit>().removeLogo();
    if (!mounted) return;

    setState(() => _isBusy = false);
    showToast(
      message: removed ? 'تمت إزالة الشعار' : 'تعذّرت إزالة الشعار',
      state: removed ? ToastState.success : ToastState.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return BlocBuilder<BrandingCubit, BrandingModel>(
      bloc: getIt<BrandingCubit>(),
      builder: (context, branding) {
        return GlassScaffold(
          appBar: GlassAppBar(
            title: Text(
              'الهوية البصرية',
              style: AppTextStyles.font18MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              // Capped and centred: this is a form, and a 1000dp-wide colour
              // field is worse, not better.
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'تُطبَّق هذه الهوية على شاشة الدخول أيضاً، قبل تسجيل دخول أي مستخدم',
                          style: AppTextStyles.font12RegularHint.copyWith(
                            color: glass.onGlassMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        _LogoCard(
                          branding: branding,
                          isBusy: _isBusy,
                          onPick: _pickLogo,
                          onRemove: _removeLogo,
                        ),

                        const SizedBox(height: AppSpacing.lg),
                        AppTextFormField(
                          controller: _colorController,
                          hintText: 'اللون الأساسي (#RRGGBB)',
                          prefixIcon: Icon(
                            Icons.palette_outlined,
                            color: glass.onGlassMuted,
                          ),
                          validator: _validateColor,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _ColorPreview(hex: _colorController.text.trim()),

                        const SizedBox(height: AppSpacing.lg),
                        DropdownButtonFormField<BrandingBackground>(
                          initialValue: _background,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'الخلفية',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            for (final style in BrandingBackground.values)
                              DropdownMenuItem(
                                value: style,
                                child: Text(style.label),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _background = value);
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        DropdownButtonFormField<BrandingControlStyle>(
                          initialValue: _controlStyle,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'شكل العناصر',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            for (final style in BrandingControlStyle.values)
                              DropdownMenuItem(
                                value: style,
                                child: Text(style.label),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _controlStyle = value);
                            }
                          },
                        ),

                        const SizedBox(height: AppSpacing.lg),
                        CustomButtonWidget(
                          buttonText: 'حفظ',
                          onPressed: _isBusy ? null : _save,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Text(
                            // Only the accent moves; the greys and surfaces
                            // stay as designed, so a brand colour cannot turn
                            // the product into an unreadable screen.
                            'يُطبَّق اللون على الأزرار والعناصر الفعّالة فقط، وتبقى بقية الألوان كما هي',
                            style: AppTextStyles.font12RegularHint.copyWith(
                              color: glass.onGlassMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LogoCard extends StatelessWidget {
  const _LogoCard({
    required this.branding,
    required this.isBusy,
    required this.onPick,
    required this.onRemove,
  });

  final BrandingModel branding;
  final bool isBusy;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: branding.hasLogo
                ? Image.network(
                    resolveMediaUrl(branding.logoPath) ?? '',
                    fit: BoxFit.contain,
                    // A logo that fails to load falls back to the placeholder
                    // rather than the framework's broken-image glyph, which
                    // reads as a bug in the app rather than a bad upload.
                    errorBuilder: (context, _, _) => Icon(
                      Icons.broken_image_outlined,
                      size: 32,
                      color: glass.onGlassMuted,
                    ),
                  )
                : Icon(
                    Icons.image_outlined,
                    size: 32,
                    color: glass.onGlassMuted,
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'شعار المختبر',
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                Text(
                  branding.hasLogo ? 'مرفوع' : 'لم يُرفع بعد',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: isBusy ? null : onPick,
                      icon: const Icon(Icons.upload_outlined, size: 16),
                      label: Text(branding.hasLogo ? 'استبدال' : 'رفع'),
                    ),
                    if (branding.hasLogo)
                      TextButton.icon(
                        onPressed: isBusy ? null : onRemove,
                        icon: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: glass.error,
                        ),
                        label: Text(
                          'إزالة',
                          style: TextStyle(color: glass.error),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows what the typed hex actually is, live — a colour field nobody can see
/// the result of is a field people get wrong.
class _ColorPreview extends StatelessWidget {
  const _ColorPreview({required this.hex});

  final String hex;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final color = BrandingModel(primaryColorHex: hex).primaryColor;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color ?? Colors.transparent,
            border: Border.all(color: glass.strokeColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: color == null
              ? Icon(Icons.close, size: 16, color: glass.onGlassMuted)
              : null,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          color == null ? 'لون غير صالح' : 'معاينة اللون',
          style: AppTextStyles.font12RegularHint.copyWith(
            color: color == null ? glass.error : glass.onGlassMuted,
          ),
        ),
      ],
    );
  }
}
