/// Searchable Dropdown Widget
/// 
/// A dropdown with a search/filter text field.
/// Used for vendor and item selection in forms.

import 'package:flutter/material.dart';

class SearchableDropdown<T extends Object> extends StatefulWidget {
  final String label;
  final String hintText;
  final List<T> items;
  final String Function(T) displayStringFor;
  final ValueChanged<T?> onChanged;
  final T? value;
  final Future<List<T>> Function(String query)? onSearch;

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.hintText,
    required this.items,
    required this.displayStringFor,
    required this.onChanged,
    this.value,
    this.onSearch,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T extends Object> extends State<SearchableDropdown<T>> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Autocomplete<T>(
          displayStringForOption: widget.displayStringFor,
          optionsBuilder: (textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return widget.items;
            }
            // Use server-side search if provided, otherwise filter locally
            if (widget.onSearch != null) {
              return await widget.onSearch!(textEditingValue.text);
            }
            return widget.items.where((item) {
              return widget
                  .displayStringFor(item)
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: widget.onChanged,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            // Set initial value if provided
            if (widget.value != null && controller.text.isEmpty) {
              controller.text = widget.displayStringFor(widget.value as T);
            }
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: widget.hintText,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          widget.onChanged(null);
                        },
                      )
                    : null,
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(widget.displayStringFor(option)),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
