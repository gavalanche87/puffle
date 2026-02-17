extends Panel

@onready var title_label: Label = $Margin/VBox/Title
@onready var description_label: Label = $Margin/VBox/Description
@onready var price_label: Label = $Margin/VBox/Bottom/Price
@onready var state_label: Label = $Margin/VBox/Bottom/State
@onready var buy_button: Button = $Margin/VBox/Bottom/BuyButton
@onready var icon_rect: TextureRect = $Margin/VBox/Icon

var offer_id: String = ""
const COLOR_LIGHT_TEXT := Color(0.964706, 0.964706, 0.964706, 1.0) # #f6f6f6
const COLOR_MAGENTA_OUTLINE := Color(0.74902, 0.184314, 0.686275, 1.0)
const COLOR_DARK_OUTLINE := Color(0.254902, 0.254902, 0.254902, 1.0)
const COLOR_ITEM_DESC := Color(0.74902, 0.74902, 0.74902, 1.0)
const COLOR_ITEM_PRICE := Color(0.980392, 0.972549, 0.67451, 1.0)
const COLOR_ITEM_PRICE_OUTLINE := Color(0.796078, 0.682353, 0.145098, 1.0)
const COLOR_ITEM_STATE := Color(0.368627, 0.901961, 0.682353, 1.0)
const ICON_SIZE_SHIFT: Texture2D = preload("res://assets/ui/amulets/Shift_Size_Amulet.png")
const ICON_HEAD_SPIKE: Texture2D = preload("res://assets/ui/amulets/Head_Spike_Amulet.png")
const ICON_DOUBLE_JUMP: Texture2D = preload("res://assets/ui/amulets/Double_Jump_Amulet.png")

signal buy_requested(offer_id: String)

func setup(data: Dictionary, status_text: String, can_buy: bool, bought: bool) -> void:
	offer_id = String(data.get("id", ""))
	var is_amulet: bool = String(data.get("kind", "")) == "amulet"
	title_label.text = String(data.get("title", "Item"))
	description_label.text = String(data.get("description", ""))
	price_label.text = "%d %s" % [int(data.get("cost", 0)), String(data.get("currency", "coins")).capitalize()]
	state_label.text = status_text
	buy_button.disabled = (not can_buy) or bought
	buy_button.text = "Owned" if bought else "Buy"
	if is_amulet:
		if icon_rect:
			icon_rect.visible = true
			icon_rect.texture = _get_amulet_icon(offer_id)
		title_label.add_theme_color_override("font_color", COLOR_LIGHT_TEXT)
		title_label.add_theme_color_override("font_outline_color", COLOR_MAGENTA_OUTLINE)
		description_label.add_theme_color_override("font_color", COLOR_LIGHT_TEXT)
		description_label.add_theme_color_override("font_outline_color", COLOR_MAGENTA_OUTLINE)
		price_label.add_theme_color_override("font_color", COLOR_LIGHT_TEXT)
		price_label.add_theme_color_override("font_outline_color", COLOR_MAGENTA_OUTLINE)
		state_label.add_theme_color_override("font_color", COLOR_LIGHT_TEXT)
		state_label.add_theme_color_override("font_outline_color", COLOR_MAGENTA_OUTLINE)
	else:
		if icon_rect:
			icon_rect.visible = false
			icon_rect.texture = null
		title_label.add_theme_color_override("font_color", COLOR_LIGHT_TEXT)
		title_label.add_theme_color_override("font_outline_color", COLOR_ITEM_PRICE_OUTLINE)
		description_label.add_theme_color_override("font_color", COLOR_ITEM_DESC)
		description_label.add_theme_color_override("font_outline_color", COLOR_DARK_OUTLINE)
		price_label.add_theme_color_override("font_color", COLOR_ITEM_PRICE)
		price_label.add_theme_color_override("font_outline_color", COLOR_ITEM_PRICE_OUTLINE)
		state_label.add_theme_color_override("font_color", COLOR_ITEM_STATE)
		state_label.add_theme_color_override("font_outline_color", COLOR_DARK_OUTLINE)

func _ready() -> void:
	buy_button.pressed.connect(func() -> void:
		emit_signal("buy_requested", offer_id)
	)

func _get_amulet_icon(amulet_id: String) -> Texture2D:
	match amulet_id:
		"size_shift":
			return ICON_SIZE_SHIFT
		"head_spike":
			return ICON_HEAD_SPIKE
		"double_jump":
			return ICON_DOUBLE_JUMP
		_:
			return null
