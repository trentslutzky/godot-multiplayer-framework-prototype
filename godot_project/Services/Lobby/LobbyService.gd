extends Node

const MAX_PLAYERS = 8

var lobby_id: int = -1
var in_lobby: bool = false
var is_host: bool = false
var using_steam: bool = false

@export var players_data_raw: Dictionary[int, Dictionary]
var last_players_data_raw: Dictionary[int, Dictionary]
var players_data: Dictionary[int, PlayerData]

var handler: GenericLobbyHandler

var steam_usernames: Dictionary[int, String]

@onready var _sync := $MultiplayerSynchronizer
@onready var _steam := SteamService

@onready var my_player_data := PlayerData.new()

signal joining_lobby
signal joined_lobby
signal failed_to_join_lobby(error_text: String)
signal creating_lobby
signal created_lobby
signal failed_to_create_lobby(error_text: String)

func _ready() -> void:
	## initialize handler ##
	init_new_lobby_handler(false)
	## connect signals ##
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.server_disconnected.connect(_server_disconnected)
	_sync.synchronized.connect(_synchronized)
	joined_lobby.connect(_lobby_joined)
	created_lobby.connect(_lobby_created)
	_steam.initialized.connect(_steam_initialized)


func _steam_initialized():
	my_player_data.steam_id = SteamService.steam_id


func init_new_lobby_handler(use_steam: bool):
	using_steam = use_steam
	if handler != null:
		handler.queue_free()
	if use_steam:
		my_player_data.username = SteamService.steam_username
		handler = SteamLobbyHandler.new() 
	else:
		my_player_data.username = "player_"+str(randi_range(8000, 9000))
		handler = LocalLobbyHandler.new()
	add_child(handler)


func _synchronized():
	_populate_player_data_objects()


func _populate_player_data_objects():
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
	Steam.leaveLobby(lobby_id)
	handler.peer.close()
	_reset()


@rpc("any_peer", "call_local", "reliable")
func _register_player(player_raw_data: Dictionary[String, Variant]):
	if not multiplayer.is_server(): return
	var remote_sender_id = multiplayer.get_remote_sender_id()
	var new_player_data = PlayerData.deserialize(player_raw_data)
	new_player_data.peer_id = remote_sender_id
	if using_steam:
		handler.get_lobby_members()
	players_data_raw.set(remote_sender_id, new_player_data.serialize())
	players_data.set(remote_sender_id, new_player_data)


func _reset():
	in_lobby = false
	is_host = false
	lobby_id = -1
	players_data = {}
	players_data_raw = {}
	init_new_lobby_handler(using_steam)
