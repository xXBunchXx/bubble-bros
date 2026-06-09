extends Node2D

const UNIT_SCENE := preload("res://scenes/unit.tscn")
const BROADCAST_PORT := 7778
const BROADCAST_INTERVAL := 1.0
const BROADCAST_MSG := "BUBBLEBROS_SERVER"

## Pawn each player starts with (id = filename in res://data/pawns/)
const STARTING_PAWN := "ninja"

const SPAWN_POSITIONS: Array[Vector2] = [
	Vector2(0, 0),
	Vector2(120, 0),
	Vector2(-120, 0),
	Vector2(0, 120),
	Vector2(0, -120),
]

var _broadcast_sockets: Array[PacketPeerUDP] = []
var _broadcast_timer := 0.0
var _next_unit_num := 1

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		spawn_unit(STARTING_PAWN, 1, _next_spawn_pos())
		_open_broadcast_sockets()
	else:
		_request_spawn.rpc_id(1)

func _process(delta: float) -> void:
	if _broadcast_sockets.is_empty():
		return
	_broadcast_timer += delta
	if _broadcast_timer >= BROADCAST_INTERVAL:
		_broadcast_timer = 0.0
		_send_broadcasts()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_close_broadcast_sockets()

# ── Spawning ────────────────────────────────────────────────────────────────
# SERVER-ONLY entry point. Spawns any pawn type for any owner and
# replicates it to all clients. This is the one function future game
# systems (buildings, abilities, game modes) call to create units.
func spawn_unit(pawn_id: String, p_owner_id: int, pos: Vector2) -> void:
	assert(multiplayer.is_server())
	var unit_name := "u%d" % _next_unit_num
	_next_unit_num += 1
	_add_unit(unit_name, pawn_id, p_owner_id, pos)
	_add_unit.rpc(unit_name, pawn_id, p_owner_id, pos)

# Called on the SERVER by each joining client once their world is loaded
@rpc("any_peer", "reliable", "call_remote")
func _request_spawn() -> void:
	var new_id := multiplayer.get_remote_sender_id()
	# First, replicate every existing unit to the new client
	for child in $Units.get_children():
		_add_unit.rpc_id(new_id, child.name, child.pawn_id, child.owner_id, child.position)
	# Then spawn their starting unit everywhere
	spawn_unit(STARTING_PAWN, new_id, _next_spawn_pos())

@rpc("authority", "reliable", "call_remote")
func _add_unit(unit_name: String, pawn_id: String, p_owner_id: int, pos: Vector2) -> void:
	if $Units.get_node_or_null(unit_name):
		return
	var unit := UNIT_SCENE.instantiate()
	unit.name = unit_name
	unit.setup(pawn_id, p_owner_id)
	unit.position = pos
	$Units.add_child(unit)

@rpc("authority", "reliable", "call_remote")
func _remove_units_of(peer_id: int) -> void:
	for child in $Units.get_children():
		if child.owner_id == peer_id:
			child.queue_free()

func _on_peer_disconnected(peer_id: int) -> void:
	_remove_units_of(peer_id)
	_remove_units_of.rpc(peer_id)

func _next_spawn_pos() -> Vector2:
	return SPAWN_POSITIONS[$Units.get_child_count() % SPAWN_POSITIONS.size()]

# ── LAN broadcast ───────────────────────────────────────────────────────────

func _open_broadcast_sockets() -> void:
	_close_broadcast_sockets()
	var seen: Array[String] = []
	for iface in IP.get_local_interfaces():
		for addr: String in iface.get("addresses", []):
			if ":" in addr or addr.begins_with("127."):
				continue
			var parts := addr.split(".")
			if parts.size() != 4:
				continue
			var subnet_bcast := "%s.%s.%s.255" % [parts[0], parts[1], parts[2]]
			if subnet_bcast in seen:
				continue
			seen.append(subnet_bcast)
			var sock := PacketPeerUDP.new()
			sock.bind(0, addr)
			sock.set_broadcast_enabled(true)
			sock.set_dest_address(subnet_bcast, BROADCAST_PORT)
			_broadcast_sockets.append(sock)
	var loopback := PacketPeerUDP.new()
	loopback.set_dest_address("127.0.0.1", BROADCAST_PORT)
	_broadcast_sockets.append(loopback)

func _send_broadcasts() -> void:
	var data := BROADCAST_MSG.to_utf8_buffer()
	for sock in _broadcast_sockets:
		sock.put_packet(data)

func _close_broadcast_sockets() -> void:
	for sock in _broadcast_sockets:
		sock.close()
	_broadcast_sockets.clear()
