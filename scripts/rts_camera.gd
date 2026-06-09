extends Camera2D

const PAN_SPEED := 400.0
const ZOOM_FACTOR := 0.1
const MIN_ZOOM := 0.3
const MAX_ZOOM := 3.0

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_set_zoom(zoom.x + ZOOM_FACTOR)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_set_zoom(zoom.x - ZOOM_FACTOR)

func _process(delta: float) -> void:
	var pan := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_forward", "move_back")
	)
	if pan != Vector2.ZERO:
		# Pan speed scales inversely with zoom so it feels consistent
		position += pan.normalized() * PAN_SPEED * delta / zoom.x

func _set_zoom(value: float) -> void:
	var z := clampf(value, MIN_ZOOM, MAX_ZOOM)
	zoom = Vector2(z, z)
