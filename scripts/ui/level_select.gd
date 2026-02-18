extends "res://scripts/ui/menu_transitions.gd"

const WORLDS := 3
const LEVELS_PER_WORLD := 10

@onready var world_buttons: Array[Button] = [
	$Layout/VBox/Header/WorldTabs/World1,
	$Layout/VBox/Header/WorldTabs/World2,
	$Layout/VBox/Header/WorldTabs/World3
]
@onready var back_button: Button = $Layout/VBox/Header/TopRow/BackButton
@onready var world_status: Label = $Layout/VBox/Header/WorldStatus
@onready var test_scene_button: Button = $Layout/VBox/Header/DevRow/TestSceneButton
@onready var level_grid: GridContainer = $Layout/VBox/LevelPanel/LevelGrid

const LEVEL_BUTTON_SCENE := preload("res://scenes/ui/LevelButton.tscn")

var selected_world: int = 1

func _ready() -> void:
	super._ready()
	back_button.pressed.connect(func() -> void:
		go_to_scene("res://scenes/ui/MainMenu.tscn")
	)
	test_scene_button.pressed.connect(func() -> void:
		go_to_scene("res://scenes/levels/test/VerticalTestScene.tscn")
	)
	for i in range(world_buttons.size()):
		var world_id := i + 1
		world_buttons[i].pressed.connect(_on_world_tab_pressed.bind(world_id))
	var gd := get_node_or_null("/root/GameData")
	if gd:
		if gd.has_signal("progression_changed"):
			gd.progression_changed.connect(_refresh)
	_refresh()

func _select_world(world: int) -> void:
	selected_world = clampi(world, 1, WORLDS)
	_refresh()

func _on_world_tab_pressed(world: int) -> void:
	_select_world(world)

func _refresh() -> void:
	var gd := get_node_or_null("/root/GameData")
	for i in range(world_buttons.size()):
		var w := i + 1
		var unlocked := true
		if gd:
			unlocked = gd.is_world_unlocked(w)
		world_buttons[i].disabled = not unlocked
		world_buttons[i].text = "WORLD %d" % w if unlocked else "WORLD %d [LOCKED]" % w
		world_buttons[i].tooltip_text = "Open World %d" % w if unlocked else "Locked: Finish prior world"
		world_buttons[i].modulate = Color(1, 1, 1, 1) if w == selected_world else Color(0.75, 0.75, 0.75, 1)
	if gd and not gd.is_world_unlocked(selected_world):
		selected_world = max(1, gd.unlocked_worlds)
	for child in level_grid.get_children():
		child.queue_free()
	for level in range(1, LEVELS_PER_WORLD + 1):
		var btn := LEVEL_BUTTON_SCENE.instantiate()
		var unlocked := true
		var completed := false
		if gd:
			unlocked = gd.is_level_unlocked(selected_world, level)
			completed = gd.is_level_completed(selected_world, level)
		btn.setup(selected_world, level, unlocked, completed)
		btn.level_pressed.connect(_on_level_pressed)
		level_grid.add_child(btn)
	if gd:
		world_status.text = "World %d  |  Unlocked: %d/%d" % [selected_world, int(gd.unlocked_levels.get(selected_world, 0)), LEVELS_PER_WORLD]
	else:
		world_status.text = "World %d" % selected_world

func _on_level_pressed(world: int, level: int) -> void:
	var gd := get_node_or_null("/root/GameData")
	if gd:
		gd.start_level(world, level)
