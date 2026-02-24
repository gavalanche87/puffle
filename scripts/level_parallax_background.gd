extends CanvasLayer

@export var sky_speed: float = 0.012
@export var clouds_speed: float = 0.028
@export var hills_speed: float = 0.05
@export var ground_speed: float = 0.085
@export var sky_vertical_speed: float = 0.004
@export var clouds_vertical_speed: float = 0.008
@export var hills_vertical_speed: float = 0.016
@export var ground_vertical_speed: float = 0.024

@onready var sky_a: Sprite2D = $SkyA
@onready var sky_b: Sprite2D = $SkyB
@onready var clouds_a: Sprite2D = $CloudsA
@onready var clouds_b: Sprite2D = $CloudsB
@onready var hills_a: Sprite2D = $HillsA
@onready var hills_b: Sprite2D = $HillsB
@onready var ground_a: Sprite2D = $GroundA
@onready var ground_b: Sprite2D = $GroundB

var _last_camera_x: float = INF
var _last_camera_y: float = INF

func _ready() -> void:
	layer = -10
	_setup_layer_tiles()
	_update_parallax()

func _process(_delta: float) -> void:
	var camera_x: float = _get_camera_world_x()
	var camera_y: float = _get_camera_world_y()
	if is_equal_approx(camera_x, _last_camera_x) and is_equal_approx(camera_y, _last_camera_y):
		return
	_update_parallax_from_camera(camera_x, camera_y)

func _setup_layer_tiles() -> void:
	# 320x180 layers are scaled to 640x360 (2x) to match the game's viewport.
	_setup_pair(sky_a, sky_b, 640.0, 0.0)
	_setup_pair(clouds_a, clouds_b, 640.0, 0.0)
	_setup_pair(hills_a, hills_b, 640.0, 0.0)
	# 360x84 -> 720x168 at 2x, aligned to screen bottom.
	_setup_pair(ground_a, ground_b, 720.0, 192.0)

func _setup_pair(a: Sprite2D, b: Sprite2D, tile_width: float, y_pos: float) -> void:
	if a == null or b == null:
		return
	a.centered = false
	b.centered = false
	a.position = Vector2(0.0, y_pos)
	b.position = Vector2(tile_width, y_pos)

func _update_parallax() -> void:
	_update_parallax_from_camera(_get_camera_world_x(), _get_camera_world_y())

func _update_parallax_from_camera(camera_x: float, camera_y: float) -> void:
	_last_camera_x = camera_x
	_last_camera_y = camera_y
	_scroll_pair(sky_a, sky_b, 640.0, 0.0, sky_speed, 0.0, camera_x, camera_y)
	_scroll_pair(clouds_a, clouds_b, 640.0, 0.0, clouds_speed, 0.0, camera_x, camera_y)
	_scroll_pair(hills_a, hills_b, 640.0, 0.0, hills_speed, hills_vertical_speed, camera_x, camera_y)
	_scroll_pair(ground_a, ground_b, 720.0, 192.0, ground_speed, ground_vertical_speed, camera_x, camera_y)

func _scroll_pair(a: Sprite2D, b: Sprite2D, tile_width: float, base_y: float, x_speed: float, y_speed: float, camera_x: float, camera_y: float) -> void:
	if a == null or b == null:
		return
	var scroll_x: float = fposmod(-camera_x * x_speed, tile_width)
	var y_offset: float = -camera_y * y_speed
	# Never let parallax layers rise above their authored base line, or the sky can show through at screen bottom.
	if y_speed > 0.0:
		y_offset = maxf(0.0, y_offset)
	a.position.x = scroll_x - tile_width
	b.position.x = scroll_x
	a.position.y = base_y + y_offset
	b.position.y = base_y + y_offset

func _get_camera_world_x() -> float:
	var viewport := get_viewport()
	if viewport:
		var cam := viewport.get_camera_2d()
		if cam:
			return cam.get_screen_center_position().x
	return _last_camera_x if _last_camera_x != INF else 0.0

func _get_camera_world_y() -> float:
	var viewport := get_viewport()
	if viewport:
		var cam := viewport.get_camera_2d()
		if cam:
			return cam.get_screen_center_position().y
	return _last_camera_y if _last_camera_y != INF else 0.0
