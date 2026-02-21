extends Node

signal data_changed
signal progression_changed
signal currencies_changed
signal inventory_changed
signal amulets_changed
signal abilities_changed
signal weapons_changed

const SAVE_PATH := "user://save_data.json"
const LEVEL_SELECT_SCENE := "res://scenes/ui/LevelSelect.tscn"

const WORLD_COUNT := 3
const LEVELS_PER_WORLD := 10

const ABILITY_SIZE_SHIFT := "size_shift"
const ABILITY_DOUBLE_JUMP := "double_jump"
const ABILITY_WALL_JUMP := "wall_jump"
const ABILITY_HEADBUTT := "headbutt"
const AMULET_LEAP_OF_FAITH := "leap_of_faith"
const WEAPON_HEAD_SPIKE := "head_spike"
const MUSIC_TRACK_LEVEL_1 := "level_music_1"

var coins: int = 0
var tokens: int = 3
var unlocked_worlds: int = 1
var unlocked_levels: Dictionary = {1: 1, 2: 0, 3: 0}
var completed_levels: Array[String] = []
var consumable_inventory: Dictionary = {"health": 0, "energy": 0}

var owned_abilities: Array[String] = []
var owned_amulets: Array[String] = []
var owned_weapons: Array[String] = []

var equipped_amulets: Array[String] = []
var amulet_slots_unlocked: int = 3
var equipped_weapon: String = ""
var unlocked_music_tracks: Array[String] = [MUSIC_TRACK_LEVEL_1]

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

const SHOP_ABILITIES := [
	{
		"id": ABILITY_SIZE_SHIFT,
		"kind": "ability",
		"title": "Size Shift",
		"description": "Boon: Toggle Big/Small Mode",
		"currency": "tokens",
		"cost": 2
	},
	{
		"id": ABILITY_DOUBLE_JUMP,
		"kind": "ability",
		"title": "Double Jump",
		"description": "Boon: Gain one extra jump in mid-air",
		"currency": "tokens",
		"cost": 3
	},
	{
		"id": ABILITY_WALL_JUMP,
		"kind": "ability",
		"title": "Wall Jump",
		"description": "Boon: Enables wall slide and wall jump",
		"currency": "tokens",
		"cost": 3
	},
	{
		"id": ABILITY_HEADBUTT,
		"kind": "ability",
		"title": "Headbutt",
		"description": "Boon: Press C to dash attack (requires Head Spike)",
		"currency": "tokens",
		"cost": 4
	}
]

const SHOP_AMULETS := [
	{
		"id": AMULET_LEAP_OF_FAITH,
		"kind": "amulet",
		"title": "Leap of Faith",
		"description": "Boon: Jump Height x2 | Grievance: Hazard Damage x1.2",
		"currency": "tokens",
		"cost": 3
	}
]

const SHOP_WEAPONS := [
	{
		"id": WEAPON_HEAD_SPIKE,
		"kind": "weapon",
		"title": "Head Spike",
		"description": "Boon: Head-mounted spike attack",
		"currency": "tokens",
		"cost": 3
	}
]

const SHOP_MUSIC_TRACKS := [
	{
		"id": "level_music_1",
		"kind": "music_track",
		"title": "Level Music 1",
		"description": "Gameplay music track",
		"currency": "tokens",
		"cost": 0
	},
	{
		"id": "level_music_2",
		"kind": "music_track",
		"title": "Level Music 2",
		"description": "Gameplay music track",
		"currency": "tokens",
		"cost": 2
	},
	{
		"id": "level_music_3",
		"kind": "music_track",
		"title": "Level Music 3",
		"description": "Gameplay music track",
		"currency": "tokens",
		"cost": 2
	},
	{
		"id": "level_music_4",
		"kind": "music_track",
		"title": "Level Music 4",
		"description": "Gameplay music track",
		"currency": "tokens",
		"cost": 3
	},
	{
		"id": "level_music_5",
		"kind": "music_track",
		"title": "Level Music 5",
		"description": "Gameplay music track",
		"currency": "tokens",
		"cost": 3
	},
	{
		"id": "level_music_6",
		"kind": "music_track",
		"title": "Level Music 6",
		"description": "Gameplay music track",
		"currency": "tokens",
		"cost": 4
	}
]

