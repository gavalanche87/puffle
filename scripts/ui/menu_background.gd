extends Control

@export var clouds_scroll_speed: float = 14.0

@onready var sky: TextureRect = $Sky
@onready var clouds_a: TextureRect = $CloudsA
@onready var clouds_b: TextureRect = $CloudsB

var _cloud_tile_width: float = 0.0
var _cloud_scale: float = 1.0
var _scroll_x: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout_layers)
	_layout_layers()

func _process(delta: float) -> void:
	if _cloud_tile_width <= 0.0:
		return
	_scroll_x = fposmod(_scroll_x + clouds_scroll_speed * delta, _cloud_tile_width)
	_apply_cloud_positions()

func _layout_layers() -> void:
	if sky:
		sky.anchor_left = 0.0
		sky.anchor_top = 0.0
		sky.anchor_right = 1.0
		sky.anchor_bottom = 1.0
		sky.offset_left = 0.0
		sky.offset_top = 0.0
		sky.offset_right = 0.0
		sky.offset_bottom = 0.0
	var clouds_tex: Texture2D = clouds_a.texture if clouds_a else null
	if clouds_tex == null:
		return
	var tex_size := clouds_tex.get_size()
	if tex_size.y <= 0.0:
		return
	_cloud_scale = size.y / tex_size.y
	_cloud_tile_width = tex_size.x * _cloud_scale
	var tile_height: float = size.y
	_layout_cloud_rect(clouds_a, tile_height)
	_layout_cloud_rect(clouds_b, tile_height)
	_apply_cloud_positions()

func _layout_cloud_rect(rect: TextureRect, tile_height: float) -> void:
	if rect == null:
		return
	rect.anchor_left = 0.0
	rect.anchor_top = 0.0
	rect.anchor_right = 0.0
	rect.anchor_bottom = 0.0
	rect.offset_top = 0.0
	rect.offset_bottom = tile_height
	rect.offset_right = _cloud_tile_width

func _apply_cloud_positions() -> void:
	if clouds_a:
		clouds_a.offset_left = -_scroll_x
		clouds_a.offset_right = clouds_a.offset_left + _cloud_tile_width
	if clouds_b:
		clouds_b.offset_left = -_scroll_x + _cloud_tile_width
		clouds_b.offset_right = clouds_b.offset_left + _cloud_tile_width
