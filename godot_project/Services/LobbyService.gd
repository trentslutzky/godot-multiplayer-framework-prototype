extends Node

var lobby_id: int = -1
var in_lobby: bool = false
var is_host: bool = false

@export var players: Dictionary = {}

@onready var _sync := $MultiplayerSynchronizer
@onready var _net := NetworkingService

# just for testing
@onready var my_username := "player_"+str(randi_range(8000, 9000))

func _ready() -> void:
	## connect to multiplayer signals ##
	_net.signal_lobby_created.connect(_lobby_created)
	_net.signal_lobby_joined.connect(_lobby_joined)
	_net.signal_peer_set.connect(_peer_changed)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.server_disconnected.connect(_reset)


func _peer_disconnected(peer_id: int):
	if not is_multiplayer_authority():
		return
	players.erase(peer_id)


func _peer_changed():
	my_username = "player_"+str(randi_range(8000, 9000)) if _net.handler is LocalNetworkingHandler else SteamService.steam_username


func _server_disconnected():
	_reset()


func _lobby_created():
	is_host = true
	in_lobby = true
	_register_player.rpc_id(1, my_username)


func _lobby_joined():
	is_host = false
	in_lobby = true
	_register_player.rpc_id(1, my_username)


func leave_lobby() -> void:
	if _net.handler is SteamNetworkingHandler:
		Steam.leaveLobby(lobby_id)


@rpc("any_peer", "call_local", "reliable")
func _register_player(username: String):
	if not is_multiplayer_authority():
		return
	players.set(multiplayer.get_remote_sender_id(), { "username": username })


func _reset():
	in_lobby = false
	is_host = false
	lobby_id = -1
	players = {}