const MUSIC_TRACK_PATHS := {
	"level_music_1": "res://assets/sound/level_music_1.mp3",
	"level_music_2": "res://assets/sound/level_music_2.mp3",
	"level_music_3": "res://assets/sound/level_music_3.mp3",
	"level_music_4": "res://assets/sound/level_music_4.mp3",
	"level_music_5": "res://assets/sound/level_music_5.mp3",
	"level_music_6": "res://assets/sound/level_music_6.mp3"
}

const ABILITY_INFO := {
	ABILITY_SIZE_SHIFT: {
		"title": "Size Shift",
		"boon": "Toggle Big and Small form with Z",
		"grievance": "None",
		"shop_cost_tokens": 2
	},
	ABILITY_DOUBLE_JUMP: {
		"title": "Double Jump",
		"boon": "Gain one extra jump in mid-air",
		"grievance": "None",
		"shop_cost_tokens": 3
	},
	ABILITY_WALL_JUMP: {
		"title": "Wall Jump",
		"boon": "Enables wall slide and wall jump",
		"grievance": "None",
		"shop_cost_tokens": 3
	},
	ABILITY_HEADBUTT: {
		"title": "Headbutt",
		"boon": "Press C to perform a headbutt dash (requires Head Spike equipped)",
		"grievance": "Consumes Energy per use",
		"shop_cost_tokens": 4
	}
}

const AMULET_INFO := {
	AMULET_LEAP_OF_FAITH: {
		"title": "Leap of Faith",
		"boon": "Jump height increased x2",
		"grievance": "Take 20% more damage from hazards",
		"shop_cost_tokens": 3
	}
}

const WEAPON_INFO := {
	WEAPON_HEAD_SPIKE: {
		"title": "Head Spike",
		"boon": "Enable head spike attacks",
		"grievance": "Destroy platforms only in Big Mode",
		"shop_cost_tokens": 3
	}
}

func _ready() -> void:
	_ensure_audio_buses()
	_load_data()
	_apply_audio_settings()

func wipe_save_data() -> void:
	coins = 0
	tokens = 3
	unlocked_worlds = 1
	unlocked_levels = {1: 1, 2: 0, 3: 0}
	completed_levels.clear()
	consumable_inventory = {"health": 0, "energy": 0}
	owned_abilities.clear()
	owned_amulets.clear()
	owned_weapons.clear()
	equipped_amulets.clear()
	amulet_slots_unlocked = 3
	equipped_weapon = ""
	unlocked_music_tracks = [MUSIC_TRACK_LEVEL_1]
	current_world = 0
	current_level = 0
	level_flow_active = false
	xp_level = 1
	xp_current = 0.0
	xp_to_next_level = 100.0
	amulet_screen_manage_mode = false
	amulet_return_scene_path = ""
	amulet_return_to_pause = false
	open_pause_on_next_hud = false
	_save_data()
	emit_signal("progression_changed")
	emit_signal("currencies_changed")
	emit_signal("inventory_changed")
	emit_signal("amulets_changed")
	emit_signal("abilities_changed")
	emit_signal("weapons_changed")
	emit_signal("data_changed")

func get_shop_items() -> Array:
	return SHOP_ITEMS.duplicate(true)

func get_shop_abilities() -> Array:
	return SHOP_ABILITIES.duplicate(true)

func get_shop_amulets() -> Array:
	return SHOP_AMULETS.duplicate(true)

func get_shop_weapons() -> Array:
	return SHOP_WEAPONS.duplicate(true)

