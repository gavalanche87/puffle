extends Area2D

@export var next_scene_path: String

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not (body is CharacterBody2D):
		return
	var game_data := get_node_or_null("/root/GameData")
	if game_data and game_data.has_method("complete_current_level"):
		game_data.call("complete_current_level")
	if game_data and game_data.has_method("is_level_flow_active") and game_data.call("is_level_flow_active"):
		game_data.call("exit_level_flow")
		get_tree().change_scene_to_file("res://scenes/ui/LevelSelect.tscn")
		return
	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)
