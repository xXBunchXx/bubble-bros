extends CharacterBody2D

const STOP_DISTANCE := 8.0

@onready var body: Polygon2D = $Body
@onready var collision: CollisionShape2D = $CollisionShape2D

var pawn_id := ""
var owner_id := 1
var health := 100.0

var _data: PawnData
var _target_position: Vector2
var _moving := false
var _base_color: Color

## Called by world.gd right after instancing, before add_child.
func setup(p_pawn_id: String, p_owner_id: int) -> void:
	pawn_id = p_pawn_id
	owner_id = p_owner_id

func _ready() -> void:
	set_multiplayer_authority(owner_id)
	add_to_group("units")

	_data = PawnRegistry.get_pawn(pawn_id)
	if _data == null:
		_data = PawnData.new()  # safe fallback so the game keeps running

	health = _data.max_health
	# Duplicate the shape — otherwise resizing it would resize every unit
	collision.shape = collision.shape.duplicate()
	collision.shape.radius = _data.radius
	# Scale the arrow polygon to match the pawn's size (authored at radius 18)
	body.scale = Vector2.ONE * (_data.radius / 18.0)

	# Per-player hue, multiplied by the pawn type's tint
	_base_color = Color.from_hsv(fmod(owner_id * 0.37, 1.0), 0.7, 0.85) * _data.color
	body.color = _base_color

func set_selected(value: bool) -> void:
	body.color = Color.YELLOW if value else _base_color

func move_to(target: Vector2) -> void:
	_target_position = target
	_moving = true

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if _moving:
		var diff := _target_position - global_position
		if diff.length() < STOP_DISTANCE:
			_moving = false
			velocity = Vector2.ZERO
		else:
			velocity = diff.normalized() * _data.speed
			rotation = diff.angle()
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	if multiplayer.get_peers().size() > 0:
		_sync_transform.rpc(global_position, rotation)

@rpc("any_peer", "unreliable_ordered", "call_remote")
func _sync_transform(pos: Vector2, rot: float) -> void:
	global_position = pos
	rotation = rot
