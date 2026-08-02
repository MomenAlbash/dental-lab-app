import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/price_tier_model.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tier_prices/price_tier_prices_cubit.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tier_prices/price_tier_prices_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Edits every restoration type's price within one price tier.
class PriceTierPricesPage extends StatelessWidget {
  const PriceTierPricesPage({super.key, required this.priceTier});

  final PriceTierModel priceTier;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PriceTierPricesCubit>()..load(priceTier.id),
      child: _PriceTierPricesView(priceTierName: priceTier.name ?? '—'),
    );
  }
}

class _PriceTierPricesView extends StatefulWidget {
  const _PriceTierPricesView({required this.priceTierName});

  final String priceTierName;

  @override
  State<_PriceTierPricesView> createState() => _PriceTierPricesViewState();
}

class _PriceTierPricesViewState extends State<_PriceTierPricesView> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(PriceTierPriceItem item) {
    return _controllers.putIfAbsent(
      item.restorationTypeId,
      () => TextEditingController(
        text: item.price > 0 ? item.price.toStringAsFixed(0) : '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      appBar: AppBar(
        title: Text(
          'أسعار "${widget.priceTierName}"',
          style: AppTextStyles.font18MediumText,
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<PriceTierPricesCubit, PriceTierPricesState>(
          listener: (context, state) {
            switch (state) {
              case PriceTierPricesActionSuccess(:final message):
                ShowToast(message: message, state: toastState.success);
              case PriceTierPricesActionError(:final message):
                ShowToast(message: message, state: toastState.error);
              default:
                break;
            }
          },
          buildWhen: (previous, current) =>
              current is! PriceTierPricesActionError &&
              current is! PriceTierPricesActionSuccess,
          builder: (context, state) {
            return switch (state) {
              PriceTierPricesLoaded(:final items, :final isBusy) =>
                _PricesList(
                  items: items,
                  isBusy: isBusy,
                  controllerFor: _controllerFor,
                  onSave: () {
                    final cubit = context.read<PriceTierPricesCubit>();
                    for (var i = 0; i < items.length; i++) {
                      final text = _controllerFor(items[i]).text.trim();
                      final price = text.isEmpty
                          ? 0.0
                          : double.tryParse(text) ?? items[i].price;
                      cubit.setPrice(i, price);
                    }
                    cubit.save();
                  },
                ),
              PriceTierPricesError(:final message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.font14RegularSecondary,
                  ),
                ),
              ),
              _ => const Center(child: CustomCircleProgressIndiacatorWidget()),
            };
          },
        ),
      ),
    );
  }
}

class _PricesList extends StatelessWidget {
  const _PricesList({
    required this.items,
    required this.isBusy,
    required this.controllerFor,
    required this.onSave,
  });

  final List<PriceTierPriceItem> items;
  final bool isBusy;
  final TextEditingController Function(PriceTierPriceItem item) controllerFor;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final contentWidth = isWide ? 560.0 : constraints.maxWidth;

        return Center(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 32 : 20,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'لا يوجد تعويضات لتسعيرها',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.font14RegularSecondary,
                            ),
                          )
                        else
                          ...items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      item.restorationTypeName,
                                      style: AppTextStyles.font14MediumText,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: AppTextFormField(
                                      controller: controllerFor(item),
                                      hintText: '0',
                                      validator: (_) => null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32 : 20,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: isBusy
                      ? const Center(
                          child: CustomCircleProgressIndiacatorWidget(),
                        )
                      : CustomButtonWidget(
                          onPressed: onSave,
                          buttonText: 'حفظ الأسعار',
                          textColor: Colors.white,
                          backgroundColor: AppColorsManger.primary,
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
