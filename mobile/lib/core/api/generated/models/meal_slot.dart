// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum MealSlot {
  @JsonValue('BREAKFAST')
  breakfast('BREAKFAST'),
  @JsonValue('LUNCH')
  lunch('LUNCH'),
  @JsonValue('DINNER')
  dinner('DINNER'),
  @JsonValue('SNACK')
  snack('SNACK'),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const MealSlot(this.json);

  factory MealSlot.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;
  String toJson() {
    final value = json;
    if (value == null) {
      throw StateError('Cannot convert enum value with null JSON representation to String. '
          'This usually happens for \$unknown or @JsonValue(null) entries.');
    }
    return value as String;
  }

  @override
  String toString() => json?.toString() ?? super.toString();
  /// Returns all defined enum values excluding the $unknown value.
  static List<MealSlot> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
