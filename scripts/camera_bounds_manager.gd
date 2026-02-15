extends Node
class_name CameraBoundsManager

## Automatically configures camera bounds based on level geometry
## Reusable across all levels - no hardcoded values

## Finds the leftmost wall in the level
func _find_leftmost_wall() -> Node2D:
	var walls = get_tree().get_nodes_in_group("level_boundary_left")
	if not walls.is_empty():
		return walls[0]
	
	# Fallback: find all Wall nodes and return leftmost
	var all_walls = []
	_find_nodes_by_script(get_tree().root, "res://scripts/tiled_body.gd", all_walls)
	
	var leftmost: Node2D = null
	var leftmost_x = INF
	for wall in all_walls:
		if wall.get("body_type") == "wall":
			if wall.global_position.x < leftmost_x:
				leftmost_x = wall.global_position.x
				leftmost = wall
	return leftmost

## Finds the rightmost wall in the level
func _find_rightmost_wall() -> Node2D:
	var walls = get_tree().get_nodes_in_group("level_boundary_right")
	if not walls.is_empty():
		return walls[0]
	
	# Fallback: find all Wall nodes and return rightmost
	var all_walls = []
	_find_nodes_by_script(get_tree().root, "res://scripts/tiled_body.gd", all_walls)
	
	var rightmost: Node2D = null
	var rightmost_x = - INF
	for wall in all_walls:
		if wall.get("body_type") == "wall":
			if wall.global_position.x > rightmost_x:
				rightmost_x = wall.global_position.x
				rightmost = wall
	return rightmost

## Finds the lowest ground in the level
func _find_lowest_ground() -> Node2D:
	var grounds = get_tree().get_nodes_in_group("level_boundary_bottom")
	if not grounds.is_empty():
		# Return the lowest one if multiple
		var lowest_ground: Node2D = grounds[0]
		var lowest_ground_y = grounds[0].global_position.y
		for ground in grounds:
			if ground.global_position.y > lowest_ground_y:
				lowest_ground_y = ground.global_position.y
				lowest_ground = ground
		return lowest_ground
	
	# Fallback: find all Ground nodes and return lowest
	var all_grounds = []
	_find_nodes_by_script(get_tree().root, "res://scripts/tiled_body.gd", all_grounds)
	
	var lowest: Node2D = null
	var lowest_y = - INF
	for ground in all_grounds:
		if ground.get("body_type") == "ground":
			if ground.global_position.y > lowest_y:
				lowest_y = ground.global_position.y
				lowest = ground
	return lowest

## Helper to find nodes with a specific script
func _find_nodes_by_script(node: Node, script_path: String, result: Array) -> void:
	if node.get_script() and node.get_script().resource_path == script_path:
		result.append(node)
	for child in node.get_children():
		_find_nodes_by_script(child, script_path, result)

## Gets the right edge of a tiled body (wall or ground)
func _get_right_edge(body: Node2D) -> float:
	var width = 32.0 # Default tile size
	if body.has_method("get") and body.get("length_tiles"):
		var length = body.get("length_tiles")
		var scale_x = body.scale.x if body.scale else 1.0
		var body_type = body.get("body_type")
		
		if body_type == "wall":
			# Walls are vertical, width is the tile size
			width = 32.0 * scale_x
		else:
			# Ground/platform is horizontal
			width = length * 32.0 * scale_x
	
	return body.global_position.x + (width / 2.0)

## Gets the left edge of a tiled body
func _get_left_edge(body: Node2D) -> float:
	var width = 32.0 # Default tile size
	if body.has_method("get") and body.get("length_tiles"):
		var length = body.get("length_tiles")
		var scale_x = body.scale.x if body.scale else 1.0
		var body_type = body.get("body_type")
		
		if body_type == "wall":
			width = 32.0 * scale_x
		else:
			width = length * 32.0 * scale_x
	
	return body.global_position.x - (width / 2.0)

## Gets the top edge of a tiled body
func _get_top_edge(body: Node2D) -> float:
	var height = 32.0 # Default tile size
	var scale_y = body.scale.y if body.scale else 1.0
	height *= scale_y
	
	return body.global_position.y - (height / 2.0)

## Main function to setup camera bounds
func setup_camera_bounds(camera: Camera2D, player: Node2D = null) -> void:
	if not camera:
		push_warning("CameraBoundsManager: No camera provided")
		return
	
	# Get viewport size dynamically
	var viewport = get_viewport()
	if not viewport:
		push_warning("CameraBoundsManager: No viewport found")
		return
	
	var viewport_size = viewport.get_visible_rect().size
	var zoom = camera.zoom.x # Assuming uniform zoom
	
	if player:
		print("  Player position: %v" % [player.global_position])
	
	# Find level boundaries
	var left_wall = _find_leftmost_wall()
	var right_wall = _find_rightmost_wall()
	var bottom_ground = _find_lowest_ground()
	
	# Calculate and set camera limits
	# Godot's camera limits work in screen space - just set them to the sprite edges
	
	if left_wall:
		var wall_left = _get_left_edge(left_wall)
		var wall_right = _get_right_edge(left_wall)
		camera.limit_left = int(wall_left)
		print("  Left Wall: pos=%v, left_edge=%.1f, right_edge=%.1f, limit_left=%d" %
			[left_wall.global_position, wall_left, wall_right, camera.limit_left])
	else:
		push_warning("CameraBoundsManager: No left wall found")
	
	if right_wall:
		var wall_left = _get_left_edge(right_wall)
		var wall_right = _get_right_edge(right_wall)
		camera.limit_right = int(wall_right)
		print("  Right Wall: pos=%v, left_edge=%.1f, right_edge=%.1f, limit_right=%d" %
			[right_wall.global_position, wall_left, wall_right, camera.limit_right])
	else:
		push_warning("CameraBoundsManager: No right wall found")
	
	if bottom_ground:
		var ground_top = _get_top_edge(bottom_ground)
		var ground_bottom = bottom_ground.global_position.y + 16.0 # Approximate
		camera.limit_bottom = int(ground_top)
		print("  Bottom Ground: pos=%v, top_edge=%.1f, bottom_edge=%.1f, limit_bottom=%d" %
			[bottom_ground.global_position, ground_top, ground_bottom, camera.limit_bottom])
	else:
		push_warning("CameraBoundsManager: No bottom ground found")
	
	# Set reasonable top limit (allow upward movement)
	camera.limit_top = -10000
	
	print("CameraBoundsManager: Bounds set - Left: %d, Right: %d, Bottom: %d, Top: %d" %
		[camera.limit_left, camera.limit_right, camera.limit_bottom, camera.limit_top])
	print("  Viewport: %v, Zoom: %.3f" %
		[viewport_size, zoom])
