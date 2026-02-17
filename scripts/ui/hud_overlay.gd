extends CanvasLayer

@onready var pause_button: Button = $PauseButton
@onready var complete_level_test_button: Button = $CompleteLevelTestButton
@onready var pause_menu: Control = $PauseMenuPopup

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if pause_button:
		pause_button.pressed.connect(_on_pause_pressed)
	if complete_level_test_button:
		complete_level_test_button.pressed.connect(_on_complete_level_test_pressed)
	if pause_menu:
		pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
		if pause_menu.has_signal("resume_requested"):
			pause_menu.connect("resume_requested", _on_resume_requested)
		if pause_menu.has_signal("settings_requested"):
			pause_menu.connect("settings_requested", _on_settings_requested)
		if pause_menu.has_signal("main_menu_requested"):
			pause_menu.connect("main_menu_requested", _on_main_menu_requested)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
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

func _on_main_menu_requested() -> void:
	_change_scene_from_pause("res://scenes/ui/MainMenu.tscn")

func _open_pause() -> void:
	if pause_menu and pause_menu.has_method("open_popup"):
		pause_menu.call("open_popup")

func _close_pause() -> void:
	if pause_menu and pause_menu.has_method("close_popup"):
		pause_menu.call("close_popup")

func _is_pause_open() -> bool:
	return pause_menu != null and pause_menu.visible

func _change_scene_from_pause(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)

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
