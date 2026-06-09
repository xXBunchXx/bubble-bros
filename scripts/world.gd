extends Node3D

const PLAYER_SCENE := preload("res://scenes/player.tscn")

const SPAWN_POSITIONS := [
	Vector3(0, 1, 0),
	Vector3(3, 1, 0),
	Vector3(-3, 1, 0),
	Vector3(0, 1, 3),
	Vector3(0, 1, -3),
]

func _ready() -> void:
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		# Spawn the host locally — no clients yet so no replication needed
		_add_player(multiplayer.get_unique_id(), _next_spawn_pos())
	else:
		# Tell the server we're in the world and ready to receive spawns
		_request_spawn.rpc_id(1)

# Called on the SERVER by each joining client once their world scene is ready
@rpc("any_peer", "reliable", "call_remote")
func _request_spawn() -> void:
	var new_id := multiplayer.get_remote_sender_id()
	var new_pos := _next_spawn_pos()

	# Send the new client info about every player already in the world
	for child in $Players.get_children():
		_add_player.rpc_id(new_id, int(child.name), child.position)

	# Spawn the new player on the server first
	_add_player(new_id, new_pos)

	# Then tell ALL clients (including the new one) about the new player
	_add_player.rpc(new_id, new_pos)

# Runs on every peer that should create a player node
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
