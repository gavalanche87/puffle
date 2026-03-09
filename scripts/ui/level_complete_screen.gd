extends "res://scripts/ui/menu_transitions.gd"

const XP_GROWTH_MULTIPLIER: float = 1.25
const XP_LEVELUP_POPUP_SCENE: PackedScene = preload("res://scenes/ui/XpLevelUpPopup.tscn")
const NO_HIT_COIN_BONUS: int = 50

@onready var level_time_row: Control = $Layout/VBox/Card/CardMargin/CardVBox/LevelTimeRow
@onready var level_time_value: Label = $Layout/VBox/Card/CardMargin/CardVBox/LevelTimeRow/LevelTimeValue
@onready var new_record_row: Control = $Layout/VBox/Card/CardMargin/CardVBox/NewRecordRow
@onready var no_hit_row: Control = $Layout/VBox/Card/CardMargin/CardVBox/NoHitRow
@onready var no_hit_value: Label = $Layout/VBox/Card/CardMargin/CardVBox/NoHitRow/NoHitValue
@onready var no_hit_coin_icon: TextureRect = $Layout/VBox/Card/CardMargin/CardVBox/NoHitRow/NoHitCoinIcon
@onready var rewards_row: Control = $Layout/VBox/Card/CardMargin/CardVBox/RewardsRow
@onready var reward_xp_icon: TextureRect = $Layout/VBox/Card/CardMargin/CardVBox/RewardsRow/RewardXpIcon
@onready var reward_xp_value: Label = $Layout/VBox/Card/CardMargin/CardVBox/RewardsRow/RewardXpValue
@onready var next_level_button: Button = $Layout/VBox/NextLevelButton

@onready var xp_level_label: Label = $Layout/VBox/TopRow/XpHud/XpLevelLabel
@onready var xp_bar_bg: Control = $Layout/VBox/TopRow/XpHud/XpBarBg
@onready var xp_bar_fill: Control = $Layout/VBox/TopRow/XpHud/XpBarBg/XpBarFill
@onready var xp_icon_target: Node2D = $Layout/VBox/TopRow/XpHud/XpIcon

var _summary: Dictionary = {}
var _xp_level: int = 1
var _xp_current: float = 0.0
var _xp_to_next: float = 100.0
var _xp_reward: int = 20
var _xp_levelup_popup: Control
var _is_new_record: bool = false
var _has_rewards: bool = true

func _ready() -> void:
	super._ready()
	if next_level_button:
		next_level_button.disabled = true
		next_level_button.pressed.connect(_on_next_level_pressed)
	_load_summary()
	_load_xp_state()
	_update_xp_ui()
	await _run_reveal_sequence()
	if next_level_button and next_level_button.disabled:
		next_level_button.disabled = false

func _load_summary() -> void:
	var gd: Node = get_node_or_null("/root/GameData")
	if gd and gd.has_method("consume_pending_level_complete_summary"):
		_summary = gd.call("consume_pending_level_complete_summary")
	var level_time: float = float(_summary.get("level_time", 0.0))
	var no_hit: bool = bool(_summary.get("no_hit", false))
	_is_new_record = bool(_summary.get("new_record", false))
	_xp_reward = maxi(0, int(_summary.get("xp_reward", 20)))
	_has_rewards = bool(_summary.get("has_rewards", _xp_reward > 0))
	if level_time_value:
		level_time_value.text = _format_time(level_time)
	if no_hit_value:
		no_hit_value.text = "+%d" % NO_HIT_COIN_BONUS if no_hit else "NONE"
		no_hit_value.add_theme_color_override(
			"font_outline_color",
			Color(0.11372549, 0.7019608, 0.48235294, 1.0) if no_hit else Color(0.8666667, 0.25882354, 0.45490196, 1.0)
		)
	if no_hit_coin_icon:
		no_hit_coin_icon.visible = no_hit
	if no_hit and gd and gd.has_method("add_currency"):
		gd.call("add_currency", "coins", NO_HIT_COIN_BONUS)
	if reward_xp_value:
		reward_xp_value.text = "+%d XP" % _xp_reward

func _load_xp_state() -> void:
	var gd: Node = get_node_or_null("/root/GameData")
	if gd and gd.has_method("get_xp_state"):
		var state: Dictionary = gd.call("get_xp_state")
		_xp_level = max(1, int(state.get("xp_level", 1)))
		_xp_to_next = maxf(1.0, float(state.get("xp_to_next_level", 100.0)))
		_xp_current = clampf(float(state.get("xp_current", 0.0)), 0.0, _xp_to_next)

func _update_xp_ui() -> void:
	if xp_level_label:
		xp_level_label.text = str(_xp_level)
	if xp_bar_bg and xp_bar_fill:
		var ratio: float = clampf(_xp_current / _xp_to_next, 0.0, 1.0)
		xp_bar_fill.size.x = xp_bar_bg.size.x * ratio

func _run_reveal_sequence() -> void:
	_set_row_visible(level_time_row, false)
	_set_row_visible(new_record_row, false)
	_set_row_visible(no_hit_row, false)
	_set_row_visible(rewards_row, false)
	await _reveal_row(level_time_row)
	if _is_new_record:
		await _reveal_row(new_record_row)
	await _reveal_row(no_hit_row)
	if _has_rewards:
		await _reveal_row(rewards_row)
	await _apply_xp_reward_animation()

