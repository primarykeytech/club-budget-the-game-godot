class_name SummaryModal
extends PanelContainer

signal summary_dismissed()

@onready var card: PanelContainer = $Card
@onready var reaction_label: Label = $Card/VBox/ReactionLabel
@onready var budget_delta_label: Label = $Card/VBox/StatsBox/VBox/BudgetDeltaLabel
@onready var morale_delta_label: Label = $Card/VBox/StatsBox/VBox/MoraleDeltaLabel
@onready var proceed_btn: Button = $Card/VBox/ProceedButton

func _ready() -> void:
	proceed_btn.pressed.connect(_on_proceed)

func open_summary(reaction_text: String, net_cash: float, effects: Dictionary, new_budget: float) -> void:
	reaction_label.text = "\"%s\"" % reaction_text

	var sign_str := "+" if net_cash >= 0.0 else ""
	budget_delta_label.text = "Net Cash: %s$%.2f  (Current Balance: $%.2f)" % [sign_str, net_cash, new_budget]
	if net_cash > 0.0:
		budget_delta_label.modulate = Color("#10b981")
	elif net_cash < 0.0:
		budget_delta_label.modulate = Color("#ef4444")
	else:
		budget_delta_label.modulate = Color("#94a3b8")

	var eff_parts: Array[String] = []
	for k in ["students", "coaches", "parents"]:
		var val: int = effects.get(k, 0)
		if val != 0:
			var prefix := "+" if val > 0 else ""
			eff_parts.append("%s %s%d" % [k.capitalize(), prefix, val])

	if eff_parts.is_empty():
		morale_delta_label.text = "Morale Impact: Neutral"
	else:
		morale_delta_label.text = "Morale Shifts: %s" % ", ".join(eff_parts)

	visible = true
	_animate_open()
	proceed_btn.grab_focus()

func _animate_open() -> void:
	if not is_inside_tree():
		return
	card.pivot_offset = card.size / 2.0
	card.scale = Vector2(0.85, 0.85)
	modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.18)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_proceed() -> void:
	visible = false
	summary_dismissed.emit()
