extends Node2D

const CHECKPOINT_POPUP_SCENE := preload("res://scenes/ui/CheckpointPopup.tscn")
const PLAYER_SCRIPT := preload("res://scripts/player.gd")

@export var activation_cost_coins: int = 5
@export var respawn_offset: Vector2 = Vector2(0.0, -100.0)
const CHECKPOINT_OFF_TEXTURE: Texture2D = preload("res://assets/level_elements/checkpoint_off.png")
const CHECKPOINT_ON_TEXTURE: Texture2D = preload("res://assets/level_elements/checkpoint_on.png")

@onready var checkpoint_sprite: Sprite2D = $CheckpointSprite
@onready var glow_top: Sprite2D = $GlowTop
@onready var interact_area: Area2D = $InteractArea
@onready var prompt_label: Label = $PromptLabel

var is_active_checkpoint: bool = false
var player_in_range: CharacterBody2D
var popup: Control
var glow_tween: Tween
var glow_base_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	add_to_group("checkpoints")
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_ensure_interact_action()
	if interact_area:
		interact_area.body_entered.connect(_on_body_entered)
		interact_area.body_exited.connect(_on_body_exited)
	if glow_top:
		glow_base_scale = glow_top.scale
	_sync_active_state_from_runtime()
	_update_visuals()

func _process(_delta: float) -> void:
	if player_in_range == null or not is_instance_valid(player_in_range):
		_set_prompt_visible(false)
		return
	_set_prompt_visible(not _is_popup_open())
	if _is_popup_open():
		return
	if Input.is_action_just_pressed("interact"):
		if is_active_checkpoint:
			_open_checkpoint_menu_popup()
		else:
			_open_activation_popup()

