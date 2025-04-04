extends Node

var lobby_id: int = -1
var in_lobby: bool = false
var is_host: bool = false

@export var players_data_raw: Dictionary[int, Dictionary]
var last_players_data_raw: Dictionary[int, Dictionary]
var players_data: Dictionary[int, PlayerData]

@onready var _sync := $MultiplayerSynchronizer
@onready var _net := NetworkingService

@onready var my_player_data := PlayerData.new()

func _ready() -> void:
	## connect to multiplayer signals ##
	_net.signal_lobby_created.connect(_lobby_created)
	_net.signal_lobby_joined.connect(_lobby_joined)
	_net.signal_peer_set.connect(_peer_changed)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.server_disconnected.connect(_server_disconnected)
	_sync.synchronized.connect(_synchronized)
	my_player_data.username = "player_"+str(randi_range(8000, 9000))


func _synchronized():
	populate_player_data_objects()


func populate_player_data_objects():
	if players_data_raw == last_players_data_raw:
		return
	last_players_data_raw = players_data_raw
	for player_id in players_data_raw:
		var raw_player_data = players_data_raw.get(player_id)
		var player_data_object: PlayerData = PlayerData.deserialize(raw_player_data)
		players_data.set(player_id, player_data_object)
	for player_id in players_data:
		if player_id not in players_data_raw.keys():
			players_data.erase(player_id)


func _peer_disconnected(peer_id: int):
	if not is_multiplayer_authority(): return
	players_data_raw.erase(peer_id)
	players_data.erase(peer_id)


func _peer_changed():
	my_player_data.username = "player_"+str(randi_range(8000, 9000)) if _net.handler is LocalNetworkingHandler else SteamService.steam_username


func _server_disconnected():
	_reset()


func _lobby_created():
	is_host = true
	in_lobby = true
	_register_self()


func _lobby_joined():
	is_host = false
	in_lobby = true
	_register_self()


func _register_self():
	_register_player.rpc_id(1, my_player_data.serialize())


func leave_lobby() -> void:
	if _net.handler is SteamNetworkingHandler:
		Steam.leaveLobby(lobby_id)
	_net.handler.peer.close()
	_net.handler.reset()
	_reset()


@rpc("any_peer", "call_local", "reliable")
func _register_player(player_raw_data: Dictionary[String, Variant]):
	if not multiplayer.is_server(): return
	var remote_sender_id = multiplayer.get_remote_sender_id()
	var new_player_data = PlayerData.deserialize(player_raw_data)
	players_data_raw.set(remote_sender_id, new_player_data.serialize())
	players_data.set(remote_sender_id, new_player_data)


func _reset():
	in_lobby = false
	is_host = false
	lobby_id = -1
	players_data = {}
	players_data_raw = {}
	_net.handler.reset()
