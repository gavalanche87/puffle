extends Node2D

@onready var camera_manager: CameraBoundsManager = CameraBoundsManager.new()

func _ready() -> void:
	add_child(camera_manager)

	var player := get_node_or_null("World/Player")
	if not player:
		push_warning("%s: Player not found at World/Player" % [name])
		return

	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if not camera:
		push_warning("%s: Player Camera2D not found" % [name])
		return

	camera_manager.setup_camera_bounds(camera, player)
