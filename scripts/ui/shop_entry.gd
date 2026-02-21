extends Panel

@onready var title_label: Label = $Margin/Row/Info/Title
@onready var description_label: Label = $Margin/Row/Info/Description
@onready var price_label: Label = $Margin/Row/Info/MetaRow/Price
@onready var state_label: Label = $Margin/Row/Info/MetaRow/State
@onready var buy_button: Button = $Margin/Row/BuyButton
@onready var icon_rect: TextureRect = $Margin/Row/Icon

var offer_id: String = ""
const COLOR_LIGHT_TEXT := Color(0.933333, 0.898039, 0.913725, 1.0) # #eee5e9
const COLOR_AMULET_OUTLINE := Color(0.87451, 0.486275, 0.827451, 1.0) # #df7cd3
const COLOR_WEAPON_OUTLINE := Color(0.113725, 0.701961, 0.482353, 1.0) # #1db37b
const COLOR_ABILITY_OUTLINE := Color(0.980392, 0.513725, 0.203922, 1.0) # #fa8334
const COLOR_MUSIC_OUTLINE := Color(0.254902, 0.737255, 0.737255, 1.0) # #41bcbc
const COLOR_DARK_OUTLINE := Color(0.254902, 0.254902, 0.254902, 1.0)
const COLOR_ITEM_DESC := Color(0.933333, 0.898039, 0.913725, 1.0)
const COLOR_ITEM_PRICE := Color(0.933333, 0.898039, 0.913725, 1.0)
const COLOR_ITEM_PRICE_OUTLINE := Color(0.796078, 0.682353, 0.145098, 1.0)
const COLOR_ITEM_STATE := Color(0.933333, 0.898039, 0.913725, 1.0)
const ICON_LEAP_OF_FAITH: Texture2D = preload("res://assets/ui/amulets/Leap_Of_Faith_Amulet.png")
const ICON_SIZE_SHIFT: Texture2D = preload("res://assets/ui/abilities/Shift_Size_Ability.png")
const ICON_DOUBLE_JUMP: Texture2D = preload("res://assets/ui/abilities/Double_Jump_Ability.png")
const ICON_WALL_JUMP: Texture2D = preload("res://assets/ui/abilities/Wall_Jump_Ability.png")
const ICON_HEADBUTT: Texture2D = preload("res://assets/ui/weapons/Head_Spike_Weapon.png")
const ICON_HEAD_SPIKE: Texture2D = preload("res://assets/ui/weapons/Head_Spike_Weapon.png")
const ICON_HEALTH_ITEM: Texture2D = preload("res://assets/items/heart_icon.png")
const ICON_ENERGY_ITEM: Texture2D = preload("res://assets/items/energy_icon.png")

signal buy_requested(offer_id: String)

