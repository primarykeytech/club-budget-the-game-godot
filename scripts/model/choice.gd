class_name Choice
extends RefCounted

var id: String = ""
var text: String = ""
var cost: float = 0.0
var revenue: float = 0.0
var effects: Dictionary = {}
var reaction: String = ""
var math_challenge: MathChallenge = null

func _init(
	p_id: String = "",
	p_text: String = "",
	p_cost: float = 0.0,
	p_revenue: float = 0.0,
	p_effects: Dictionary = {},
	p_reaction: String = "",
	p_math_challenge: MathChallenge = null
) -> void:
	id = p_id
	text = p_text
	cost = p_cost
	revenue = p_revenue
	effects = p_effects.duplicate()
	reaction = p_reaction
	math_challenge = p_math_challenge
