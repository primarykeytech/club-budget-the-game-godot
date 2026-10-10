extends SceneTree

var passed_count := 0
var failed_count := 0

func _init() -> void:
	print("========================================")
	print("Running Club Budget GDScript Test Suite")
	print("========================================")

	run_test("test_initial_state", test_initial_state)
	run_test("test_formula_evaluation", test_formula_evaluation)
	run_test("test_apply_choice_deduction", test_apply_choice_deduction)
	run_test("test_math_challenge_bonus", test_math_challenge_bonus)
	run_test("test_math_challenge_penalty", test_math_challenge_penalty)
	run_test("test_immediate_loss_low_happiness", test_immediate_loss_low_happiness)
	run_test("test_immediate_loss_bankruptcy", test_immediate_loss_bankruptcy)
	run_test("test_victory_condition", test_victory_condition)
	run_test("test_end_season_missed_target", test_end_season_missed_target)
	run_test("test_scenario_manager_loading", test_scenario_manager_loading)
	run_test("test_start_season_shuffled_deck", test_start_season_shuffled_deck)
	run_test("test_season_deck_zero_repeats_up_to_max", test_season_deck_zero_repeats_up_to_max)
	run_test("test_events_deck_zero_repeats", test_events_deck_zero_repeats)
	run_test("test_all_28_scenarios_math_formulas_valid", test_all_28_scenarios_math_formulas_valid)
	run_test("test_text_formatting", test_text_formatting)

	print("========================================")
	print("Results: %d Passed, %d Failed" % [passed_count, failed_count])
	print("========================================")

	if failed_count == 0:
		quit(0)
	else:
		quit(1)

func run_test(test_name: String, test_callable: Callable) -> void:
	print("[RUN] %s" % test_name)
	var err = test_callable.call()
	if err == null or err == "":
		print("  -> PASS")
		passed_count += 1
	else:
		printerr("  -> FAIL: %s" % str(err))
		failed_count += 1

func assert_true(val: bool, msg: String = "Expected true") -> String:
	if not val:
		return msg
	return ""

func assert_false(val: bool, msg: String = "Expected false") -> String:
	if val:
		return msg
	return ""

func assert_eq(a: Variant, b: Variant, msg: String = "") -> String:
	if a != b:
		var err = "Expected %s to equal %s" % [str(a), str(b)]
		if not msg.is_empty():
			err += " (%s)" % msg
		return err
	return ""

func assert_approx(a: float, b: float, msg: String = "") -> String:
	if not is_equal_approx(a, b):
		var err = "Expected ~%s to equal ~%s" % [str(a), str(b)]
		if not msg.is_empty():
			err += " (%s)" % msg
		return err
	return ""

# -------------------------------------------------------------
# TEST CASES
# -------------------------------------------------------------

func test_initial_state() -> String:
	var state := ClubState.new("Alpha Math Club", 250.0, 16, 8, 75.0)
	var res: String
	res = assert_eq(state.club_name, "Alpha Math Club"); if res != "": return res
	res = assert_approx(state.budget, 250.0); if res != "": return res
	res = assert_eq(state.students_count, 16); if res != "": return res
	res = assert_eq(state.total_weeks, 8); if res != "": return res
	res = assert_eq(state.current_week, 1); if res != "": return res
	res = assert_approx(state.happiness["students"], 75.0); if res != "": return res
	res = assert_approx(state.happiness["coaches"], 75.0); if res != "": return res
	res = assert_approx(state.happiness["parents"], 75.0); if res != "": return res
	return ""

func test_formula_evaluation() -> String:
	var state := ClubState.new("Alpha Math Club", 250.0, 16, 8, 75.0)
	var res: String

	# 16 students * $0.25 = $4.00
	var val1 := state.evaluate_formula("0.25 * students")
	res = assert_approx(val1, 4.00); if res != "": return res

	# 16 students * $1.75 = $28.00
	var val2 := state.evaluate_formula("1.75 * students")
	res = assert_approx(val2, 28.00); if res != "": return res

	# Bake sale: (3.50 * 32) - 15 = 112 - 15 = 97.00
	var val3 := state.evaluate_formula("(3.50 * students * 2) - 15.00")
	res = assert_approx(val3, 97.00); if res != "": return res

	# Direct numbers
	res = assert_approx(state.evaluate_formula(25.50), 25.50); if res != "": return res
	res = assert_approx(state.evaluate_formula("18.50"), 18.50); if res != "": return res
	return ""

func test_apply_choice_deduction() -> String:
	var state := ClubState.new("Alpha Math Club", 250.0, 16, 8, 75.0)
	var choice := Choice.new(
		"test_pencils",
		"Buy Pencils",
		20.0,
		0.0,
		{"students": 5, "coaches": 2, "parents": -1},
		"Pencils bought!"
	)
	var outcome := state.apply_choice(choice)
	var res: String
	res = assert_approx(outcome["net_cash"], -20.0); if res != "": return res
	res = assert_approx(state.budget, 230.0); if res != "": return res
	res = assert_approx(state.happiness["students"], 80.0); if res != "": return res
	res = assert_approx(state.happiness["coaches"], 77.0); if res != "": return res
	res = assert_approx(state.happiness["parents"], 74.0); if res != "": return res
	return ""

