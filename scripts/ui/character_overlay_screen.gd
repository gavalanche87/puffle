extends "res://scripts/ui/menu_transitions.gd"

signal overlay_closed(from_pause_menu: bool)

const SCENE_ABILITIES := preload("res://scenes/ui/Abilities.tscn")
const SCENE_AMULETS := preload("res://scenes/ui/Amulets.tscn")
const SCENE_WEAPONS := preload("res://scenes/ui/Weapons.tscn")
const SCENE_AMULETS_OVERLAY := preload("res://scenes/ui/AmuletsOverlay.tscn")
const SCENE_WEAPONS_OVERLAY := preload("res://scenes/ui/WeaponsOverlay.tscn")

@onready var back_button: Button = $Layout/VBox/Header/BackButton
@onready var abilities_button: Button = $Layout/VBox/Tabs/AbilitiesButton
@onready var amulets_button: Button = $Layout/VBox/Tabs/AmuletsButton
@onready var weapons_button: Button = $Layout/VBox/Tabs/WeaponsButton
@onready var content: Control = $Layout/VBox/ContentPanel/Content

var _overlay_mode: bool = false
var _opened_from_pause_menu: bool = false
var _manage_mode: bool = false
var _current_tab: String = "amulets"
var _current_view: Control = null
const TAB_OUTLINE_WEAPONS := Color(0.113725, 0.701961, 0.482353, 1.0) # #1db37b
const TAB_OUTLINE_AMULETS := Color(0.87451, 0.486275, 0.827451, 1.0) # #df7cd3
const TAB_OUTLINE_ABILITIES := Color(0.980392, 0.513725, 0.203922, 1.0) # #fa8334

func set_overlay_mode(enabled: bool, from_pause_menu: bool) -> void:
	_overlay_mode = enabled
	_opened_from_pause_menu = from_pause_menu
	if enabled:
		_manage_mode = true

func _ready() -> void:
	super._ready()
	if _is_hud_overlay_context():
		_overlay_mode = true
		_manage_mode = true
	var gd: Node = get_node_or_null("/root/GameData")
	if (not _manage_mode) and gd and gd.has_method("get_amulet_screen_manage_mode"):
		_manage_mode = bool(gd.call("get_amulet_screen_manage_mode"))
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if abilities_button:
		abilities_button.pressed.connect(func() -> void:
			_show_tab("abilities")
		)
	if amulets_button:
		amulets_button.pressed.connect(func() -> void:
			_show_tab("amulets")
		)
	if weapons_button:
		weapons_button.pressed.connect(func() -> void:
			_show_tab("weapons")
		)
	_show_tab(_current_tab)

func _on_back_pressed() -> void:
	if _overlay_mode:
		emit_signal("overlay_closed", _opened_from_pause_menu)
		return
	var gd: Node = get_node_or_null("/root/GameData")
	if _manage_mode and gd and gd.has_method("get_amulet_return_scene_path"):
		var return_path := String(gd.call("get_amulet_return_scene_path"))
		if gd.has_method("set_amulet_screen_manage_mode"):
			gd.call("set_amulet_screen_manage_mode", false)
		if return_path != "":
			go_to_scene(return_path)
			return
	if gd and gd.has_method("set_amulet_screen_manage_mode"):
		gd.call("set_amulet_screen_manage_mode", false)
	go_to_scene("res://scenes/ui/MainMenu.tscn")

func _show_tab(tab_id: String) -> void:
	_current_tab = tab_id
	if _current_view:
		_current_view.queue_free()
		_current_view = null
	var scene: PackedScene = SCENE_AMULETS
	match tab_id:
		"abilities":
			scene = SCENE_ABILITIES
		"weapons":
			scene = SCENE_WEAPONS_OVERLAY
		_:
			scene = SCENE_AMULETS_OVERLAY
	var node: Node = scene.instantiate()
	var view: Control = node as Control
	if view == null:
		if node:
			node.queue_free()
		return
	_current_view = view
	if _current_view.has_method("set_embedded_mode"):
		_current_view.call("set_embedded_mode", true)
	if _current_view.has_method("set_compact_mode"):
		_current_view.call("set_compact_mode", _overlay_mode or _is_hud_overlay_context())
	if _current_view.has_method("set_manage_mode"):
		_current_view.call("set_manage_mode", _manage_mode)
	_current_view.anchor_left = 0.0
	_current_view.anchor_top = 0.0
	_current_view.anchor_right = 1.0
	_current_view.anchor_bottom = 1.0
	_current_view.offset_left = 0.0
	_current_view.offset_top = 0.0
	_current_view.offset_right = 0.0
	_current_view.offset_bottom = 0.0
	content.add_child(_current_view)
	_update_tab_visuals()

func _update_tab_visuals() -> void:
	if abilities_button:
		abilities_button.add_theme_color_override("font_outline_color", TAB_OUTLINE_ABILITIES)
	if abilities_button:
		abilities_button.modulate = Color(1, 1, 1, 1) if _current_tab == "abilities" else Color(0.75, 0.75, 0.75, 1)
	if amulets_button:
		amulets_button.add_theme_color_override("font_outline_color", TAB_OUTLINE_AMULETS)
	if amulets_button:
		amulets_button.modulate = Color(1, 1, 1, 1) if _current_tab == "amulets" else Color(0.75, 0.75, 0.75, 1)
	if weapons_button:
		weapons_button.add_theme_color_override("font_outline_color", TAB_OUTLINE_WEAPONS)
	if weapons_button:
		weapons_button.modulate = Color(1, 1, 1, 1) if _current_tab == "weapons" else Color(0.75, 0.75, 0.75, 1)

func _is_hud_overlay_context() -> bool:
	var p := get_parent()
	if p == null:
		return false
	return p is CanvasLayer
