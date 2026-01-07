import 'package:flutter/material.dart';
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/widgets/form_fields_label.dart';
import 'package:offroad_nav/design/widgets/pill_nav_row.dart';

typedef PillItemTitle<T> = String Function(T item);
typedef PillItemId<T> = String Function(T item);

class PillPicker<T> extends StatelessWidget {
  //final String label;
  final String placeholder;

  final T? selected;
  final List<T> items;

  final PillItemTitle<T> titleOf;
  final PillItemId<T> idOf;

  final ValueChanged<T> onSelect;

  final Widget? leadingIcon;
  final String sheetTitle;
  final bool searchable;

  final String Function(T)? subtitleOf;

  const PillPicker({
    super.key,
    //required this.label,
    required this.placeholder,
    required this.items,
    required this.titleOf,
    required this.idOf,
    required this.onSelect,
    this.selected,
    this.leadingIcon,
    this.sheetTitle = 'Select',
    this.searchable = true, 
    this.subtitleOf,
  });

  @override
  Widget build(BuildContext context) {
    final text = selected != null ? titleOf(selected as T) : placeholder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //FormFieldLabel(label),
          // const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: items.isEmpty ? null : () => _openSheet(context),
          child: PillBox(
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  leadingIcon!,
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected == null ? textHintColor : textMainColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, color: textHintColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    final picked = await showModalBottomSheet<T>(
      context: context,
      backgroundColor: surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PillPickerSheet<T>(
        title: sheetTitle,
        items: items,
        selectedId: selected == null ? null : idOf(selected as T),
        titleOf: titleOf,
        idOf: idOf,
        searchable: searchable,
        subtitleOf: subtitleOf,
      ),
    );

    if (picked != null) onSelect(picked);
  }
}

class _PillPickerSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String? selectedId;

  final PillItemTitle<T> titleOf;
  final PillItemId<T> idOf;

  final bool searchable;
  final String Function(T)? subtitleOf;


  const _PillPickerSheet({
    required this.title,
    required this.items,
    required this.selectedId,
    required this.titleOf,
    required this.idOf,
    required this.searchable, 
    this.subtitleOf,
  });

  @override
  State<_PillPickerSheet<T>> createState() => _PillPickerSheetState<T>();
}

class _PillPickerSheetState<T> extends State<_PillPickerSheet<T>> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items.where((item) {
      if (!widget.searchable || _q.isEmpty) return true;
      return widget
          .titleOf(item)
          .toLowerCase()
          .contains(_q.toLowerCase());
    }).toList();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFD0D0D6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48), // баланс справа
              ],
            ),
            const SizedBox(height: 12),

            if (widget.searchable) ...[
              SizedBox(
                height: 50,
                child: TextField(
                  controller: _ctrl,
                  onChanged: (v) => setState(() => _q = v),
                  decoration: pillInputDecoration('Search...').copyWith(
                    prefixIcon:
                        const Icon(Icons.search_rounded, color: textHintColor),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final item = items[i];
                  final isSelected =
                      widget.idOf(item) == widget.selectedId;

                  return PillNavRow(
                    title: widget.titleOf(item),
                    leading: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: isSelected
                          ? buttonSecondBackgroundColor
                          : textHintColor,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: textHintColor,
                    ),
                    onTap: () => Navigator.pop(context, item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