func test_math_challenge_bonus() -> String:
	var state := ClubState.new("Alpha Math Club", 250.0, 16, 8, 75.0)
	var challenge := MathChallenge.new(
		"decimal_mult",
		"16 * 0.25",
		4.0,
		"$",
		[4.0, 5.0, 6.0, 7.0],
		6,
		2.0
	)
	var choice := Choice.new(
		"test_math",
		"Math Option",
		4.0,
		0.0,
		{"students": 0, "coaches": 0, "parents": 0},
		"Good job",
		challenge
	)
	state.apply_choice(choice, true)
	if state.happiness["coaches"] <= 75.0:
		return "Expected coach happiness to exceed 75.0"
	return ""

func test_math_challenge_penalty() -> String:
	var state := ClubState.new("Alpha Math Club", 250.0, 16, 8, 75.0)
	var challenge := MathChallenge.new(
		"decimal_mult",
		"16 * 0.25",
		4.0,
		"$",
		[4.0, 5.0, 6.0, 7.0],
		6,
		5.0
	)
	var choice := Choice.new(
		"test_math",
		"Math Option",
		4.0,
		0.0,
		{"students": 0, "coaches": 0, "parents": 0},
		"Oops",
		challenge
	)
	var initial_budget := state.budget
	state.apply_choice(choice, false)
	return assert_approx(state.budget, initial_budget - 4.0 - 5.0)

func test_immediate_loss_low_happiness() -> String:
	var state := ClubState.new("Alpha Math Club", 250.0, 16, 8, 75.0)

	# Student drop below 40
	state.happiness["students"] = 38.0
	var check1 := state.check_immediate_loss()
	if not check1["lost"] or not check1["reason"].contains("Student Mutiny"):
		return "Expected Student Mutiny loss"

	# Coach drop below 40
	state.happiness["students"] = 70.0
	state.happiness["coaches"] = 35.0
	var check2 := state.check_immediate_loss()
	if not check2["lost"] or not check2["reason"].contains("Coach Resigned"):
		return "Expected Coach Resigned loss"

	# Parent drop below 40
	state.happiness["coaches"] = 70.0
	state.happiness["parents"] = 39.5
	var check3 := state.check_immediate_loss()
	if not check3["lost"] or not check3["reason"].contains("Parent Boycott"):
		return "Expected Parent Boycott loss"

	return ""

func test_immediate_loss_bankruptcy() -> String:
	var state := ClubState.new("Alpha Math Club", 250.0, 16, 8, 75.0)
	state.budget = -5.0
	var check := state.check_immediate_loss()
	if not check["lost"] or not check["reason"].contains("Bankruptcy"):
		return "Expected Bankruptcy loss"
	return ""

func test_victory_condition() -> String:
	var state := ClubState.new("Alpha Math Club", 250.0, 16, 8, 75.0)
	state.current_week = 9
	state.happiness["students"] = 82.0
	state.happiness["coaches"] = 85.0
	state.happiness["parents"] = 80.0
	var check := state.check_victory()
	if not check["won"] or not check["message"].contains("Gold Ribbon Season"):
		return "Expected Gold Ribbon victory"
	return ""

func test_end_season_missed_target() -> String:
	var state := ClubState.new("Alpha Math Club", 250.0, 16, 8, 75.0)
	state.current_week = 9
	state.happiness["students"] = 85.0
	state.happiness["coaches"] = 78.0
	state.happiness["parents"] = 85.0
	var check := state.check_victory()
	if check["won"] or not check["message"].contains("Coaches"):
		return "Expected loss due to Coaches below 80%"
	return ""

func test_scenario_manager_loading() -> String:
	var sm := ScenarioManager.new("res://data/scenarios.json", "res://data/events.json")
	if sm.scenarios_raw.size() == 0:
		return "scenarios_raw is empty"
	if sm.events_raw.size() == 0:
		return "events_raw is empty"

	var state := ClubState.new("Alpha Math Club", 250.0, 16, 8, 75.0)
	var scen := sm.get_scenario_for_week(1, state)
	if scen.title.is_empty():
		return "Scenario title is empty"
	if scen.choices.size() <= 1:
		return "Scenario has insufficient choices"

	for c in scen.choices:
		if c.math_challenge != null:
			if c.math_challenge.options.size() != 4:
				return "Expected 4 options in math challenge, got %d" % c.math_challenge.options.size()
			var found_ans := false
			for opt in c.math_challenge.options:
				if is_equal_approx(opt, c.math_challenge.answer):
					found_ans = true
					break
			if not found_ans:
				return "Answer %.2f not found in options" % c.math_challenge.answer
	return ""

