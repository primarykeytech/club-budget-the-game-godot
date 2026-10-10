class_name ScenarioManager
extends RefCounted

var scenarios_path: String = ""
var events_path: String = ""
var scenarios_raw: Array = []
var events_raw: Array = []
var season_deck: Array = []
var event_deck: Array = []

func _init(p_scenarios_path: String = "res://data/scenarios.json", p_events_path: String = "res://data/events.json") -> void:
	scenarios_path = p_scenarios_path
	events_path = p_events_path
	load_data()

func load_data() -> void:
	scenarios_raw = _load_json_file(scenarios_path)
	events_raw = _load_json_file(events_path)

func _load_json_file(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("JSON file does not exist: %s" % path)
		return []

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open JSON file: %s" % path)
		return []

	var content := file.get_as_text()
	var json_data: Variant = JSON.parse_string(content)
	if typeof(json_data) != TYPE_ARRAY:
		push_error("Expected JSON array in %s, got %s" % [path, typeof(json_data)])
		return []

	return json_data as Array

func start_season(total_weeks: int, keep_starter_week1: bool = true) -> void:
	if scenarios_raw.is_empty():
		season_deck = []
		return

	# Reset and shuffle events deck for strict non-repeating events
	event_deck = events_raw.duplicate()
	event_deck.shuffle()

	if keep_starter_week1:
		var starter: Dictionary = scenarios_raw[0]
		var pool: Array = scenarios_raw.slice(1)
		pool.shuffle()
		var deck: Array = [starter]
		var needed := mini(pool.size(), total_weeks - 1)
		deck.append_array(pool.slice(0, needed))

		# In case total_weeks exceeds available pool size, cycle without immediate adjacent repeats
		var remaining := total_weeks - deck.size()
		while remaining > 0:
			var extra: Array = scenarios_raw.duplicate()
			extra.shuffle()
			var add_count := mini(extra.size(), remaining)
			deck.append_array(extra.slice(0, add_count))
			remaining -= add_count

		season_deck = deck.slice(0, total_weeks)
	else:
		var pool: Array = scenarios_raw.duplicate()
		pool.shuffle()
		var deck: Array = pool.slice(0, mini(pool.size(), total_weeks))

		var remaining := total_weeks - deck.size()
		while remaining > 0:
			var extra: Array = scenarios_raw.duplicate()
			extra.shuffle()
			var add_count := mini(extra.size(), remaining)
			deck.append_array(extra.slice(0, add_count))
			remaining -= add_count

		season_deck = deck.slice(0, total_weeks)

func get_scenario_for_week(week_num: int, state: ClubState) -> Scenario:
	if season_deck.is_empty() or season_deck.size() < state.total_weeks:
		start_season(state.total_weeks)

	var raw: Dictionary = {}
	if week_num - 1 >= 0 and week_num - 1 < season_deck.size():
		raw = season_deck[week_num - 1]
	elif not scenarios_raw.is_empty():
		raw = scenarios_raw[(week_num - 1) % scenarios_raw.size()]
	else:
		raw = {
			"id": "generic",
			"title": "Weekly Planning",
			"speaker": "Coach",
			"description": "How should we organize this week's activities?",
			"choices": []
		}

	var choices: Array[Choice] = []
	var raw_choices: Array = raw.get("choices", [])
	for raw_c in raw_choices:
		var cost := state.evaluate_formula(raw_c.get("cost_formula", "0"))
		var rev := state.evaluate_formula(raw_c.get("revenue_formula", "0"))

		var math_challenge: MathChallenge = null
		if raw_c.has("math_challenge") and raw_c["math_challenge"] != null:
			var mc_raw: Dictionary = raw_c["math_challenge"]
			var ans := state.evaluate_formula(mc_raw.get("answer_formula", "0"))
			var prompt := state.format_text(mc_raw.get("prompt", ""))
			var options := _generate_math_options(ans)

			math_challenge = MathChallenge.new(
				mc_raw.get("type", "calc"),
				prompt,
				ans,
				mc_raw.get("unit", "$"),
				options,
				int(mc_raw.get("bonus_happiness", 5)),
				float(mc_raw.get("penalty_cost", 0.0))
			)

		choices.append(
			Choice.new(
				raw_c.get("id", "opt"),
				state.format_text(raw_c.get("text", "")),
				cost,
				rev,
				raw_c.get("effects", {}),
				state.format_text(raw_c.get("reaction", "")),
				math_challenge
			)
		)

	return Scenario.new(
		raw.get("id", "scen"),
		state.format_text(raw.get("title", "")),
		raw.get("speaker", "Coach"),
		state.format_text(raw.get("description", "")),
		choices
	)

func get_event_if_triggered(week_num: int, state: ClubState) -> GameEvent:
	# Periodic unexpected event on weeks 3, 6, 9, 12, etc.
	if week_num > 1 and week_num % 3 == 0 and not events_raw.is_empty():
		if event_deck.is_empty():
			event_deck = events_raw.duplicate()
			event_deck.shuffle()

		var raw: Dictionary = event_deck.pop_front()
		var cost_formula: Variant = raw.get("cost_formula", raw.get("cost", 0))
		var cost := state.evaluate_formula(cost_formula)

		return GameEvent.new(
			raw.get("id", "event"),
			state.format_text(raw.get("title", "")),
			state.format_text(raw.get("description", "")),
			cost,
			raw.get("effects", {})
		)
	return null

func _generate_math_options(correct_ans: float) -> Array[float]:
	var opts: Array[float] = [correct_ans]

	var delta_choices: Array[float] = [2.0, 5.0, 10.0, 0.50, 1.50]
	var sub_choices: Array[float] = [2.0, 4.0, 5.0, 0.50]
	var mult_choices: Array[float] = [0.8, 1.2, 1.5]

	var deltas: Array[float] = [
		snappedf(correct_ans + delta_choices.pick_random(), 0.01),
		snappedf(maxf(0.0, correct_ans - sub_choices.pick_random()), 0.01),
		snappedf(correct_ans * mult_choices.pick_random(), 0.01),
		snappedf(correct_ans + 10.0, 0.01)
	]

	for d in deltas:
		if not _float_in_array(d, opts) and d >= 0.0:
			opts.append(d)
		if opts.size() >= 4:
			break

	while opts.size() < 4:
		var fake := snappedf(maxf(0.0, correct_ans + float(opts.size()) * 3.5), 0.01)
		if not _float_in_array(fake, opts):
			opts.append(fake)
		else:
			opts.append(snappedf(fake + 1.0, 0.01))

	opts.shuffle()
	return opts

func _float_in_array(val: float, arr: Array[float]) -> bool:
	for item in arr:
		if is_equal_approx(item, val):
			return true
	return false
