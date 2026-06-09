extends CharacterBody3D

const SPEED := 5.0
const JUMP_VELOCITY := 5.0
const MOUSE_SENSITIVITY := 0.002

@onready var camera: Camera3D = $Camera3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var _yaw := 0.0

func _ready() -> void:
	# Node name is the peer id — use it to assign authority
	set_multiplayer_authority(int(name))

	if is_multiplayer_authority():
		camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		# Tint local player green so you can tell yourself apart
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color.GREEN
		mesh_instance.material_override = mat
	else:
		camera.current = false

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event is InputEventMouseMotion:
		_yaw -= event.relative.x * MOUSE_SENSITIVITY
		rotation.y = _yaw
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