func _set_row_visible(row: Control, visible_state: bool) -> void:
	if row == null:
		return
	row.visible = visible_state
	if visible_state:
		row.modulate.a = 1.0
		row.scale = Vector2.ONE

func _reveal_row(row: Control) -> void:
	if row == null:
		return
	row.visible = true
	row.modulate.a = 0.0
	row.scale = Vector2(0.92, 0.92)
	var t := create_tween().set_parallel(true)
	t.tween_property(row, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(row, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished
	await get_tree().create_timer(0.18).timeout

func _apply_xp_reward_animation() -> void:
	if not _has_rewards or _xp_reward <= 0:
		if rewards_row:
			rewards_row.visible = false
		if next_level_button:
			next_level_button.disabled = false
		return
	if reward_xp_icon == null or xp_icon_target == null:
		_apply_xp_reward_state()
		return
	var fly_icon := TextureRect.new()
	fly_icon.texture = reward_xp_icon.texture
	fly_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fly_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fly_icon.custom_minimum_size = reward_xp_icon.size
	fly_icon.global_position = reward_xp_icon.global_position
	fly_icon.scale = reward_xp_icon.scale
	add_child(fly_icon)
	var t := create_tween().set_parallel(true)
	t.tween_property(fly_icon, "global_position", xp_icon_target.global_position, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_property(fly_icon, "scale", reward_xp_icon.scale * 0.35, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(fly_icon, "modulate:a", 0.2, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t.finished
	fly_icon.queue_free()
	_apply_xp_reward_state()

func _apply_xp_reward_state() -> void:
	var xp_gain: float = float(_xp_reward)
	_xp_current += xp_gain
	var levels_gained: int = 0
	while _xp_current >= _xp_to_next:
		_xp_current -= _xp_to_next
		_xp_level += 1
		_xp_to_next = ceil(_xp_to_next * XP_GROWTH_MULTIPLIER)
		levels_gained += 1
	var gd: Node = get_node_or_null("/root/GameData")
	if gd and gd.has_method("set_xp_state"):
		gd.call("set_xp_state", _xp_level, _xp_current, _xp_to_next)
	if levels_gained > 0 and gd and gd.has_method("add_currency"):
		gd.call("add_currency", "tokens", levels_gained)
	var ratio: float = clampf(_xp_current / _xp_to_next, 0.0, 1.0)
	if xp_bar_bg and xp_bar_fill:
		var target_width: float = xp_bar_bg.size.x * ratio
		var t := create_tween()
		t.tween_property(xp_bar_fill, "size:x", target_width, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await t.finished
	_update_xp_ui()
	if levels_gained > 0:
		await _show_xp_levelup_popup(levels_gained)
	if next_level_button:
		next_level_button.disabled = false

func _on_next_level_pressed() -> void:
	if next_level_button:
		next_level_button.disabled = true
	var gd: Node = get_node_or_null("/root/GameData")
	if gd == null:
		go_to_scene("res://scenes/ui/LevelSelect.tscn")
		return
	var level_flow_active: bool = bool(_summary.get("level_flow_active", false))
	if level_flow_active:
		var has_next: bool = bool(_summary.get("has_next_level", false))
		if has_next:
			var next_world: int = int(_summary.get("next_world", 0))
			var next_level: int = int(_summary.get("next_level", 0))
			gd.call("start_level", next_world, next_level)
			return
		gd.call("exit_level_flow")
		go_to_scene("res://scenes/ui/LevelSelect.tscn")
		return
	var fallback_scene: String = String(_summary.get("next_scene_path", ""))
	if fallback_scene != "":
		go_to_scene(fallback_scene)
		return
	go_to_scene("res://scenes/ui/LevelSelect.tscn")

func _format_time(total_seconds: float) -> String:
	var safe_time: float = maxf(0.0, total_seconds)
	var minutes: int = int(floor(safe_time / 60.0))
	var seconds: int = int(floor(fmod(safe_time, 60.0)))
	var centiseconds: int = int(floor(fmod(safe_time, 1.0) * 100.0))
	return "%02d:%02d.%02d" % [minutes, seconds, centiseconds]

func _show_xp_levelup_popup(tokens_reward: int) -> void:
	if XP_LEVELUP_POPUP_SCENE == null:
		return
	var popup_node: Node = XP_LEVELUP_POPUP_SCENE.instantiate()
	var popup: Control = popup_node as Control
	if popup == null:
		if popup_node:
			popup_node.queue_free()
		return
	_xp_levelup_popup = popup
	add_child(_xp_levelup_popup)
	if _xp_levelup_popup.has_method("setup_reward"):
		_xp_levelup_popup.call("setup_reward", tokens_reward, _xp_level)
	if _xp_levelup_popup.has_method("open_popup"):
		_xp_levelup_popup.call("open_popup")
	if _xp_levelup_popup.has_signal("closed"):
		await _xp_levelup_popup.closed
	if is_instance_valid(_xp_levelup_popup):
		_xp_levelup_popup.queue_free()
	_xp_levelup_popup = null
