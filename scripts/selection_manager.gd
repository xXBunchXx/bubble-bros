extends Node

var selected_units: Array = []

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			_handle_select(event.position)
		MOUSE_BUTTON_RIGHT:
			_handle_command(event.position)

func _handle_select(screen_pos: Vector2) -> void:
	_deselect_all()
	var unit = _unit_at(_to_world(screen_pos))
	if unit and unit.is_multiplayer_authority():
		unit.set_selected(true)
		selected_units.append(unit)

func _handle_command(screen_pos: Vector2) -> void:
	if selected_units.is_empty():
		return
	var world_pos := _to_world(screen_pos)
	var target_unit = _unit_at(world_pos)

	# If right-clicked an enemy, converge on their position
	var target: Vector2 = (target_unit as Node2D).global_position if (target_unit and not target_unit.is_multiplayer_authority()) else world_pos

	var count := selected_units.size()
	for i in count:
		var offset := Vector2.ZERO
		if count > 1:
			var angle := i * TAU / count
			offset = Vector2(cos(angle), sin(angle)) * 30.0
		selected_units[i].move_to(target + offset)

func _deselect_all() -> void:
	for unit in selected_units:
		if is_instance_valid(unit):
			unit.set_selected(false)
	selected_units.clear()

func _unit_at(world_pos: Vector2) -> Node:
	var space := get_tree().get_root().get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	for result in space.intersect_point(query, 8):
		var node = result.collider
		if node.is_in_group("units"):
			return node
	return null

func _to_world(screen_pos: Vector2) -> Vector2:
	return get_viewport().canvas_transform.affine_inverse() * screen_pos
