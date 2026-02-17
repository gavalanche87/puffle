extends "res://scripts/ui/menu_transitions.gd"
signal overlay_closed(from_pause_menu: bool)

const NAV_BUTTON_SCENE := preload("res://scenes/ui/NavButton.tscn")
const ICON_SIZE_SHIFT: Texture2D = preload("res://assets/ui/amulets/Shift_Size_Amulet.png")
const ICON_HEAD_SPIKE: Texture2D = preload("res://assets/ui/amulets/Head_Spike_Amulet.png")
const ICON_DOUBLE_JUMP: Texture2D = preload("res://assets/ui/amulets/Double_Jump_Amulet.png")
const AMULET_ICON_MAP := {
	"size_shift": ICON_SIZE_SHIFT,
	"head_spike": ICON_HEAD_SPIKE,
	"double_jump": ICON_DOUBLE_JUMP
}

@onready var back_button: Button = $Layout/VBox/Header/BackButton
@onready var slots_section: Panel = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/RightSlotsSection
@onready var slot_1: VBoxContainer = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/RightSlotsSection/Margin/SlotsScroll/SlotsRow/Slot1
@onready var slot_2: VBoxContainer = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/RightSlotsSection/Margin/SlotsScroll/SlotsRow/Slot2
@onready var slot_3: VBoxContainer = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/RightSlotsSection/Margin/SlotsScroll/SlotsRow/Slot3
@onready var owned_list: VBoxContainer = $Layout/VBox/OwnedSection/OwnedMargin/Split/Left/OwnedScroll/OwnedList
@onready var selected_title: Label = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/SelectedRow/SelectedTitle
@onready var selected_icon: TextureRect = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/SelectedRow/SelectedIcon
@onready var boon_label: Label = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/BoonLabel
@onready var grievance_label: Label = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/GrievanceLabel

var _selected_amulet_id: String = ""
var _manage_mode: bool = false
var _overlay_mode: bool = false
var _opened_from_pause_menu: bool = false

func set_overlay_mode(enabled: bool, from_pause_menu: bool) -> void:
	_overlay_mode = enabled
	_opened_from_pause_menu = from_pause_menu

func _ready() -> void:
	super._ready()
	var gd: Node = get_node_or_null("/root/GameData")
	if gd and gd.has_method("get_amulet_screen_manage_mode"):
		_manage_mode = bool(gd.call("get_amulet_screen_manage_mode"))
	if gd and gd.has_signal("amulets_changed"):
		if not gd.amulets_changed.is_connected(_refresh):
			gd.amulets_changed.connect(_refresh)
	back_button.pressed.connect(_on_back_pressed)
	_bind_slot_buttons(slot_1, 0)
	_bind_slot_buttons(slot_2, 1)
	_bind_slot_buttons(slot_3, 2)
	_refresh()

func _bind_slot_buttons(slot_node: VBoxContainer, slot_index: int) -> void:
	var action_btn: Button = slot_node.get_node("ActionButton")
	action_btn.pressed.connect(func() -> void:
		_on_slot_action_pressed(slot_index)
	)

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

func _refresh() -> void:
	var gd: Node = get_node_or_null("/root/GameData")
	if not gd:
		return
	slots_section.visible = _manage_mode
	_clear_owned_list()
	var owned: Array = gd.call("get_owned_amulets")
	var catalog: Array = gd.call("get_amulet_catalog")
	var selected_exists := false
	for entry_variant in catalog:
		var entry: Dictionary = entry_variant
		var amulet_id := String(entry.get("id", ""))
		if not owned.has(amulet_id):
			continue
		selected_exists = selected_exists or amulet_id == _selected_amulet_id
		_add_owned_button(entry)
	if not selected_exists:
		_selected_amulet_id = String(owned[0]) if not owned.is_empty() else ""
	_update_details(gd)
	_update_slot_ui(gd)

