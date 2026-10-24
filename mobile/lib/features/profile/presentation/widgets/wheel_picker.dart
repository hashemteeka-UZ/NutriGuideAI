import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../format_number.dart';

class WheelPicker extends StatefulWidget {
  const WheelPicker({
    required this.itemCount,
    required this.selectedIndex,
    required this.labelForIndex,
    required this.onSelected,
    required this.semanticLabel,
    super.key,
  });

  final int itemCount;
  final int selectedIndex;
  final String Function(int index) labelForIndex;
  final ValueChanged<int> onSelected;
  final String semanticLabel;

  @override
  State<WheelPicker> createState() => _WheelPickerState();
}

class _WheelPickerState extends State<WheelPicker> {
  late FixedExtentScrollController _controller;
  var _accept = false;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(
      initialItem: _safe(widget.selectedIndex),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _accept = true;
    });
  }

  @override
  void didUpdateWidget(WheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _safe(widget.selectedIndex);
    if (oldWidget.itemCount != widget.itemCount) {
      _controller.jumpToItem(next);
      return;
    }
    if (next != _controller.selectedItem && next != oldWidget.selectedIndex) {
      _controller.jumpToItem(next);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSelected(int index) {
    if (!_accept || index == widget.selectedIndex) {
      return;
    }
    widget.onSelected(index);
  }

  int _safe(int index) {
    if (widget.itemCount <= 0) {
      return 0;
    }
    if (index < 0) {
      return 0;
    }
    if (index >= widget.itemCount) {
      return widget.itemCount - 1;
    }
    return index;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final numeric = colors.numeric;
    return Semantics(
      label: widget.semanticLabel,
      child: SizedBox(
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.line),
              ),
            ),
            ListWheelScrollView.useDelegate(
              controller: _controller,
              itemExtent: 44,
              diameterRatio: 1.6,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: _onSelected,
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: widget.itemCount,
                builder: (BuildContext context, int index) {
                  final selected = index == widget.selectedIndex;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.labelForIndex(index),
                          style: numeric.copyWith(
                            fontSize: selected ? 26 : 18,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected ? colors.brand : colors.fg3,
                          ),
                        ),
                      ),
                    ),
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

class NumberWheel extends StatelessWidget {
  const NumberWheel({
    required this.min,
    required this.max,
    required this.step,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.fractionDigits = 0,
    super.key,
  });

  final double min;
  final double max;
  final double step;
  final double value;
  final ValueChanged<double> onChanged;
  final String semanticLabel;
  final int fractionDigits;

  int get count => ((max - min) / step).round() + 1;

  @override
  Widget build(BuildContext context) {
    final index = (((value - min) / step).round()).clamp(0, count - 1);
    return WheelPicker(
      itemCount: count,
      selectedIndex: index,
      semanticLabel: semanticLabel,
      labelForIndex: (int item) {
        return formatCount(
          context,
          _valueAt(item),
          fractionDigits: fractionDigits,
        );
      },
      onSelected: (int item) => onChanged(_valueAt(item)),
    );
  }

  double _valueAt(int index) {
    final raw = min + index * step;
    if ((step - 0.5).abs() < 1e-9) {
      return (raw * 2).roundToDouble() / 2;
    }
    return raw.roundToDouble();
  }
}
