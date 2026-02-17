extends Node

signal data_changed
signal progression_changed
signal currencies_changed
signal inventory_changed
signal amulets_changed

const SAVE_PATH := "user://save_data.json"
const LEVEL_SELECT_SCENE := "res://scenes/ui/LevelSelect.tscn"

const WORLD_COUNT := 3
const LEVELS_PER_WORLD := 10

var coins: int = 0
var tokens: int = 3
var unlocked_worlds: int = 1
var unlocked_levels: Dictionary = {1: 1, 2: 0, 3: 0}
var completed_levels: Array[String] = []
var consumable_inventory: Dictionary = {"health": 0, "energy": 0}
var owned_amulets: Array[String] = []
var equipped_amulet: String = ""
var equipped_amulets: Array[String] = []
var amulet_slots_unlocked: int = 3
var amulet_screen_manage_mode: bool = false
var amulet_return_scene_path: String = ""
var amulet_return_to_pause: bool = false
var open_pause_on_next_hud: bool = false

var current_world: int = 0
var current_level: int = 0
var level_flow_active: bool = false

var music_volume_linear: float = 0.75
var sfx_volume_linear: float = 0.8
var xp_level: int = 1
var xp_current: float = 0.0
var xp_to_next_level: float = 100.0

const SHOP_ITEMS := [
	{
		"id": "health_pack",
		"kind": "item",
		"title": "Health Pack",
		"description": "+25 Health (consumable)",
		"currency": "coins",
		"cost": 5,
		"inventory_key": "health"
	},
	{
		"id": "energy_pack",
		"kind": "item",
		"title": "Energy Pack",
		"description": "+25 Energy (consumable)",
		"currency": "coins",
		"cost": 5,
		"inventory_key": "energy"
	}
]

const SHOP_AMULETS := [
	{
		"id": "size_shift",
		"kind": "amulet",
		"title": "Size Shift",
		"description": "Boon: Toggle Big/Small Mode | Grievance: Enemy Damage x1.5",
		"currency": "tokens",
		"cost": 2
	},
	{
		"id": "head_spike",
		"kind": "amulet",
		"title": "Head Spike",
		"description": "Boon: Spike Attack (X) | Grievance: Max Health -10%",
		"currency": "tokens",
		"cost": 2
	},
	{
		"id": "double_jump",
		"kind": "amulet",
		"title": "Double Jump",
		"description": "Boon: +1 Mid-air Jump | Grievance: Bonus Reward Rate x3",
		"currency": "tokens",
		"cost": 3
	}
]

const AMULET_INFO := {
	"size_shift": {
		"title": "Size Shift",
		"boon": "Toggle Big and Small form with Z",
		"grievance": "Enemy Damage x1.5",
		"shop_cost_tokens": 2
	},
	"head_spike": {
		"title": "Head Spike",
		"boon": "Enable head spike attacks with X",
		"grievance": "Max Health -10%",
		"shop_cost_tokens": 2
	},
	"double_jump": {
		"title": "Double Jump",
		"boon": "Gain one extra jump in mid-air",
		"grievance": "Bonus Reward Rate x3",
		"shop_cost_tokens": 3
	}
}

func _ready() -> void:
	_ensure_audio_buses()
	_load_data()
	_apply_audio_settings()

func get_shop_items() -> Array:
	return SHOP_ITEMS.duplicate(true)

func get_shop_amulets() -> Array:
	return SHOP_AMULETS.duplicate(true)

func is_world_unlocked(world: int) -> bool:
	return world >= 1 and world <= unlocked_worlds

func is_level_unlocked(world: int, level: int) -> bool:
	if world < 1 or world > WORLD_COUNT:
		return false
	if level < 1 or level > LEVELS_PER_WORLD:
		return false
	if world > unlocked_worlds:
		return false
	return level <= int(unlocked_levels.get(world, 0))

func level_key(world: int, level: int) -> String:
	return "%d_%d" % [world, level]

func is_level_completed(world: int, level: int) -> bool:
	return completed_levels.has(level_key(world, level))

