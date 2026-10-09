class_name ScenarioPanel
extends PanelContainer

signal choice_selected(index: int)

@onready var title_label: Label = $VBox/Header/TitleLabel
@onready var speaker_label: Label = $VBox/Header/SpeakerLabel
@onready var description_label: Label = $VBox/DescriptionLabel
@onready var choices_container: VBoxContainer = $VBox/ChoicesContainer

var current_scenario: Scenario = null

func display_scenario(scenario: Scenario) -> void:
	current_scenario = scenario
	title_label.text = scenario.title
	speaker_label.text = "%s presents this week's situation:" % scenario.speaker
	description_label.text = scenario.description

	# Clear old buttons
	for child in choices_container.get_children():
		child.queue_free()

	for i in range(scenario.choices.size()):
		var choice: Choice = scenario.choices[i]
		var card := _create_choice_card(i, choice)
		choices_container.add_child(card)

func _create_choice_card(index: int, choice: Choice) -> PanelContainer:
	var panel := PanelContainer.new()
	var box_style := StyleBoxFlat.new()
	box_style.set_content_margin_all(10.0)
	box_style.bg_color = Color(0.09, 0.14, 0.22, 0.95)
	box_style.border_color = Color(0.25, 0.35, 0.48, 1.0)
	box_style.set_border_width_all(1)
	box_style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", box_style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	panel.add_child(hbox)

	# Main action button
	var btn := Button.new()
	btn.text = choice.text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.pressed.connect(func(): choice_selected.emit(index))
	hbox.add_child(btn)

	# Financial tag
	var net_cost := choice.revenue - choice.cost
	var cost_label := Label.new()
	cost_label.custom_minimum_size = Vector2(90, 0)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if net_cost > 0.0:
		cost_label.text = "+$%.2f" % net_cost
		cost_label.modulate = Color("#10b981")
	elif net_cost < 0.0:
		cost_label.text = "-$%.2f" % absf(net_cost)
		cost_label.modulate = Color("#f87171")
	else:
		cost_label.text = "$0.00"
		cost_label.modulate = Color("#94a3b8")
	hbox.add_child(cost_label)

	# Morale summary badges
	var effects_label := Label.new()
	effects_label.custom_minimum_size = Vector2(210, 0)
	effects_label.add_theme_font_size_override("font_size", 12)
	var eff_parts: Array[String] = []
	for k in ["students", "coaches", "parents"]:
		var val: int = choice.effects.get(k, 0)
		if val != 0:
			var prefix := "+" if val > 0 else ""
			eff_parts.append("%s %s%d" % [k.substr(0, 3).to_upper(), prefix, val])
	if eff_parts.is_empty():
		effects_label.text = "No direct morale shift"
		effects_label.modulate = Color("#94a3b8")
	else:
		effects_label.text = " | ".join(eff_parts)
		effects_label.modulate = Color("#e2e8f0")
	hbox.add_child(effects_label)

	# Math icon if math challenge is attached
	if choice.math_challenge != null:
		var math_badge := Label.new()
		math_badge.text = "📐 Math Challenge!"
		math_badge.modulate = Color("#38bdf8")
		math_badge.add_theme_font_size_override("font_size", 12)
		hbox.add_child(math_badge)

	return panel
