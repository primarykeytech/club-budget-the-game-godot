class_name ClubState
extends RefCounted

var club_name: String = "Mathletes Club"
var initial_budget: float = 300.0
var budget: float = 300.0
var students_count: int = 16
var total_weeks: int = 12
var current_week: int = 1

var happiness: Dictionary = {
	"students": 72.0,
	"coaches": 72.0,
	"parents": 72.0
}

var history: Array[String] = []
var last_transaction_delta: float = 0.0
var last_effects_delta: Dictionary = {
	"students": 0,
	"coaches": 0,
	"parents": 0
}
var loss_reason: String = ""

func _init(
	p_name: String = "Mathletes Club",
	p_initial_budget: float = 300.0,
	p_students: int = 16,
	p_weeks: int = 12,
	p_starting_happiness: float = 72.0
) -> void:
	club_name = p_name.strip_edges() if not p_name.strip_edges().is_empty() else "Mathletes Club"
	initial_budget = float(p_initial_budget)
	budget = float(p_initial_budget)
	students_count = maxi(1, int(p_students))
	total_weeks = maxi(1, int(p_weeks))
	current_week = 1

	happiness = {
		"students": float(p_starting_happiness),
		"coaches": float(p_starting_happiness),
		"parents": float(p_starting_happiness)
	}
	history.clear()
	last_transaction_delta = 0.0
	last_effects_delta = {"students": 0, "coaches": 0, "parents": 0}
	loss_reason = ""

func evaluate_formula(formula_variant: Variant) -> float:
	return FormulaEvaluator.evaluate(formula_variant, students_count)

func format_text(template_text: String) -> String:
	var result := template_text
	result = result.replace("{club}", club_name)
	result = result.replace("{students}", str(students_count))
	result = result.replace("{students_x2}", str(students_count * 2))
	result = result.replace("{half_students}", str(int(students_count / 2.0)))
	result = result.replace("{budget}", "%.2f" % budget)
	result = result.replace("{week}", str(current_week))
	result = result.replace("{total_weeks}", str(total_weeks))
	return result

func apply_choice(choice: Choice, math_correct: Variant = null) -> Dictionary:
	var net_cash: float = choice.revenue - choice.cost
	var eff: Dictionary = choice.effects.duplicate()

	# Process math challenge bonus/penalty if applicable
	if choice.math_challenge != null and math_correct != null:
		if bool(math_correct):
			var bonus: int = choice.math_challenge.bonus_happiness
			eff["students"] = eff.get("students", 0) + int(bonus / 2.0)
			eff["coaches"] = eff.get("coaches", 0) + bonus
			eff["parents"] = eff.get("parents", 0) + int(bonus / 2.0)
		else:
			net_cash -= choice.math_challenge.penalty_cost
			eff["students"] = eff.get("students", 0) - 2
			eff["coaches"] = eff.get("coaches", 0) - 3

	budget = snappedf(budget + net_cash, 0.01)
	last_transaction_delta = net_cash

	for key in ["students", "coaches", "parents"]:
		var delta: int = eff.get(key, 0)
		var current_val: float = float(happiness.get(key, 0.0))
		happiness[key] = clampf(current_val + float(delta), 0.0, 100.0)

	last_effects_delta = eff
	var sign_str: String = "+" if net_cash >= 0.0 else ""
	history.append("Wk %d: Chose '%s' (Net %s$%.2f)" % [current_week, choice.text, sign_str, net_cash])

	return {
		"net_cash": net_cash,
		"effects": eff
	}

func apply_event(event: GameEvent) -> Dictionary:
	var net_cash: float = -snappedf(event.cost, 0.01)
	budget = snappedf(budget + net_cash, 0.01)
	last_transaction_delta = net_cash

	var eff: Dictionary = event.effects.duplicate()
	for key in ["students", "coaches", "parents"]:
		var delta: int = eff.get(key, 0)
		var current_val: float = float(happiness.get(key, 0.0))
		happiness[key] = clampf(current_val + float(delta), 0.0, 100.0)

	last_effects_delta = eff
	var sign_str: String = "+" if net_cash >= 0.0 else ""
	history.append("Wk %d Event: %s (%s$%.2f)" % [current_week, event.title, sign_str, net_cash])

	return {
		"net_cash": net_cash,
		"effects": eff
	}

func check_immediate_loss() -> Dictionary:
	if budget < 0.0:
		loss_reason = "Bankruptcy! The club ran out of money (Balance: $%.2f)." % budget
		return {"lost": true, "reason": loss_reason}

	var labels := {
		"students": "Student Mutiny! Students stopped attending (Happiness < 40%).",
		"coaches": "Coach Resigned! The coach was overwhelmed and burnt out (Happiness < 40%).",
		"parents": "Parent Boycott! Parents pulled their children from the club (Happiness < 40%)."
	}

	for role in ["students", "coaches", "parents"]:
		if float(happiness.get(role, 0.0)) < 40.0:
			loss_reason = labels.get(role, "%s satisfaction collapsed!" % role.capitalize())
			return {"lost": true, "reason": loss_reason}

	return {"lost": false, "reason": ""}

func is_season_finished() -> bool:
	return current_week > total_weeks

func check_victory() -> Dictionary:
	if not is_season_finished():
		return {"won": false, "message": "Season in progress."}

	var loss_status := check_immediate_loss()
	if loss_status.get("lost", false):
		return {"won": false, "message": loss_status.get("reason", "Season failed.")}

	var all_above_80 := true
	var low_stakeholders: Array[String] = []
	for role in ["students", "coaches", "parents"]:
		if float(happiness.get(role, 0.0)) < 80.0:
			all_above_80 = false
			low_stakeholders.append(role.capitalize())

	if all_above_80:
		return {
			"won": true,
			"message": "Gold Ribbon Season! Students, Coaches, and Parents are thrilled (all >= 80%)!"
		}

	return {
		"won": false,
		"message": "Season Ended, but failed to reach 80%% happiness for: %s." % ", ".join(low_stakeholders)
	}

func advance_week() -> void:
	current_week += 1
