class_name EventModal
extends PanelContainer

signal event_dismissed()

@onready var card: PanelContainer = $Card
@onready var title_label: Label = $Card/VBox/TitleLabel
@onready var description_label: Label = $Card/VBox/DescriptionLabel
@onready var cost_label: Label = $Card/VBox/ImpactRow/CostLabel
@onready var morale_label: Label = $Card/VBox/ImpactRow/MoraleLabel
@onready var dismiss_btn: Button = $Card/VBox/DismissButton

func _ready() -> void:
	dismiss_btn.pressed.connect(_on_dismiss)

func open_event(event: GameEvent) -> void:
	title_label.text = "⚡ %s" % event.title
	description_label.text = event.description

	if event.cost > 0.0:
		cost_label.text = "Financial Loss: -$%.2f" % event.cost
		cost_label.modulate = Color("#ef4444")
	elif event.cost < 0.0:
		cost_label.text = "Surprise Grant/Donation: +$%.2f" % absf(event.cost)
		cost_label.modulate = Color("#10b981")
	else:
		cost_label.text = "No direct financial cost"
		cost_label.modulate = Color("#94a3b8")

	var eff_parts: Array[String] = []
	for k in ["students", "coaches", "parents"]:
		var val: int = event.effects.get(k, 0)
		if val != 0:
			var prefix := "+" if val > 0 else ""
			eff_parts.append("%s %s%d" % [k.capitalize(), prefix, val])

	if eff_parts.is_empty():
		morale_label.text = "Morale unaffected"
	else:
		morale_label.text = "Morale shift: %s" % ", ".join(eff_parts)

	visible = true
	_animate_open()
	dismiss_btn.grab_focus()

func _animate_open() -> void:
	if not is_inside_tree():
		return
	card.pivot_offset = card.size / 2.0
	card.scale = Vector2(0.85, 0.85)
	modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.18)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_dismiss() -> void:
	visible = false
	event_dismissed.emit()