func _add_owned_button(entry: Dictionary) -> void:
	var amulet_id := String(entry.get("id", ""))
	var b := NAV_BUTTON_SCENE.instantiate() as Button
	if b == null:
		return
	b.text = String(entry.get("title", amulet_id))
	b.icon = _get_amulet_icon(amulet_id)
	b.expand_icon = true
	b.modulate = Color(0.98, 0.92, 0.56, 1.0) if _selected_amulet_id == amulet_id else Color(1, 1, 1, 1)
	b.pressed.connect(func() -> void:
		_selected_amulet_id = amulet_id
		_refresh()
	)
	owned_list.add_child(b)

func _update_details(gd: Node) -> void:
	if _selected_amulet_id == "":
		selected_title.text = "No Amulet Selected"
		selected_icon.texture = null
		boon_label.text = "Boon:"
		grievance_label.text = "Grievance:"
		return
	var catalog: Array = gd.call("get_amulet_catalog")
	for entry_variant in catalog:
		var entry: Dictionary = entry_variant
		if String(entry.get("id", "")) != _selected_amulet_id:
			continue
		selected_title.text = String(entry.get("title", _selected_amulet_id))
		selected_icon.texture = _get_amulet_icon(_selected_amulet_id)
		boon_label.text = "Boon: %s" % String(entry.get("boon", ""))
		grievance_label.text = "Grievance: %s" % String(entry.get("grievance", ""))
		return

func _update_slot_ui(gd: Node) -> void:
	var equipped: Array = gd.call("get_equipped_amulets")
	var unlocked: int = int(gd.call("get_amulet_slots_unlocked"))
	_apply_slot(slot_1, 0, unlocked, equipped, gd)
	_apply_slot(slot_2, 1, unlocked, equipped, gd)
	_apply_slot(slot_3, 2, unlocked, equipped, gd)

func _apply_slot(slot_node: VBoxContainer, slot_index: int, unlocked: int, equipped: Array, gd: Node) -> void:
	slot_node.visible = slot_index < unlocked
	if not slot_node.visible:
		return
	var equipped_id := String(equipped[slot_index]) if equipped.size() > slot_index else ""
	var icon: TextureRect = slot_node.get_node("Backing/Icon")
	var value: Label = slot_node.get_node("Value")
	var action_btn: Button = slot_node.get_node("ActionButton")
	icon.texture = _get_amulet_icon(equipped_id)
	var slot_text := _get_amulet_title(gd, equipped_id) if equipped_id != "" else "Empty"
	var owned: Array = gd.call("get_owned_amulets")
	if equipped_id == "":
		var already_equipped_elsewhere := _selected_amulet_id != "" and equipped.has(_selected_amulet_id)
		action_btn.disabled = (not _manage_mode) or _selected_amulet_id == "" or (not owned.has(_selected_amulet_id)) or already_equipped_elsewhere
		action_btn.text = "EQUIP"
		value.text = "Slot %d: %s" % [slot_index + 1, slot_text]
	else:
		action_btn.disabled = not _manage_mode
		action_btn.text = "UNEQUIP"
		value.text = "Slot %d: %s" % [slot_index + 1, slot_text]

func _on_slot_action_pressed(slot_index: int) -> void:
	var gd: Node = get_node_or_null("/root/GameData")
	if not gd:
		return
	var equipped: Array = gd.call("get_equipped_amulets")
	var slot_value := String(equipped[slot_index]) if equipped.size() > slot_index else ""
	if slot_value != "":
		gd.call("unequip_amulet", slot_index)
		_refresh()
		return
	if _selected_amulet_id == "":
		return
	if equipped.has(_selected_amulet_id):
		return
	gd.call("equip_amulet", _selected_amulet_id, slot_index)
	_refresh()

func _clear_owned_list() -> void:
	for child in owned_list.get_children():
		child.queue_free()

func _get_amulet_icon(amulet_id: String) -> Texture2D:
	return AMULET_ICON_MAP.get(amulet_id, null)

func _get_amulet_title(gd: Node, amulet_id: String) -> String:
	if amulet_id == "":
		return ""
	var catalog: Array = gd.call("get_amulet_catalog")
	for entry_variant in catalog:
		var entry: Dictionary = entry_variant
		if String(entry.get("id", "")) == amulet_id:
			return String(entry.get("title", amulet_id))
	return amulet_id