func get_shop_music_tracks() -> Array:
	return SHOP_MUSIC_TRACKS.duplicate(true)

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
		"res://scenes/levels/world_1/Level_1_1.tscn",
		"res://scenes/levels/test/MainLevel.tscn",
		"res://scenes/levels/test/VerticalTestScene.tscn"
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

	var kind := String(offer.get("kind", ""))
	var id := String(offer.get("id", ""))
	if kind == "amulet":
		if owned_amulets.has(id):
			return {"ok": false, "message": "Already owned"}
		owned_amulets.append(id)
	elif kind == "ability":
		if owned_abilities.has(id):
			return {"ok": false, "message": "Already owned"}
		owned_abilities.append(id)
	elif kind == "weapon":
		if owned_weapons.has(id):
			return {"ok": false, "message": "Already owned"}
		owned_weapons.append(id)
	elif kind == "music_track":
		if unlocked_music_tracks.has(id):
			return {"ok": false, "message": "Already owned"}
		unlocked_music_tracks.append(id)
	else:
		var inv_key := String(offer.get("inventory_key", ""))
		if inv_key != "":
			consumable_inventory[inv_key] = int(consumable_inventory.get(inv_key, 0)) + 1

	add_currency(currency, -cost, false)
	_save_data()
	emit_signal("inventory_changed")
	emit_signal("currencies_changed")
	emit_signal("amulets_changed")
	emit_signal("abilities_changed")
	emit_signal("weapons_changed")
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

func has_ability(ability_id: String) -> bool:
	return owned_abilities.has(ability_id)

func get_ability_catalog() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for offer in SHOP_ABILITIES:
		var id := String(offer.get("id", ""))
		var info: Dictionary = ABILITY_INFO.get(id, {})
		out.append({
			"id": id,
			"title": String(info.get("title", String(offer.get("title", id)))),
			"boon": String(info.get("boon", "")),
			"grievance": String(info.get("grievance", "")),
			"cost_tokens": int(info.get("shop_cost_tokens", int(offer.get("cost", 0))))
		})
	return out

func get_owned_abilities() -> Array[String]:
	return owned_abilities.duplicate()

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
	_save_data()
	emit_signal("amulets_changed")
	emit_signal("inventory_changed")
	emit_signal("data_changed")
	return {"ok": true, "message": "Unequipped"}

func has_weapon(weapon_id: String) -> bool:
	return owned_weapons.has(weapon_id)

func get_weapon_catalog() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for offer in SHOP_WEAPONS:
		var id := String(offer.get("id", ""))
		var info: Dictionary = WEAPON_INFO.get(id, {})
		out.append({
			"id": id,
			"title": String(info.get("title", String(offer.get("title", id)))),
			"boon": String(info.get("boon", "")),
			"grievance": String(info.get("grievance", "")),
			"cost_tokens": int(info.get("shop_cost_tokens", int(offer.get("cost", 0))))
		})
	return out

func get_owned_weapons() -> Array[String]:
	return owned_weapons.duplicate()

func get_equipped_weapon() -> String:
	return equipped_weapon

func is_weapon_equipped(weapon_id: String) -> bool:
	return equipped_weapon == weapon_id and weapon_id != ""

func has_music_track(track_id: String) -> bool:
	return unlocked_music_tracks.has(track_id)

func get_unlocked_music_tracks() -> Array[String]:
	var out: Array[String] = []
	for track_id_variant in unlocked_music_tracks:
		var track_id := String(track_id_variant)
		if MUSIC_TRACK_PATHS.has(track_id):
			out.append(track_id)
	if out.is_empty():
		out.append(MUSIC_TRACK_LEVEL_1)
	return out

func get_music_track_path(track_id: String) -> String:
	return String(MUSIC_TRACK_PATHS.get(track_id, MUSIC_TRACK_PATHS[MUSIC_TRACK_LEVEL_1]))

func equip_weapon(weapon_id: String) -> Dictionary:
	if not has_weapon(weapon_id):
		return {"ok": false, "message": "Weapon not owned"}
	equipped_weapon = weapon_id
	_save_data()
	emit_signal("weapons_changed")
	emit_signal("inventory_changed")
	emit_signal("data_changed")
	return {"ok": true, "message": "Equipped %s" % weapon_id}