func setup(data: Dictionary, status_text: String, can_buy: bool, bought: bool) -> void:
	offer_id = String(data.get("id", ""))
	var kind: String = String(data.get("kind", ""))
	var description: String = String(data.get("description", ""))
	if kind == "amulet":
		description = description.replace(" | ", "\n")
	elif kind == "weapon" or kind == "ability" or kind == "music_track":
		description = description.replace("Boon: ", "")
	title_label.text = String(data.get("title", "Item"))
	description_label.text = description
	price_label.text = "%d %s" % [int(data.get("cost", 0)), String(data.get("currency", "coins")).capitalize()]
	state_label.text = status_text
	buy_button.disabled = (not can_buy) or bought
	buy_button.text = "Owned" if bought else "Buy"
	if icon_rect:
		icon_rect.visible = true
		icon_rect.texture = _get_offer_icon(offer_id)
	if kind == "amulet":
		title_label.add_theme_color_override("font_color", COLOR_LIGHT_TEXT)
		title_label.add_theme_color_override("font_outline_color", COLOR_AMULET_OUTLINE)
		description_label.add_theme_color_override("font_color", COLOR_ITEM_DESC)
		description_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
		description_label.add_theme_constant_override("outline_size", 0)
		price_label.add_theme_color_override("font_color", COLOR_LIGHT_TEXT)
		price_label.add_theme_color_override("font_outline_color", COLOR_AMULET_OUTLINE)
		state_label.add_theme_color_override("font_color", COLOR_LIGHT_TEXT)
		state_label.add_theme_color_override("font_outline_color", COLOR_AMULET_OUTLINE)
	elif kind == "weapon":
		title_label.add_theme_color_override("font_color", COLOR_LIGHT_TEXT)
		title_label.add_theme_color_override("font_outline_color", COLOR_WEAPON_OUTLINE)
		description_label.add_theme_color_override("font_color", COLOR_ITEM_DESC)
		description_label.add_theme_color_override("font_outline_color", COLOR_DARK_OUTLINE)
		description_label.add_theme_constant_override("outline_size", 8)
		price_label.add_theme_color_override("font_color", COLOR_ITEM_PRICE)
		price_label.add_theme_color_override("font_outline_color", COLOR_WEAPON_OUTLINE)
		state_label.add_theme_color_override("font_color", COLOR_ITEM_STATE)
		state_label.add_theme_color_override("font_outline_color", COLOR_WEAPON_OUTLINE)
	elif kind == "ability":
		title_label.add_theme_color_override("font_color", COLOR_LIGHT_TEXT)
		title_label.add_theme_color_override("font_outline_color", COLOR_ABILITY_OUTLINE)
		description_label.add_theme_color_override("font_color", COLOR_ITEM_DESC)
		description_label.add_theme_color_override("font_outline_color", COLOR_DARK_OUTLINE)
		description_label.add_theme_constant_override("outline_size", 8)
		price_label.add_theme_color_override("font_color", COLOR_ITEM_PRICE)
		price_label.add_theme_color_override("font_outline_color", COLOR_ABILITY_OUTLINE)
		state_label.add_theme_color_override("font_color", COLOR_ITEM_STATE)
		state_label.add_theme_color_override("font_outline_color", COLOR_ABILITY_OUTLINE)
	elif kind == "music_track":
		title_label.add_theme_color_override("font_color", COLOR_LIGHT_TEXT)
		title_label.add_theme_color_override("font_outline_color", COLOR_MUSIC_OUTLINE)
		description_label.add_theme_color_override("font_color", COLOR_ITEM_DESC)
		description_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
		description_label.add_theme_constant_override("outline_size", 0)
		price_label.add_theme_color_override("font_color", COLOR_ITEM_PRICE)
		price_label.add_theme_color_override("font_outline_color", COLOR_MUSIC_OUTLINE)
		state_label.add_theme_color_override("font_color", COLOR_ITEM_STATE)
		state_label.add_theme_color_override("font_outline_color", COLOR_MUSIC_OUTLINE)
	else:
		title_label.add_theme_color_override("font_color", COLOR_LIGHT_TEXT)
		title_label.add_theme_color_override("font_outline_color", COLOR_ITEM_PRICE_OUTLINE)
		description_label.add_theme_color_override("font_color", COLOR_ITEM_DESC)
		description_label.add_theme_color_override("font_outline_color", COLOR_DARK_OUTLINE)
		description_label.add_theme_constant_override("outline_size", 8)
		price_label.add_theme_color_override("font_color", COLOR_ITEM_PRICE)
		price_label.add_theme_color_override("font_outline_color", COLOR_ITEM_PRICE_OUTLINE)
		state_label.add_theme_color_override("font_color", COLOR_ITEM_STATE)
		state_label.add_theme_color_override("font_outline_color", COLOR_DARK_OUTLINE)

func _ready() -> void:
	buy_button.pressed.connect(func() -> void:
		emit_signal("buy_requested", offer_id)
	)

func _get_offer_icon(offer_kind_id: String) -> Texture2D:
	match offer_kind_id:
		"leap_of_faith":
			return ICON_LEAP_OF_FAITH
		"size_shift":
			return ICON_SIZE_SHIFT
		"double_jump":
			return ICON_DOUBLE_JUMP
		"wall_jump":
			return ICON_WALL_JUMP
		"headbutt":
			return ICON_HEADBUTT
		"head_spike":
			return ICON_HEAD_SPIKE
		"health_pack":
			return ICON_HEALTH_ITEM
		"energy_pack":
			return ICON_ENERGY_ITEM
		_:
			return null
