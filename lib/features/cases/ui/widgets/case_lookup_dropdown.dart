import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

/// Full-width, boxed searchable lookup field used across the case form and
/// filter sheets — type to filter instead of scrolling a long dropdown
/// (doctor lists especially can get large). The suggestion list renders
/// inline right below the field (pushing the rest of the form down) rather
/// than as a floating overlay, so it can never be mispositioned regardless
/// of RTL layout or where the field sits on screen. Null [items] renders a
/// disabled field (while the lookup is loading).
class CaseLookupDropdown extends StatefulWidget {
  const CaseLookupDropdown({
    super.key,
    required this.value,
    required this.icon,
    required this.hintText,
    required this.items,
    required this.onChanged,
  });

  final String? value;
  final IconData icon;
  final String hintText;
  final List<DropdownMenuItem<String>>? items;
  final ValueChanged<String?> onChanged;

  @override
  State<CaseLookupDropdown> createState() => _CaseLookupDropdownState();
}

class _CaseLookupDropdownState extends State<CaseLookupDropdown> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<DropdownMenuItem<String>> _filtered = const [];

  @override
  void initState() {
    super.initState();
    _controller.text = _labelFor(widget.value);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant CaseLookupDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus &&
        (widget.value != oldWidget.value || widget.items != oldWidget.items)) {
      _controller.text = _labelFor(widget.value);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  static String _labelOf(DropdownMenuItem<String> item) {
    final child = item.child;
    return child is Text ? (child.data ?? '') : '';
  }

  String _labelFor(String? value) {
    if (value == null) return '';
    final items = widget.items ?? const [];
    for (final item in items) {
      if (item.value == value) return _labelOf(item);
    }
    return '';
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      setState(() => _filtered = widget.items ?? const []);
    } else {
      // Revert to the selected label if the field lost focus without a pick.
      setState(() => _controller.text = _labelFor(widget.value));
    }
  }

  void _onChangedText(String text) {
    final items = widget.items ?? const [];
    setState(() {
      _filtered = text.isEmpty
          ? items
          : items
              .where(
                (i) => _labelOf(i).toLowerCase().contains(text.toLowerCase()),
              )
              .toList();
    });
  }

  void _select(DropdownMenuItem<String> item) {
    _controller.text = _labelOf(item);
    _focusNode.unfocus();
    widget.onChanged(item.value);
  }

  void _clear() {
    setState(() {
      _controller.clear();
      _filtered = widget.items ?? const [];
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.items != null;
    final showSuggestions = _focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: enabled,
          onChanged: _onChangedText,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColorsManger.moreLightGray,
            prefixIcon: Icon(widget.icon, color: AppColorsManger.textSecondary),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _clear,
                  )
                : const Icon(
                    Icons.search,
                    color: AppColorsManger.textSecondary,
                  ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            hintText: widget.hintText,
            hintStyle: AppTextStyles.font14RegularSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (showSuggestions) ...[
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: AppColorsManger.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColorsManger.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: _filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'لا يوجد نتائج',
                      style: AppTextStyles.font14RegularSecondary,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final item = _filtered[index];
                      return InkWell(
                        onTap: () => _select(item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: DefaultTextStyle(
                            style: AppTextStyles.font14MediumText,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            child: item.child,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }
}
