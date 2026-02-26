extends Button

@export var action_id: String = ""
@export var min_auto_font_size: int = 14
@export var icon_reserved_width: float = 56.0
@export var horizontal_text_padding: float = 20.0

signal nav_pressed(action_id: String)

var _base_font_size: int = 0

func _ready() -> void:
	clip_text = true
	_base_font_size = get_theme_font_size("font_size")
	pressed.connect(_on_pressed)
	if not resized.is_connected(_refresh_text_fit):
		resized.connect(_refresh_text_fit)
	call_deferred("_refresh_text_fit")

func _on_pressed() -> void:
	emit_signal("nav_pressed", action_id)

func _refresh_text_fit() -> void:
	var font := get_theme_font("font")
	if font == null:
		return
	var base_size: int = _base_font_size if _base_font_size > 0 else get_theme_font_size("font_size")
	if base_size <= 0:
		return
	var outline_px: int = 0
	if has_theme_constant("outline_size"):
		outline_px = get_theme_constant("outline_size")
	var reserved_icon: float = icon_reserved_width if icon != null else 0.0
	var available_width: float = maxf(40.0, size.x - reserved_icon - horizontal_text_padding)
	var chosen_size: int = base_size
	for font_size in range(base_size, min_auto_font_size - 1, -1):
		var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x + float(outline_px * 2)
		if text_width <= available_width:
			chosen_size = font_size
			break
		chosen_size = min_auto_font_size
	add_theme_font_size_override("font_size", chosen_size)
