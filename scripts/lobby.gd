extends Control

const GAME_PORT := 7777
const BROADCAST_PORT := 7778
const MAX_PLAYERS := 8

@onready var ip_input: LineEdit = $CenterContainer/VBoxContainer/IPInput
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var server_list: ItemList = $CenterContainer/VBoxContainer/ServerList
@onready var join_selected_btn: Button = $CenterContainer/VBoxContainer/JoinSelectedButton

const BROADCAST_MSG := "BUBBLEBROS_SERVER"

var _scan_socket := PacketPeerUDP.new()
var _scanning := false
var _found_servers: Array[String] = []

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	join_selected_btn.disabled = true

func _process(_delta: float) -> void:
	if not _scanning:
		return
	while _scan_socket.get_available_packet_count() > 0:
		var packet := _scan_socket.get_packet()
		var ip := _scan_socket.get_packet_ip()
		if packet.get_string_from_utf8() == BROADCAST_MSG and ip not in _found_servers:
			_found_servers.append(ip)
			server_list.add_item("Server @ %s" % ip)

func _on_host_pressed() -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(GAME_PORT, MAX_PLAYERS)
	if err != OK:
		status_label.text = "Failed to host: %s" % error_string(err)
		return
	multiplayer.multiplayer_peer = peer
	# Broadcasting is started by world.gd so it outlives this scene
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_join_pressed() -> void:
	var ip := ip_input.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"
	_connect_to(ip)

func _on_search_pressed() -> void:
	_stop_scanning()
	_found_servers.clear()
	server_list.clear()
	join_selected_btn.disabled = true
	var err := _scan_socket.bind(BROADCAST_PORT, "0.0.0.0")
	if err != OK:
		status_label.text = "Could not open scan port: %s" % error_string(err)
		return
	_scanning = true
	status_label.text = "Scanning all network interfaces..."

func _on_server_list_item_selected(_index: int) -> void:
	join_selected_btn.disabled = false

func _on_join_selected_pressed() -> void:
	var selected := server_list.get_selected_items()
	if selected.is_empty():
		return
	_connect_to(_found_servers[selected[0]])

func _connect_to(ip: String) -> void:
	_stop_scanning()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, GAME_PORT)
	if err != OK:
		status_label.text = "Failed to connect: %s" % error_string(err)
		return
	multiplayer.multiplayer_peer = peer
	status_label.text = "Connecting to %s:%d..." % [ip, GAME_PORT]

func _on_connected_to_server() -> void:
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_connection_failed() -> void:
	status_label.text = "Connection failed."
	multiplayer.multiplayer_peer = null

func _stop_scanning() -> void:
	_scanning = false
	_scan_socket.close()