func get_level_scene(world: int, level: int) -> String:
	var cycle := [
		"res://scenes/Level_1.tscn",
		"res://scenes/MainLevel.tscn",
		"res://scenes/VerticalTestScene.tscn"
	]
	var idx := ((world - 1) * LEVELS_PER_WORLD + (level - 1)) % cycle.size()
	return cycle[idx]

func start_level(world: int, level: int) -> void:
	if not is_level_unlocked(world, level):
		return
	current_world = world
	current_level = level
	level_flow_active = true
	var path := get_level_scene(world, level)
	get_tree().change_scene_to_file(path)

func is_level_flow_active() -> bool:
	return level_flow_active

func exit_level_flow() -> void:
	level_flow_active = false
	current_world = 0
	current_level = 0

func complete_current_level() -> void:
	if current_world <= 0 or current_level <= 0:
		return
	complete_level(current_world, current_level)

func complete_level(world: int, level: int) -> void:
	var key := level_key(world, level)
	if not completed_levels.has(key):
		completed_levels.append(key)

	var unlocked_changed := false
	var max_level := int(unlocked_levels.get(world, 0))
	if level >= max_level and level < LEVELS_PER_WORLD:
		unlocked_levels[world] = min(LEVELS_PER_WORLD, level + 1)
		unlocked_changed = true
	elif level >= LEVELS_PER_WORLD and world < WORLD_COUNT:
		if unlocked_worlds < world + 1:
			unlocked_worlds = world + 1
			unlocked_changed = true
		if int(unlocked_levels.get(world + 1, 0)) < 1:
			unlocked_levels[world + 1] = 1
			unlocked_changed = true

	_save_data()
	emit_signal("progression_changed")
	emit_signal("data_changed")
	if unlocked_changed:
		emit_signal("progression_changed")

func get_balance(currency: String) -> int:
	match currency:
		"coins":
			return coins
		"tokens":
			return tokens
		_:
			return 0

func add_currency(currency: String, amount: int, save_now: bool = true) -> void:
	if amount == 0:
		return
	match currency:
		"coins":
			coins = max(0, coins + amount)
		"tokens":
			tokens = max(0, tokens + amount)
		_:
			return
	if save_now:
		_save_data()
	emit_signal("currencies_changed")
	emit_signal("data_changed")

func can_afford(currency: String, cost: int) -> bool:
	return get_balance(currency) >= cost

func purchase_offer(offer_id: String) -> Dictionary:
	var offer := _find_offer(offer_id)
	if offer.is_empty():
		return {"ok": false, "message": "Offer not found"}

	var currency := String(offer.get("currency", "coins"))
	var cost := int(offer.get("cost", 0))
	if not can_afford(currency, cost):
		return {"ok": false, "message": "Not enough %s" % currency}

	if String(offer.get("kind", "")) == "amulet":
		var amulet_id := String(offer.get("id", ""))
		if owned_amulets.has(amulet_id):
			return {"ok": false, "message": "Already owned"}
		owned_amulets.append(amulet_id)
	else:
		var inv_key := String(offer.get("inventory_key", ""))
		if inv_key != "":
			consumable_inventory[inv_key] = int(consumable_inventory.get(inv_key, 0)) + 1

	add_currency(currency, -cost, false)
	_save_data()
	emit_signal("inventory_changed")
	emit_signal("currencies_changed")
	emit_signal("amulets_changed")
	emit_signal("data_changed")
	return {"ok": true, "message": "Purchased %s" % String(offer.get("title", "item"))}

func get_inventory_count(key: String) -> int:
	return int(consumable_inventory.get(key, 0))

