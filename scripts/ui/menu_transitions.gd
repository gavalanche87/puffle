extends Control

var _scene_transitioning: bool = false

func _ready() -> void:
	modulate.a = 0.0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func go_to_scene(path: String) -> void:
	if _scene_transitioning:
		return
	_scene_transitioning = true
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t.finished
	get_tree().change_scene_to_file(path)
