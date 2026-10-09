class_name FormulaEvaluator
extends RefCounted

## Evaluates math formulas from scenario and event definitions.
## Supports dynamic variable substitutions: students, students_x2, half_students.
static func evaluate(formula_variant: Variant, students_count: int) -> float:
	if formula_variant == null:
		return 0.0

	# If it's already a number
	if typeof(formula_variant) == TYPE_INT or typeof(formula_variant) == TYPE_FLOAT:
		return snappedf(float(formula_variant), 0.01)

	var formula_str: String = str(formula_variant).strip_edges()
	if formula_str.is_empty() or formula_str == "0":
		return 0.0

	# If formula_str is a pure number like "18.50" or "-45.00"
	if formula_str.is_valid_float() or formula_str.is_valid_int():
		return snappedf(float(formula_str), 0.01)

	var expr := Expression.new()
	var input_names := PackedStringArray(["students", "students_x2", "half_students"])
	var err := expr.parse(formula_str, input_names)
	if err != OK:
		push_warning("Formula parse error '%s': %s" % [formula_str, expr.get_error_text()])
		return 0.0

	var input_values: Array = [
		students_count,
		students_count * 2,
		int(students_count / 2.0)
	]

	var result: Variant = expr.execute(input_values)
	if expr.has_execute_failed():
		push_warning("Formula execution failed for '%s': %s" % [formula_str, expr.get_error_text()])
		return 0.0

	return snappedf(float(result), 0.01)