func consume_consumable(key: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	var current: int = int(consumable_inventory.get(key, 0))
	if current < amount:
		return false
	consumable_inventory[key] = current - amount
	_save_data()
	emit_signal("inventory_changed")
	emit_signal("data_changed")
	return true

func get_xp_state() -> Dictionary:
	return {
		"xp_level": xp_level,
		"xp_current": xp_current,
		"xp_to_next_level": xp_to_next_level
	}

func set_xp_state(level: int, current: float, to_next: float, save_now: bool = true) -> void:
	xp_level = max(1, level)
	xp_to_next_level = maxf(1.0, to_next)
	xp_current = clampf(current, 0.0, xp_to_next_level)
	if save_now:
		_save_data()
	emit_signal("data_changed")

func has_amulet(amulet_id: String) -> bool:
	return owned_amulets.has(amulet_id)

func get_amulet_catalog() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for offer in SHOP_AMULETS:
		var id := String(offer.get("id", ""))
		var info: Dictionary = AMULET_INFO.get(id, {})
		out.append({
			"id": id,
			"title": String(info.get("title", String(offer.get("title", id)))),
			"boon": String(info.get("boon", "")),
			"grievance": String(info.get("grievance", "")),
			"cost_tokens": int(info.get("shop_cost_tokens", int(offer.get("cost", 0))))
		})
	return out

func get_owned_amulets() -> Array[String]:
	return owned_amulets.duplicate()

func get_equipped_amulets() -> Array[String]:
	return equipped_amulets.duplicate()

func get_amulet_slots_unlocked() -> int:
	return max(3, amulet_slots_unlocked)

func is_amulet_equipped(amulet_id: String) -> bool:
	return equipped_amulets.has(amulet_id)

func equip_amulet(amulet_id: String, slot_index: int = 0) -> Dictionary:
	if not has_amulet(amulet_id):
		return {"ok": false, "message": "Amulet not owned"}
	if slot_index < 0 or slot_index >= get_amulet_slots_unlocked():
		return {"ok": false, "message": "Slot locked"}
	var existing_index: int = equipped_amulets.find(amulet_id)
	if existing_index != -1 and existing_index != slot_index:
		return {"ok": false, "message": "Amulet already equipped"}
	while equipped_amulets.size() <= slot_index:
		equipped_amulets.append("")
	equipped_amulets[slot_index] = amulet_id
	equipped_amulet = equipped_amulets[0] if not equipped_amulets.is_empty() else ""
	_save_data()
	emit_signal("amulets_changed")
	emit_signal("inventory_changed")
	emit_signal("data_changed")
	return {"ok": true, "message": "Equipped %s" % amulet_id}

func unequip_amulet(slot_index: int = 0) -> Dictionary:
	if slot_index < 0 or slot_index >= get_amulet_slots_unlocked():
		return {"ok": false, "message": "Slot locked"}
	while equipped_amulets.size() <= slot_index:
		equipped_amulets.append("")
	equipped_amulets[slot_index] = ""
	equipped_amulet = equipped_amulets[0] if not equipped_amulets.is_empty() else ""
	_save_data()
	emit_signal("amulets_changed")
	emit_signal("inventory_changed")
	emit_signal("data_changed")
	return {"ok": true, "message": "Unequipped"}

func set_amulet_screen_manage_mode(value: bool) -> void:
	amulet_screen_manage_mode = value

func get_amulet_screen_manage_mode() -> bool:
	return amulet_screen_manage_mode

func set_amulet_return_context(scene_path: String, should_reopen_pause: bool) -> void:
	amulet_return_scene_path = scene_path
	amulet_return_to_pause = should_reopen_pause
	open_pause_on_next_hud = should_reopen_pause

func get_amulet_return_scene_path() -> String:
	return amulet_return_scene_path

func should_reopen_pause_on_return() -> bool:
	return amulet_return_to_pause

func consume_open_pause_on_next_hud() -> bool:
	var value := open_pause_on_next_hud
	open_pause_on_next_hud = false
	return value

func set_music_volume_linear(value: float) -> void:
	music_volume_linear = clampf(value, 0.0, 1.0)
	_set_bus_volume("Music", music_volume_linear)
	_save_data()

func set_sfx_volume_linear(value: float) -> void:
	sfx_volume_linear = clampf(value, 0.0, 1.0)
	_set_bus_volume("SFX", sfx_volume_linear)
	_save_data()

func get_music_volume_linear() -> float:
	return music_volume_linear

func get_sfx_volume_linear() -> float:
	return sfx_volume_linear

func _find_offer(offer_id: String) -> Dictionary:
	for offer in SHOP_ITEMS:
		if String(offer.get("id", "")) == offer_id:
			return offer
	for offer in SHOP_AMULETS:
		if String(offer.get("id", "")) == offer_id:
			return offer
	return {}

func _save_data() -> void:
	var data := {
		"coins": coins,
		"tokens": tokens,
		"unlocked_worlds": unlocked_worlds,
		"unlocked_levels": unlocked_levels,
		"completed_levels": completed_levels,
		"consumable_inventory": consumable_inventory,
		"owned_amulets": owned_amulets,
		"equipped_amulet": equipped_amulet,
		"equipped_amulets": equipped_amulets,
		"amulet_slots_unlocked": amulet_slots_unlocked,
		"music_volume_linear": music_volume_linear,
		"sfx_volume_linear": sfx_volume_linear,
		"xp_level": xp_level,
		"xp_current": xp_current,
		"xp_to_next_level": xp_to_next_level
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))

