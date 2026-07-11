import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppDropdownItem<T> {
  const AppDropdownItem({required this.value, required this.label, this.enabled = true, this.tooltip});

  final T value;
  final String label;
  final bool enabled;
  final String? tooltip;
}

class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.leadingIcon,
    this.triggerPrefix,
    this.menuWidth = 240,
    this.expand = false,
  });

  final T value;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final IconData? leadingIcon;
  final String? triggerPrefix;
  final double menuWidth;
  final bool expand;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  final _controller = MenuController();

  Widget _menuItem(BuildContext context, AppDropdownItem<T> item) {
    final button = MenuItemButton(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 36)),
        fixedSize: WidgetStatePropertyAll(Size(widget.menuWidth, 36)),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10)),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled) ? context.c.mutedForeground : context.c.foreground),
        textStyle: const WidgetStatePropertyAll(TextStyle(fontFamily: 'Inter', fontSize: 14)),
        mouseCursor: WidgetStatePropertyAll(item.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
            return context.c.accent;
          }
          return Colors.transparent;
        }),
      ),
      onPressed: item.enabled ? () => widget.onChanged(item.value) : null,
      child: Row(
        children: [
          Expanded(
            child: Text(item.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: item.value == widget.value ? FontWeight.w600 : FontWeight.normal)),
          ),
          if (item.value == widget.value && item.enabled)
            Icon(Icons.check, size: 15, color: context.c.foreground),
        ],
      ),
    );
    if (item.tooltip == null) return button;
    return Tooltip(message: item.tooltip!, child: button);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.items.firstWhere(
      (i) => i.value == widget.value,
      orElse: () => widget.items.first,
    );
    final label = '${widget.triggerPrefix ?? ''}${selected.label}';

    return MenuAnchor(
      controller: _controller,
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(context.c.card),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: const WidgetStatePropertyAll(Color(0x22000000)),
        elevation: const WidgetStatePropertyAll(8),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(4)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: context.c.border),
          ),
        ),
      ),
      menuChildren: [for (final item in widget.items) _menuItem(context, item)],
      builder: (context, controller, child) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => controller.isOpen ? controller.close() : controller.open(),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: context.c.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.c.inputBorder),
              ),
              child: Row(
                mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  if (widget.leadingIcon != null) ...[
                    Icon(widget.leadingIcon, size: 16, color: context.c.mutedForeground),
                    const SizedBox(width: 8),
                  ],
                  if (widget.expand)
                    Expanded(
                      child: Text(label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, color: context.c.foreground)),
                    )
                  else
                    Text(label, style: TextStyle(fontSize: 14, color: context.c.foreground)),
                  const SizedBox(width: 8),
                  Icon(Icons.expand_more, size: 18, color: context.c.mutedForeground),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
