extends CanvasLayer

@onready var pause_button: Button = $PauseButton
@onready var complete_level_test_button: Button = $CompleteLevelTestButton
@onready var pause_menu: Control = $PauseMenuPopup
@onready var amulets_hud_button: Button = $EquippedAmuletsPanel/AmuletsHudButton

var _character_overlay: Control = null
var _character_overlay_from_pause: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var gd: Node = get_node_or_null("/root/GameData")
	if pause_button:
		pause_button.pressed.connect(_on_pause_pressed)
	if amulets_hud_button:
		amulets_hud_button.pressed.connect(_on_amulets_hud_pressed)
	if complete_level_test_button:
		complete_level_test_button.pressed.connect(_on_complete_level_test_pressed)
	if pause_menu:
		pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
		if pause_menu.has_signal("resume_requested"):
			pause_menu.connect("resume_requested", _on_resume_requested)
		if pause_menu.has_signal("settings_requested"):
			pause_menu.connect("settings_requested", _on_settings_requested)
		if pause_menu.has_signal("amulets_requested"):
			pause_menu.connect("amulets_requested", _on_amulets_requested)
		if pause_menu.has_signal("main_menu_requested"):
			pause_menu.connect("main_menu_requested", _on_main_menu_requested)
	if gd and gd.has_method("consume_open_pause_on_next_hud"):
		if bool(gd.call("consume_open_pause_on_next_hud")):
			call_deferred("_open_pause")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _character_overlay:
			_close_character_overlay(not _character_overlay_from_pause)
			if _character_overlay_from_pause and not _is_pause_open():
				_open_pause()
			get_viewport().set_input_as_handled()
			return
		if _is_pause_open():
			_close_pause()
		else:
			_open_pause()
		get_viewport().set_input_as_handled()

func _on_pause_pressed() -> void:
	if _is_pause_open():
		_close_pause()
	else:
		_open_pause()

func _on_complete_level_test_pressed() -> void:
	_simulate_level_complete()

func _on_resume_requested() -> void:
	_close_pause()

func _on_settings_requested() -> void:
	_change_scene_from_pause("res://scenes/ui/Settings.tscn")

func _on_amulets_requested() -> void:
	_open_character_overlay(true)

func _on_main_menu_requested() -> void:
	_change_scene_from_pause("res://scenes/ui/MainMenu.tscn")

func _on_amulets_hud_pressed() -> void:
	_open_character_overlay(false)

func _open_pause() -> void:
	if pause_menu and pause_menu.has_method("open_popup"):
		pause_menu.call("open_popup")

func _close_pause() -> void:
	_refresh_player_amulet_state()
	if pause_menu and pause_menu.has_method("close_popup"):
		pause_menu.call("close_popup")

func _is_pause_open() -> bool:
	return pause_menu != null and pause_menu.visible

func _change_scene_from_pause(path: String) -> void:
	_close_character_overlay(false)
	get_tree().paused = false
	get_tree().change_scene_to_file(path)

func _open_character_overlay(from_pause_menu: bool) -> void:
	if _character_overlay != null:
		return
	var gd: Node = get_node_or_null("/root/GameData")
	if gd and gd.has_method("set_amulet_screen_manage_mode"):
		gd.call("set_amulet_screen_manage_mode", true)
	var packed: PackedScene = load("res://scenes/ui/CharacterOverlay.tscn") as PackedScene
	if packed == null:
		return
	var instance: Node = packed.instantiate()
	var screen: Control = instance as Control
	if screen == null:
		if instance:
			instance.queue_free()
		return
	_character_overlay = screen
	_character_overlay_from_pause = from_pause_menu
	_character_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	if _character_overlay.has_method("set_overlay_mode"):
		_character_overlay.call("set_overlay_mode", true, from_pause_menu)
	if _character_overlay.has_signal("overlay_closed"):
		_character_overlay.connect("overlay_closed", _on_amulets_overlay_closed)
	add_child(_character_overlay)
	if not from_pause_menu:
		_close_pause()
	get_tree().paused = true

func _on_amulets_overlay_closed(from_pause_menu: bool) -> void:
	_close_character_overlay(not from_pause_menu)
	_refresh_player_amulet_state()
	if from_pause_menu and not _is_pause_open():
		_open_pause()

func _close_character_overlay(resume_game: bool) -> void:
	if _character_overlay:
		_character_overlay.queue_free()
		_character_overlay = null
	var gd: Node = get_node_or_null("/root/GameData")
	if gd and gd.has_method("set_amulet_screen_manage_mode"):
		gd.call("set_amulet_screen_manage_mode", false)
	if resume_game:
		get_tree().paused = false
	_character_overlay_from_pause = false

func _refresh_player_amulet_state() -> void:
	for node in get_tree().get_nodes_in_group("player"):
		var player := node as Node
		if player == null:
			continue
		if player.has_method("validate_ability_state_from_amulets"):
			player.call("validate_ability_state_from_amulets")

func _simulate_level_complete() -> void:
	var game_data: Node = get_node_or_null("/root/GameData")
	if game_data and game_data.has_method("complete_current_level"):
		game_data.call("complete_current_level")
	if game_data and game_data.has_method("is_level_flow_active") and game_data.call("is_level_flow_active"):
		game_data.call("exit_level_flow")
		get_tree().change_scene_to_file("res://scenes/ui/LevelSelect.tscn")
		return
	var goal_node := _find_goal_node()
	if goal_node:
		var next_scene_path := String(goal_node.get("next_scene_path"))
		if next_scene_path != "":
			get_tree().change_scene_to_file(next_scene_path)
			return
	get_tree().change_scene_to_file("res://scenes/ui/LevelSelect.tscn")

func _find_goal_node() -> Area2D:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return null
	var all: Array[Node] = scene.find_children("*", "Area2D", true, false)
	for entry in all:
		var area := entry as Area2D
		if area == null:
			continue
		var script: Script = area.get_script() as Script
		if script and String(script.resource_path) == "res://scripts/goal.gd":
			return area
	return null
