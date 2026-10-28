import 'package:flutter/material.dart';

import 'portal_button_dock.dart';
import 'portal_form_stack.dart';
import 'portal_sheet.dart';
import 'portal_text_field.dart';

/// Daily calorie and macro goals: four numbers, "Save goals" on the dock, the
/// count over it when any is invalid, busy while saving.
///
/// Calories are whole kcal; the macros may be decimal. An emptied field is
/// valid and clears that goal (0 is "not set" in the app's model), so only a
/// non-number or a negative is an error. Presentational: the app maps its model
/// to these numbers and persists what [onSave] gets.
class PortalNutritionGoalsSheet extends StatefulWidget {
  const PortalNutritionGoalsSheet({
    super.key,
    required this.onSave,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.onClose,
  });

  /// The current goals; 0 is "not set" and shows an empty field.
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  /// Called once every field parses; the sheet is busy until it completes,
  /// then closes. A throw keeps it open with the failure on the dock.
  final Future<void> Function(
    int calories,
    double protein,
    double carbs,
    double fat,
  ) onSave;
  final VoidCallback? onClose;

  @override
  State<PortalNutritionGoalsSheet> createState() =>
      _PortalNutritionGoalsSheetState();
}

class _PortalNutritionGoalsSheetState extends State<PortalNutritionGoalsSheet> {
  static const _labels = ['Calories', 'Protein', 'Carbs', 'Fat'];

  // Keeps a decimal goal's decimals: 12.5 g must not reopen as 13.
  static String _text(num v) =>
      v <= 0 ? '' : (v == v.roundToDouble() ? '${v.round()}' : '$v');

  late final _fields = [
    for (final v in [widget.calories, widget.protein, widget.carbs, widget.fat])
      TextEditingController(text: _text(v)),
  ];
  Map<String, String> _errors = const {};
  bool _saving = false;
  String? _failed;

  @override
  void dispose() {
    for (final c in _fields) {
      c.dispose();
    }
    super.dispose();
  }

  /// Field [i] as a number: 0 when empty, null when it is not a valid goal.
  num? _parse(int i) {
    final t = _fields[i].text.trim();
    if (t.isEmpty) return 0;
    final n = i == 0 ? int.tryParse(t) : double.tryParse(t);
    return n == null || !n.isFinite || n < 0 ? null : n;
  }

  Future<void> _save() async {
    final errors = {
      for (var i = 0; i < _labels.length; i++)
        if (_parse(i) == null)
          _labels[i]: i == 0
              ? 'Enter whole calories, or leave it empty.'
              : 'Enter a number, or leave it empty.',
    };
    setState(() {
      _errors = errors;
      _failed = null;
    });
    if (errors.isNotEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(
        _parse(0)!.toInt(),
        _parse(1)!.toDouble(),
        _parse(2)!.toDouble(),
        _parse(3)!.toDouble(),
      );
      if (!mounted) return;
      (widget.onClose ?? () => Navigator.pop(context))();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _failed = "Couldn't save your goals. Try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget field(int i, String unit, String hint) => PortalTextField(
      label: _labels[i],
      controller: _fields[i],
      hint: hint,
      unit: unit,
      errorText: _errors[_labels[i]],
      enabled: !_saving,
      keyboardType: i == 0
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      textInputAction: i == 3 ? TextInputAction.done : TextInputAction.next,
    );
    return PortalSheetScaffold(
      title: 'Daily nutrition goals',
      onClose: widget.onClose ?? () => Navigator.pop(context),
      message:
          'Kept on this phone. Leave a field empty to track it without a goal.',
      dock: PortalButtonDock.save(
        label: 'Save goals',
        busyLabel: 'Saving goals',
        saving: _saving,
        errors: _errors.length,
        failed: _failed,
        onSave: _save,
      ),
      body: PortalFormStack(
        children: [
          field(0, 'kcal', '2000'),
          field(1, 'g', '120'),
          field(2, 'g', '250'),
          field(3, 'g', '70'),
        ],
      ),
    );
  }
}
