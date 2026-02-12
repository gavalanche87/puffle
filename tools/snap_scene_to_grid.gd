@tool
extends EditorScript

const GRID_SIZE := Vector2(32.0, 32.0)

func _run() -> void:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		push_warning("No scene is open.")
		return

	var world := root.find_child("World", true, false)
	if world == null:
		push_warning("Could not find a node named 'World' in the current scene.")
		return

	var undo_redo = get_editor_interface().get_editor_undo_redo()
	undo_redo.create_action("Snap World Bodies To 32x32 Grid")

	var snapped := _snap_recursive(world, undo_redo)

	undo_redo.commit_action()
	print("Snapped %d nodes under 'World' to 32x32 grid." % snapped)


func _snap_recursive(node: Node, undo_redo) -> int:
	var count := 0

	if node is CharacterBody2D or node is Area2D or node is StaticBody2D:
		var n := node as Node2D
		var old_pos := n.global_position
		var new_pos := old_pos.snapped(GRID_SIZE)
		if old_pos != new_pos:
			undo_redo.add_do_property(n, "global_position", new_pos)
			undo_redo.add_undo_property(n, "global_position", old_pos)
			count += 1

	for child in node.get_children():
		count += _snap_recursive(child, undo_redo)

	return count
