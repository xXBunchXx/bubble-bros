extends Node3D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const BROADCAST_PORT := 7778
const BROADCAST_INTERVAL := 1.0
const BROADCAST_MSG := "BUBBLEBROS_SERVER"

const SPAWN_POSITIONS := [
	Vector3(0, 1, 0),
	Vector3(3, 1, 0),
	Vector3(-3, 1, 0),
	Vector3(0, 1, 3),
	Vector3(0, 1, -3),
]

var _broadcast_sockets: Array[PacketPeerUDP] = []
var _broadcast_timer := 0.0

func _ready() -> void:
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		_add_player(multiplayer.get_unique_id(), _next_spawn_pos())
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

# ── Multiplayer spawning ────────────────────────────────────────────────────

@rpc("any_peer", "reliable", "call_remote")
func _request_spawn() -> void:
	var new_id := multiplayer.get_remote_sender_id()
	var new_pos := _next_spawn_pos()
	for child in $Players.get_children():
		_add_player.rpc_id(new_id, int(child.name), child.position)
	_add_player(new_id, new_pos)
	_add_player.rpc(new_id, new_pos)

@rpc("authority", "reliable", "call_local")
func _add_player(peer_id: int, pos: Vector3) -> void:
	if $Players.get_node_or_null(str(peer_id)):
		return
	var player := PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	player.position = pos
	$Players.add_child(player)

@rpc("authority", "reliable", "call_local")
func _remove_player(peer_id: int) -> void:
	var player := $Players.get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func _on_peer_disconnected(peer_id: int) -> void:
	_remove_player(peer_id)
	_remove_player.rpc(peer_id)

func _next_spawn_pos() -> Vector3:
	return SPAWN_POSITIONS[$Players.get_child_count() % SPAWN_POSITIONS.size()]

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
			# Bind to this interface's IP so the OS sends through the right NIC
			sock.bind(0, addr)
			sock.set_broadcast_enabled(true)
			sock.set_dest_address(subnet_bcast, BROADCAST_PORT)
			_broadcast_sockets.append(sock)

	# Unicast to loopback so a second instance on the same machine can find us
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
