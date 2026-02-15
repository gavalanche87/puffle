extends Node2D

@onready var camera_manager: CameraBoundsManager = CameraBoundsManager.new()

func _ready() -> void:
	# Add camera manager as child so it has access to scene tree
	add_child(camera_manager)
	
	var player = get_node_or_null("World/Player")
	if not player:
		push_warning("Level_1: Player not found")
		return
		
	var camera = player.get_node_or_null("Camera2D")
	if not camera:
		push_warning("Level_1: Player Camera2D not found")
		return
	
	# Setup camera bounds using the manager
	camera_manager.setup_camera_bounds(camera, player)