func test_start_season_shuffled_deck() -> String:
	var sm := ScenarioManager.new("res://data/scenarios.json", "res://data/events.json")
	sm.start_season(12, true)

	if sm.season_deck.size() != 12:
		return "Expected deck size 12, got %d" % sm.season_deck.size()

	if sm.season_deck[0]["id"] != "pencils_shortage":
		return "Expected week 1 to be pencils_shortage, got %s" % sm.season_deck[0]["id"]

	var subsequent_ids: Array = []
	for i in range(1, 8):
		subsequent_ids.append(sm.season_deck[i]["id"])

	if subsequent_ids.has("pencils_shortage"):
		return "pencils_shortage repeated unexpectedly in weeks 2-8"

	# Check uniqueness in first cycle
	var unique_set: Dictionary = {}
	for id in subsequent_ids:
		unique_set[id] = true
	if unique_set.size() != subsequent_ids.size():
		return "Duplicate scenarios found in single cycle"

	return ""

func test_season_deck_zero_repeats_up_to_max() -> String:
	var sm := ScenarioManager.new("res://data/scenarios.json", "res://data/events.json")
	var total_unique := sm.scenarios_raw.size()
	if total_unique < 28:
		return "Expected at least 28 unique scenarios in JSON, found %d" % total_unique

	sm.start_season(total_unique, true)
	if sm.season_deck.size() != total_unique:
		return "Expected season deck size %d, got %d" % [total_unique, sm.season_deck.size()]

	var seen_ids: Dictionary = {}
	for i in range(sm.season_deck.size()):
		var id: String = sm.season_deck[i]["id"]
		if seen_ids.has(id):
			return "Scenario ID '%s' repeated at week index %d (previously seen at week %d)" % [id, i + 1, seen_ids[id] + 1]
		seen_ids[id] = i

	return ""

func test_events_deck_zero_repeats() -> String:
	var sm := ScenarioManager.new("res://data/scenarios.json", "res://data/events.json")
	var state := ClubState.new("Alpha Math Club", 250.0, 16, 28, 75.0)
	sm.start_season(28, true)

	var triggered_event_ids: Array[String] = []
	for week in range(1, 29):
		var evt := sm.get_event_if_triggered(week, state)
		if evt != null:
			if triggered_event_ids.has(evt.id):
				return "Event ID '%s' repeated unexpectedly at week %d" % [evt.id, week]
			triggered_event_ids.append(evt.id)

	if triggered_event_ids.size() < 8:
		return "Expected at least 8 unique events across 28 weeks, triggered %d" % triggered_event_ids.size()

	return ""

func test_all_28_scenarios_math_formulas_valid() -> String:
	var sm := ScenarioManager.new("res://data/scenarios.json", "res://data/events.json")
	if sm.scenarios_raw.size() < 28:
		return "Expected at least 28 scenarios, found %d" % sm.scenarios_raw.size()

	var test_roster_sizes := [10, 16, 24]
	for students in test_roster_sizes:
		var state := ClubState.new("Test Club", 500.0, students, 28, 75.0)
		for s_idx in range(sm.scenarios_raw.size()):
			var raw_dict: Dictionary = sm.scenarios_raw[s_idx]
			for c_raw in raw_dict.get("choices", []):
				var cost_val := state.evaluate_formula(c_raw.get("cost_formula", "0"))
				if cost_val < 0.0 and not c_raw.has("revenue_formula"):
					return "Cost formula evaluated negative in scenario %s" % raw_dict["id"]

				if c_raw.has("math_challenge") and c_raw["math_challenge"] != null:
					var mc: Dictionary = c_raw["math_challenge"]
					var ans_val := state.evaluate_formula(mc.get("answer_formula", "0"))
					var prompt_str := state.format_text(mc.get("prompt", ""))
					if prompt_str.is_empty():
						return "Empty math challenge prompt in scenario %s" % raw_dict["id"]
					if ans_val < 0.0:
						return "Math challenge answer is negative in scenario %s" % raw_dict["id"]

					var opts := sm._generate_math_options(ans_val)
					if opts.size() != 4:
						return "Expected 4 math options in scenario %s, got %d" % [raw_dict["id"], opts.size()]

					var found := false
					for o in opts:
						if is_equal_approx(o, ans_val):
							found = true
							break
					if not found:
						return "Correct answer %.2f missing from generated options in scenario %s" % [ans_val, raw_dict["id"]]

	return ""

func test_text_formatting() -> String:
	var state := ClubState.new("Mathletes", 300.50, 16, 10, 75.0)
	state.current_week = 3
	var template := "Welcome to {club}! We have {students} students ({half_students} half). Budget: ${budget}. Week {week}/{total_weeks}."
	var formatted := state.format_text(template)
	var expected := "Welcome to Mathletes! We have 16 students (8 half). Budget: $300.50. Week 3/10."
	return assert_eq(formatted, expected)
