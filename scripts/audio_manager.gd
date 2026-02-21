extends Node

var saw_stream: AudioStreamMP3
var saw_player: AudioStreamPlayer
var saw_visible_count: int = 0
var music_player: AudioStreamPlayer
var _last_scene_path: String = ""
var _music_fade_tween: Tween
var _music_transition_token: int = 0
var _pending_track_path: String = ""
var _pending_track_id: String = ""
var _pending_loop: bool = true
var _pending_context: String = ""
var _current_context: String = ""
var _current_track_id: String = ""
var _level_music_paused: bool = false

const MENU_THEME_PATH := "res://assets/sound/main_theme.mp3"
const MENU_SCENE_PREFIX := "res://scenes/ui/"
const LEVEL_SCENE_PREFIX := "res://scenes/levels/"
const CONTEXT_MENU := "menu"
const CONTEXT_LEVEL := "level"
const LEVEL_MUSIC_DEFAULT_ID := "level_music_1"
const MUSIC_FADE_OUT_TIME := 0.18
const MUSIC_FADE_IN_TIME := 0.28
const MUSIC_SILENT_DB := -40.0
const MUSIC_TARGET_DB := 0.0

func _ready() -> void:
	randomize()
	_ensure_music_bus()
	_setup_music_player()
	var tree := get_tree()
	_apply_music_for_scene(tree.current_scene if tree else null)
	_last_scene_path = _get_scene_path(tree.current_scene if tree else null)

	# Initialize the saw sound player
	saw_stream = load("res://assets/sound/saw.mp3")
	if saw_stream:
		saw_stream.loop = true
	
	saw_player = AudioStreamPlayer.new()
	saw_player.stream = saw_stream
	# Set a reasonable volume, maybe -10 dB because mechanical sounds can be loud
	saw_player.volume_db = -10.0
	add_child(saw_player)

func _ensure_music_bus() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus(AudioServer.get_bus_count())
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "Music")

func _setup_music_player() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	music_player.volume_db = MUSIC_TARGET_DB
	add_child(music_player)

func _process(_delta: float) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var scene := tree.current_scene
	var scene_path := _get_scene_path(scene)
	if scene_path == "":
		return
	if scene_path == _last_scene_path:
		return
	_last_scene_path = scene_path
	_apply_music_for_scene(scene)

func _get_scene_path(scene: Node) -> String:
	if scene == null:
		return ""
	if scene.has_method("get_scene_file_path"):
		return String(scene.call("get_scene_file_path"))
	return String(scene.scene_file_path)

func _apply_music_for_scene(scene: Node) -> void:
	if music_player == null:
		return
	var path := _get_scene_path(scene)

	var is_menu_scene := path.begins_with(MENU_SCENE_PREFIX)
	var is_level_scene := path.begins_with(LEVEL_SCENE_PREFIX)

	if is_menu_scene:
		if _current_context != CONTEXT_MENU or _current_track_id != "main_theme":
			_transition_to_track(MENU_THEME_PATH, "main_theme", true, CONTEXT_MENU)
		return
	if is_level_scene:
		var level_track_id := _pick_random_unlocked_level_track_id()
		var level_track_path := _resolve_level_track_path(level_track_id)
		if _current_context != CONTEXT_LEVEL or _current_track_id != level_track_id:
			_transition_to_track(level_track_path, level_track_id, true, CONTEXT_LEVEL)
		return

func _pick_random_unlocked_level_track_id() -> String:
	var gd := get_node_or_null("/root/GameData")
	var unlocked: Array = []
	if gd and gd.has_method("get_unlocked_music_tracks"):
		unlocked = gd.call("get_unlocked_music_tracks")
	if unlocked.is_empty():
		return LEVEL_MUSIC_DEFAULT_ID
	var idx := randi() % unlocked.size()
	return String(unlocked[idx])

func _resolve_level_track_path(track_id: String) -> String:
	var gd := get_node_or_null("/root/GameData")
	if gd and gd.has_method("get_music_track_path"):
		return String(gd.call("get_music_track_path", track_id))
	return "res://assets/sound/%s.mp3" % track_id

func _transition_to_track(track_path: String, track_id: String, looped: bool, context: String) -> void:
	if track_path == "":
		return
	_pending_track_path = track_path
	_pending_track_id = track_id
	_pending_loop = looped
	_pending_context = context
	_music_transition_token += 1
	var token := _music_transition_token
	_level_music_paused = false

	if _music_fade_tween and _music_fade_tween.is_running():
		_music_fade_tween.kill()

	if music_player.playing:
		_music_fade_tween = create_tween()
		_music_fade_tween.tween_property(music_player, "volume_db", MUSIC_SILENT_DB, MUSIC_FADE_OUT_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_music_fade_tween.tween_callback(Callable(self, "_apply_pending_track").bind(token))
	else:
		_apply_pending_track(token)

func _apply_pending_track(token: int) -> void:
	if token != _music_transition_token:
		return
	var stream := load(_pending_track_path) as AudioStream
	if stream == null:
		return
	_set_stream_loop(stream, _pending_loop)
	music_player.stop()
	music_player.stream = stream
	music_player.stream_paused = false
	music_player.volume_db = MUSIC_SILENT_DB
	music_player.play()
	_current_context = _pending_context
	_current_track_id = _pending_track_id
	_music_fade_tween = create_tween()
	_music_fade_tween.tween_property(music_player, "volume_db", MUSIC_TARGET_DB, MUSIC_FADE_IN_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _set_stream_loop(stream: AudioStream, looped: bool) -> void:
	if stream == null:
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = looped
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = looped
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD if looped else AudioStreamWAV.LOOP_DISABLED

func pause_level_music() -> void:
	if music_player == null:
		return
	if _current_context != CONTEXT_LEVEL:
		return
	if not music_player.playing:
		return
	music_player.stream_paused = true
	_level_music_paused = true

func resume_level_music() -> void:
	if music_player == null:
		return
	if _current_context != CONTEXT_LEVEL:
		return
	if not _level_music_paused:
		return
	music_player.stream_paused = false
	_level_music_paused = false

func add_saw_on_screen() -> void:
	# Saw SFX temporarily disabled.
	saw_visible_count += 1

func remove_saw_on_screen() -> void:
	saw_visible_count = max(0, saw_visible_count - 1)
	# Saw SFX temporarily disabled.

func _update_saw_sound() -> void:
	# Saw SFX temporarily disabled.
	if saw_player and saw_player.playing:
		saw_player.stop()
