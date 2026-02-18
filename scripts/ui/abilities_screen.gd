extends "res://scripts/ui/menu_transitions.gd"

const NAV_BUTTON_SCENE := preload("res://scenes/ui/NavButton.tscn")
const ICON_SIZE_SHIFT: Texture2D = preload("res://assets/ui/abilities/Shift_Size_Ability.png")
const ICON_DOUBLE_JUMP: Texture2D = preload("res://assets/ui/abilities/Double_Jump_Ability.png")
const ABILITY_ICON_MAP := {
	"size_shift": ICON_SIZE_SHIFT,
	"double_jump": ICON_DOUBLE_JUMP
}

@onready var back_button: Button = $Layout/VBox/Header/BackButton
@onready var background: ColorRect = $Background
@onready var header: Control = $Layout/VBox/Header
@onready var owned_list: VBoxContainer = $Layout/VBox/OwnedSection/OwnedMargin/Split/Left/OwnedScroll/OwnedList
@onready var selected_title: Label = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/SelectedRow/SelectedTitle
@onready var selected_icon: TextureRect = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/SelectedRow/SelectedIcon
@onready var boon_label: Label = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/BoonLabel
@onready var grievance_label: Label = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/GrievanceLabel
@onready var slots_section: Panel = $Layout/VBox/OwnedSection/OwnedMargin/Split/Right/RightSlotsSection

var _selected_ability_id: String = ""
var _embedded_mode: bool = false

func set_embedded_mode(enabled: bool) -> void:
	_embedded_mode = enabled
	if is_inside_tree():
		_apply_embedded_mode()

func _ready() -> void:
	super._ready()
	if back_button:
		back_button.pressed.connect(func() -> void:
			go_to_scene("res://scenes/ui/Character.tscn")
		)
	_apply_embedded_mode()
	_refresh()

func _apply_embedded_mode() -> void:
	if background:
		background.visible = not _embedded_mode
	if header:
		header.visible = not _embedded_mode
	if slots_section:
		slots_section.visible = false

func _refresh() -> void:
	var gd: Node = get_node_or_null("/root/GameData")
	if not gd:
		return
	_clear_owned_list()
	var owned: Array = gd.call("get_owned_abilities")
	var catalog: Array = gd.call("get_ability_catalog")
	var selected_exists := false
	for entry_variant in catalog:
		var entry: Dictionary = entry_variant
		var ability_id := String(entry.get("id", ""))
		if not owned.has(ability_id):
			continue
		selected_exists = selected_exists or ability_id == _selected_ability_id
		_add_owned_button(entry)
	if not selected_exists:
		_selected_ability_id = String(owned[0]) if not owned.is_empty() else ""
	_update_details(gd)

func _add_owned_button(entry: Dictionary) -> void:
	var ability_id := String(entry.get("id", ""))
	var button: Button = NAV_BUTTON_SCENE.instantiate() as Button
	if button == null:
		return
	button.text = String(entry.get("title", ability_id))
	button.icon = _get_ability_icon(ability_id)
	button.expand_icon = true
	button.modulate = Color(0.98, 0.92, 0.56, 1.0) if _selected_ability_id == ability_id else Color(1, 1, 1, 1)
	button.pressed.connect(func() -> void:
		_selected_ability_id = ability_id
		_refresh()
	)
	owned_list.add_child(button)

func _update_details(gd: Node) -> void:
	if _selected_ability_id == "":
		selected_title.text = "No Ability Selected"
		selected_icon.texture = null
		boon_label.text = "Boon:"
		grievance_label.text = "Grievance:"
		return
	var catalog: Array = gd.call("get_ability_catalog")
	for entry_variant in catalog:
		var entry: Dictionary = entry_variant
		if String(entry.get("id", "")) != _selected_ability_id:
			continue
		selected_title.text = String(entry.get("title", _selected_ability_id))
		selected_icon.texture = _get_ability_icon(_selected_ability_id)
		boon_label.text = "Boon: %s" % String(entry.get("boon", ""))
		grievance_label.text = "Grievance: %s" % String(entry.get("grievance", ""))
		return

func _clear_owned_list() -> void:
	for child in owned_list.get_children():
		child.queue_free()

func _get_ability_icon(ability_id: String) -> Texture2D:
	return ABILITY_ICON_MAP.get(ability_id, null)