func _load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_save_data()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var raw := file.get_as_text()
	var json := JSON.new()
	if json.parse(raw) != OK:
		return
	var data: Dictionary = json.data
	coins = int(data.get("coins", coins))
	tokens = int(data.get("tokens", tokens))
	unlocked_worlds = int(data.get("unlocked_worlds", unlocked_worlds))
	var loaded_levels: Dictionary = data.get("unlocked_levels", {})
	var normalized_levels: Dictionary = {}
	for key in loaded_levels.keys():
		normalized_levels[int(key)] = int(loaded_levels[key])
	for world in range(1, WORLD_COUNT + 1):
		if not normalized_levels.has(world):
			normalized_levels[world] = (1 if world == 1 else 0)
	unlocked_levels = normalized_levels
	var loaded_completed: Array = data.get("completed_levels", [])
	completed_levels.clear()
	for entry in loaded_completed:
		completed_levels.append(String(entry))
	var loaded_inventory: Dictionary = data.get("consumable_inventory", {})
	consumable_inventory["health"] = int(loaded_inventory.get("health", consumable_inventory.get("health", 0)))
	consumable_inventory["energy"] = int(loaded_inventory.get("energy", consumable_inventory.get("energy", 0)))
	var loaded_amulets: Array = data.get("owned_amulets", [])
	owned_amulets.clear()
	for amulet in loaded_amulets:
		owned_amulets.append(String(amulet))
	equipped_amulet = String(data.get("equipped_amulet", equipped_amulet))
	var loaded_equipped: Array = data.get("equipped_amulets", [])
	equipped_amulets.clear()
	for entry in loaded_equipped:
		equipped_amulets.append(String(entry))
	amulet_slots_unlocked = max(3, int(data.get("amulet_slots_unlocked", amulet_slots_unlocked)))
	while equipped_amulets.size() < amulet_slots_unlocked:
		equipped_amulets.append("")
	if equipped_amulets.is_empty() and equipped_amulet != "":
		equipped_amulets.append(equipped_amulet)
	if equipped_amulets.size() > amulet_slots_unlocked:
		equipped_amulets.resize(amulet_slots_unlocked)
	if not equipped_amulets.is_empty():
		equipped_amulet = String(equipped_amulets[0])
	else:
		equipped_amulet = ""
	music_volume_linear = float(data.get("music_volume_linear", music_volume_linear))
	sfx_volume_linear = float(data.get("sfx_volume_linear", sfx_volume_linear))
	xp_level = max(1, int(data.get("xp_level", xp_level)))
	xp_to_next_level = maxf(1.0, float(data.get("xp_to_next_level", xp_to_next_level)))
	xp_current = clampf(float(data.get("xp_current", xp_current)), 0.0, xp_to_next_level)

func _ensure_audio_buses() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus(AudioServer.get_bus_count())
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "Music")
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus(AudioServer.get_bus_count())
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "SFX")

func _apply_audio_settings() -> void:
	_set_bus_volume("Music", music_volume_linear)
	_set_bus_volume("SFX", sfx_volume_linear)

func _set_bus_volume(bus_name: String, linear_value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	var db := linear_to_db(maxf(0.0001, linear_value))
	AudioServer.set_bus_volume_db(idx, db)
