class_name FloatingIndicator
extends Label

## Spawns an animated floating delta label that floats upward and fades out.
static func spawn(parent: Node, text: String, color: Color, start_pos: Vector2, font_size: int = 16) -> FloatingIndicator:
	var indicator := FloatingIndicator.new()
	indicator.text = text
	indicator.modulate = color
	indicator.position = start_pos
	indicator.add_theme_font_size_override("font_size", font_size)
	indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	indicator.top_level = false
	parent.add_child(indicator)

	var tween := indicator.create_tween().set_parallel(true)
	tween.tween_property(indicator, "position:y", start_pos.y - 36.0, 0.95).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(indicator, "modulate:a", 0.0, 0.85).set_delay(0.25)
	tween.chain().tween_callback(indicator.queue_free)
	return indicator
