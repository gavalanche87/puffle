extends Area2D

@export var next_scene_path: String

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)
