extends Node

const MAX_PLAYERS = 8

var lobby_id: int = -1
var in_lobby: bool = false
var is_host: bool = false
@onready var using_steam: bool = OS.has_feature("steam")

@export var players_data_raw: Dictionary[int, Dictionary]
var players_data: Dictionary[int, PlayerData]

var handler: GenericLobbyHandler

@onready var _sync := $MultiplayerSynchronizer
@onready var _steam := SteamService

@onready var my_player_data := PlayerData.new()

signal joining_lobby
signal joined_lobby
signal failed_to_join_lobby(error_text: String)
signal creating_lobby
signal created_lobby
signal failed_to_create_lobby(error_text: String)

signal connected_to_lobby

func _ready() -> void:
	## connect signals ##
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.server_disconnected.connect(_server_disconnected)
	multiplayer.peer_connected.connect(_peer_connected)
	_sync.delta_synchronized.connect(_populate_player_data_objects)
	joined_lobby.connect(_lobby_joined)
	created_lobby.connect(_lobby_created)
	_steam.initialized.connect(_steam_initialized)
	
	my_player_data.username = "player_"+str(randi_range(8000, 9000))


func _steam_initialized():
	my_player_data.steam_id = SteamService.steam_id
	## initialize handler ##
	handler = SteamLobbyHandler.new() if OS.has_feature("steam") else LocalLobbyHandler.new()
	add_child(handler)


func _populate_player_data_objects():
	print("_populate_player_data_objects")
	for player_id in players_data_raw:
		var raw_player_data = players_data_raw.get(player_id)
		var player_data_object: PlayerData = PlayerData.deserialize(raw_player_data)
		players_data.set(player_id, player_data_object)
	for player_id in players_data:
		if player_id not in players_data_raw.keys():
			players_data.erase(player_id)


func _peer_disconnected(peer_id: int):
	prints("_peer_disconnected:", peer_id)
	if not is_multiplayer_authority(): return
	players_data_raw.erase(peer_id)
	players_data.erase(peer_id)


func _server_disconnected():
	_reset()


func _peer_connected(peer_id: int):
	prints("_peer_connected:", peer_id)
	if peer_id == 1:
		_register_self()
		connected_to_lobby.emit()


func _lobby_created():
	prints("_lobby_created", multiplayer.get_unique_id())
	is_host = true
	in_lobby = true
	_register_self()


func _lobby_joined():
	prints("_lobby_joined", multiplayer.get_unique_id())
	is_host = false
	in_lobby = true


func _register_self():
	_register_player.rpc_id(1, my_player_data.serialize())


func leave_lobby() -> void:
	Steam.leaveLobby(lobby_id)
	handler.peer.close()
	_reset()


@rpc("any_peer", "call_local", "reliable")
func _register_player(player_raw_data: Dictionary[String, Variant]):
	var remote_sender_id = multiplayer.get_remote_sender_id()
	var new_player_data = PlayerData.deserialize(player_raw_data)
	new_player_data.peer_id = remote_sender_id
	players_data_raw.set(remote_sender_id, new_player_data.serialize())
	players_data.set(remote_sender_id, new_player_data)
	if using_steam:
		_steam.get_lobby_members()


func _reset():
	in_lobby = false
	is_host = false
	lobby_id = -1
	players_data = {}
	players_data_raw = {}
