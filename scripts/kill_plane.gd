extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	if not body.is_in_group("player"):
		return
	if body.has_method("respawn_from_kill_plane"):
		body.call_deferred("respawn_from_kill_plane", 30)
