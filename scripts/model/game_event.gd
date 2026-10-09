class_name GameEvent
extends RefCounted

var id: String = ""
var title: String = ""
var description: String = ""
var cost: float = 0.0
var effects: Dictionary = {}

func _init(
	p_id: String = "",
	p_title: String = "",
	p_description: String = "",
	p_cost: float = 0.0,
	p_effects: Dictionary = {}
) -> void:
	id = p_id
	title = p_title
	description = p_description
	cost = p_cost
	effects = p_effects.duplicate()