func unequip_weapon() -> Dictionary:
	equipped_weapon = ""
	_save_data()
	emit_signal("weapons_changed")
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
	for offer in SHOP_ABILITIES:
		if String(offer.get("id", "")) == offer_id:
			return offer
	for offer in SHOP_AMULETS:
		if String(offer.get("id", "")) == offer_id:
			return offer
	for offer in SHOP_WEAPONS:
		if String(offer.get("id", "")) == offer_id:
			return offer
	for offer in SHOP_MUSIC_TRACKS:
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
		"owned_abilities": owned_abilities,
		"owned_amulets": owned_amulets,
		"owned_weapons": owned_weapons,
		"equipped_amulets": equipped_amulets,
		"amulet_slots_unlocked": amulet_slots_unlocked,
		"equipped_weapon": equipped_weapon,
		"unlocked_music_tracks": unlocked_music_tracks,
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

	owned_abilities.clear()
	owned_amulets.clear()
	owned_weapons.clear()
	equipped_amulets.clear()

	var loaded_abilities: Array = data.get("owned_abilities", [])
	for ability in loaded_abilities:
		var ability_id := String(ability)
		if not owned_abilities.has(ability_id):
			owned_abilities.append(ability_id)

	var loaded_amulets: Array = data.get("owned_amulets", [])
	for amulet in loaded_amulets:
		var amulet_id := String(amulet)
		if amulet_id == "size_shift":
			if not owned_abilities.has(ABILITY_SIZE_SHIFT):
				owned_abilities.append(ABILITY_SIZE_SHIFT)
			continue
		if amulet_id == "double_jump":
			if not owned_abilities.has(ABILITY_DOUBLE_JUMP):
				owned_abilities.append(ABILITY_DOUBLE_JUMP)
			continue
		if amulet_id == "head_spike":
			if not owned_weapons.has(WEAPON_HEAD_SPIKE):
				owned_weapons.append(WEAPON_HEAD_SPIKE)
			continue
		if AMULET_INFO.has(amulet_id) and not owned_amulets.has(amulet_id):
			owned_amulets.append(amulet_id)

	var loaded_weapons: Array = data.get("owned_weapons", [])
	for weapon in loaded_weapons:
		var weapon_id := String(weapon)
		if WEAPON_INFO.has(weapon_id) and not owned_weapons.has(weapon_id):
			owned_weapons.append(weapon_id)

	var loaded_equipped: Array = data.get("equipped_amulets", [])
	if loaded_equipped.is_empty():
		var legacy_equipped := String(data.get("equipped_amulet", ""))
		if legacy_equipped != "":
			loaded_equipped.append(legacy_equipped)
	for entry in loaded_equipped:
		var equipped_id := String(entry)
		if equipped_id == "head_spike":
			equipped_weapon = WEAPON_HEAD_SPIKE
			continue
		if equipped_id == "size_shift" or equipped_id == "double_jump":
			continue
		if owned_amulets.has(equipped_id):
			equipped_amulets.append(equipped_id)

	amulet_slots_unlocked = max(3, int(data.get("amulet_slots_unlocked", amulet_slots_unlocked)))
	while equipped_amulets.size() < amulet_slots_unlocked:
		equipped_amulets.append("")
	if equipped_amulets.size() > amulet_slots_unlocked:
		equipped_amulets.resize(amulet_slots_unlocked)

	var loaded_equipped_weapon := String(data.get("equipped_weapon", equipped_weapon))
	if loaded_equipped_weapon != "" and owned_weapons.has(loaded_equipped_weapon):
		equipped_weapon = loaded_equipped_weapon
	elif equipped_weapon != "" and not owned_weapons.has(equipped_weapon):
		equipped_weapon = ""

	unlocked_music_tracks.clear()
	var loaded_tracks: Array = data.get("unlocked_music_tracks", [MUSIC_TRACK_LEVEL_1])
	for track_variant in loaded_tracks:
		var track_id := String(track_variant)
		if MUSIC_TRACK_PATHS.has(track_id) and not unlocked_music_tracks.has(track_id):
			unlocked_music_tracks.append(track_id)
	if not unlocked_music_tracks.has(MUSIC_TRACK_LEVEL_1):
		unlocked_music_tracks.insert(0, MUSIC_TRACK_LEVEL_1)

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