func _on_body_entered(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	player_in_range = body as CharacterBody2D
	_set_prompt_visible(true)

func _on_body_exited(body: Node) -> void:
	if body == null:
		return
	if body == player_in_range:
		player_in_range = null
		_set_prompt_visible(false)

func _open_activation_popup() -> void:
	var popup_node: Control = _ensure_popup()
	if popup_node == null:
		return
	var game_data: Node = get_node_or_null("/root/GameData")
	var can_afford := true
	if game_data and game_data.has_method("can_afford"):
		can_afford = bool(game_data.call("can_afford", "coins", activation_cost_coins))
	if popup_node.has_method("setup_for_cost"):
		popup_node.call("setup_for_cost", activation_cost_coins, can_afford)
	if popup_node.has_method("open_popup"):
		popup_node.call_deferred("open_popup")
	_set_prompt_visible(false)

func _open_checkpoint_menu_popup() -> void:
	var popup_node: Control = _ensure_popup()
	if popup_node == null:
		return
	if popup_node.has_method("setup_for_menu"):
		popup_node.call("setup_for_menu")
	if popup_node.has_method("open_popup"):
		popup_node.call_deferred("open_popup")
	_set_prompt_visible(false)

func _ensure_popup() -> Control:
	if popup and is_instance_valid(popup):
		return popup
	var parent_node: Node = null
	var current_scene: Node = get_tree().current_scene
	if current_scene:
		parent_node = current_scene.get_node_or_null("HUD")
	if parent_node == null:
		parent_node = get_tree().get_first_node_in_group("hud")
	if parent_node == null:
		parent_node = current_scene
	if parent_node == null:
		return null
	popup = CHECKPOINT_POPUP_SCENE.instantiate() as Control
	if popup == null:
		return null
	parent_node.add_child(popup)
	if popup is CanvasItem:
		(popup as CanvasItem).z_index = 999
	if popup is Control:
		var popup_control := popup as Control
		popup_control.anchor_left = 0.0
		popup_control.anchor_top = 0.0
		popup_control.anchor_right = 1.0
		popup_control.anchor_bottom = 1.0
		popup_control.offset_left = 0.0
		popup_control.offset_top = 0.0
		popup_control.offset_right = 0.0
		popup_control.offset_bottom = 0.0
	if popup.has_signal("activate_requested") and not popup.is_connected("activate_requested", Callable(self, "_on_popup_activate_requested")):
		popup.connect("activate_requested", Callable(self, "_on_popup_activate_requested"))
	if popup.has_signal("cancelled") and not popup.is_connected("cancelled", Callable(self, "_on_popup_cancelled")):
		popup.connect("cancelled", Callable(self, "_on_popup_cancelled"))
	if popup.has_signal("loadout_requested") and not popup.is_connected("loadout_requested", Callable(self, "_on_popup_loadout_requested")):
		popup.connect("loadout_requested", Callable(self, "_on_popup_loadout_requested"))
	if popup.has_signal("closed") and not popup.is_connected("closed", Callable(self, "_on_popup_closed")):
		popup.connect("closed", Callable(self, "_on_popup_closed"))
	return popup

func _on_popup_activate_requested() -> void:
	var game_data: Node = get_node_or_null("/root/GameData")
	if game_data == null or not game_data.has_method("can_afford") or not game_data.has_method("add_currency"):
		return
	if not bool(game_data.call("can_afford", "coins", activation_cost_coins)):
		if popup and popup.has_method("set_insufficient_funds"):
			popup.call("set_insufficient_funds", activation_cost_coins)
		return
	game_data.call("add_currency", "coins", -activation_cost_coins)
	_activate_checkpoint()
	if popup and popup.has_method("close_popup"):
		popup.call("close_popup")

func _on_popup_cancelled() -> void:
	_set_prompt_visible(player_in_range != null and is_instance_valid(player_in_range))

func _on_popup_loadout_requested() -> void:
	if popup and popup.has_method("close_popup"):
		popup.call("close_popup")
	var hud := _find_hud_overlay()
	if hud and hud.has_method("open_character_overlay_from_checkpoint"):
		hud.call_deferred("open_character_overlay_from_checkpoint")

func _on_popup_closed() -> void:
	_set_prompt_visible(player_in_range != null and is_instance_valid(player_in_range))

func _activate_checkpoint() -> void:
	for node in get_tree().get_nodes_in_group("checkpoints"):
		if node == self:
			continue
		if node and node.has_method("deactivate_checkpoint"):
			node.call("deactivate_checkpoint")
	is_active_checkpoint = true
	var respawn_pos: Vector2 = global_position + respawn_offset
	var current_scene: Node = get_tree().current_scene
	var scene_path := String(current_scene.scene_file_path) if current_scene else ""
	PLAYER_SCRIPT.checkpoint_scene_path = scene_path
	PLAYER_SCRIPT.checkpoint_key = _checkpoint_runtime_key()
	PLAYER_SCRIPT.checkpoint_spawn_position = respawn_pos
	_play_checkpoint_activate_sfx()
	if player_in_range and is_instance_valid(player_in_range) and player_in_range.has_method("set_active_checkpoint_respawn"):
		player_in_range.call("set_active_checkpoint_respawn", respawn_pos, _checkpoint_runtime_key())
	_update_visuals()

func deactivate_checkpoint() -> void:
	is_active_checkpoint = false
	_update_visuals()

func _sync_active_state_from_runtime() -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return
	var scene_path := String(current_scene.scene_file_path)
	var active_key: String = String(PLAYER_SCRIPT.get_active_checkpoint_key_for_scene(scene_path))
	is_active_checkpoint = (active_key != "" and active_key == _checkpoint_runtime_key())

func _checkpoint_runtime_key() -> String:
	var current_scene: Node = get_tree().current_scene
	var scene_path := String(current_scene.scene_file_path) if current_scene else ""
	return "%s::%s" % [scene_path, String(get_path())]

func _update_visuals() -> void:
	if checkpoint_sprite:
		checkpoint_sprite.texture = CHECKPOINT_ON_TEXTURE if is_active_checkpoint else CHECKPOINT_OFF_TEXTURE
	if glow_top:
		glow_top.visible = is_active_checkpoint
	if is_active_checkpoint:
		_start_glow_pulse()
	else:
		_stop_glow_pulse()
	_set_prompt_visible(player_in_range != null and is_instance_valid(player_in_range) and not _is_popup_open())

func _start_glow_pulse() -> void:
	if glow_top == null:
		return
	if glow_tween and glow_tween.is_running():
		glow_tween.kill()
	glow_top.visible = true
	glow_top.modulate = Color(1.0, 0.329412, 0.0, 0.8)
	glow_top.scale = glow_base_scale * 1.0
	glow_top.rotation = 0.0
	glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(glow_top, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	glow_tween.parallel().tween_property(glow_top, "scale", glow_base_scale * 2.2, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	glow_tween.tween_property(glow_top, "modulate:a", 0.25, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	glow_tween.parallel().tween_property(glow_top, "scale", glow_base_scale * 1.2, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _stop_glow_pulse() -> void:
	if glow_tween and glow_tween.is_running():
		glow_tween.kill()
	if glow_top:
		glow_top.visible = false
		glow_top.scale = glow_base_scale
		glow_top.modulate.a = 0.0
		glow_top.rotation = 0.0

func _set_prompt_visible(value: bool) -> void:
	if prompt_label:
		prompt_label.visible = value

func _is_popup_open() -> bool:
	return popup != null and is_instance_valid(popup) and popup.visible

func _ensure_interact_action() -> void:
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
	for event_variant in InputMap.action_get_events("interact"):
		var key_event := event_variant as InputEventKey
		if key_event and key_event.keycode == KEY_G:
			return
	var new_event := InputEventKey.new()
	new_event.keycode = KEY_G
	InputMap.action_add_event("interact", new_event)

func _play_checkpoint_activate_sfx() -> void:
	var player_node := player_in_range
	if player_node == null or not is_instance_valid(player_node):
		for node in get_tree().get_nodes_in_group("player"):
			player_node = node as CharacterBody2D
			if player_node:
				break
	if player_node == null:
		return
	var sfx := player_node.get_node_or_null("SfxItemLand") as AudioStreamPlayer
	if sfx and sfx.stream:
		sfx.play()

func _find_hud_overlay() -> Node:
	var current_scene := get_tree().current_scene
	if current_scene:
		var hud_node := current_scene.get_node_or_null("HUD")
		if hud_node:
			return hud_node
	return get_tree().get_first_node_in_group("hud")
