extends Node

const MAX_PLAYERS: int = 8

var lobby_id: int = -1
var in_lobby: bool = false
var is_host: bool = false
@onready var using_steam: bool = OS.has_feature("steam")

@export var players_data_raw: Dictionary[int, Dictionary]
var players_data: Dictionary[int, PlayerData]

var handler: GenericLobbyHandler

@onready var _sync: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var _steam: SteamService = SteamService
@onready var _game_sequence: GameSequence = GameSequence

@onready var my_player_data: PlayerData = PlayerData.new()

signal joining_lobby
signal joined_lobby
signal creating_lobby
signal created_lobby
signal lobby_error(error_text: String)
signal players_updated(players_data:  Dictionary[int, PlayerData])
signal left_lobby

func _ready() -> void:
	## connect signals ##
	Steam.steam_server_disconnected.connect(_on_steam_server_disconnected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected)
	_sync.delta_synchronized.connect(_populate_player_data_objects)
	_steam.initialized.connect(_on_steam_initialized)
	_steam.got_steam_username.connect(_on_steam_got_steam_username)
	my_player_data.username = "player_"+str(randi_range(1000, 9000))
	_game_sequence.game_starting.connect(_on_game_sequence_game_starting)
	
	## initialize handler ##
	handler = SteamLobbyHandler.new() if using_steam else LocalLobbyHandler.new()
	add_child(handler)
	
	## new handler means we need to connect the signals ##
	handler.creating_lobby.connect(_on_creating_lobby)
	handler.created_lobby.connect(_on_lobby_created)
	handler.failed_to_create_or_join.connect(_lobby_error)
	handler.joining_lobby.connect(_on_joining_lobby)
	handler.joined_lobby.connect(_on_lobby_joined)


func _on_steam_initialized() -> void:
	if using_steam:
		my_player_data.steam_id = SteamService.steam_id
		my_player_data.username = SteamService.steam_username


func _populate_player_data_objects() -> void:
	for player_id: int in players_data_raw:
		var raw_player_data: Dictionary = players_data_raw.get(player_id)
		var player_data_object: PlayerData = PlayerData.deserialize(raw_player_data)
		players_data.set(player_id, player_data_object)
	for player_id: int in players_data:
		if player_id not in players_data_raw.keys():
			players_data.erase(player_id)
	players_updated.emit(players_data)


func _on_peer_disconnected(peer_id: int) -> void:
	if not is_multiplayer_authority(): return
	players_data_raw.erase(peer_id)
	players_data.erase(peer_id)
	players_updated.emit(players_data)


func _on_server_disconnected() -> void:
	_reset()
	left_lobby.emit()


func _on_steam_server_disconnected() -> void:
	_reset()
	left_lobby.emit()
	lobby_error.emit("There was an error joining the steam lobby!")


func _on_peer_connected(peer_id: int) -> void:
	if peer_id == 1:
		_register_self()
		joined_lobby.emit()


func _on_creating_lobby() -> void:
	creating_lobby.emit()


func _on_lobby_created() -> void:
	is_host = true
	in_lobby = true
	_register_self()
	created_lobby.emit()


func _on_joining_lobby() -> void:
	joining_lobby.emit()


func _on_lobby_joined() -> void:
	is_host = false
	in_lobby = true
	joined_lobby.emit()


func _register_self() -> void:
	_register_player.rpc_id(1, my_player_data.serialize())


func leave_lobby() -> void:
	_im_leaving_the_lobby.rpc()
	Steam.leaveLobby(lobby_id)
	handler.close_peer()
	_reset()
	left_lobby.emit()

# seems like we need this for now because steam doesn't trigger a 
# disconnect when you leave the lobby
@rpc("any_peer", "call_remote", "reliable")
func _im_leaving_the_lobby() -> void:
	var peer_id: int = multiplayer.get_remote_sender_id()
	players_data_raw.erase(peer_id)
	players_data.erase(peer_id)
	players_updated.emit(players_data)
	if peer_id == 1:
		lobby_error.emit("The host closed the lobby")
		leave_lobby()


func _lobby_error(error_text: String) -> void:
	lobby_error.emit(error_text)


@rpc("any_peer", "call_local", "reliable")
func _register_player(player_raw_data: Dictionary[String, Variant]) -> void:
	var remote_sender_id: int = multiplayer.get_remote_sender_id()
	var new_player_data: PlayerData = PlayerData.deserialize(player_raw_data)
	new_player_data.peer_id = remote_sender_id
	players_data_raw.set(remote_sender_id, new_player_data.serialize())
	players_data.set(remote_sender_id, new_player_data)
	players_updated.emit(players_data)
	if using_steam:
		_steam.get_lobby_members(lobby_id)


func _on_steam_got_steam_username(steam_id: int, steam_username: String) -> void:
	if not is_host: return
	for player_id: int in players_data_raw:
		if players_data_raw[player_id]["steam_id"] == steam_id:
			players_data_raw[player_id]["username"] = steam_username
			players_data[player_id].username = steam_username


func _reset() -> void:
	in_lobby = false
	is_host = false
	lobby_id = -1
	players_data = {}
	players_data_raw = {}


func _on_game_sequence_game_starting() -> void:
	if not is_host: return
	if not using_steam: return
	Steam.setLobbyJoinable(lobby_id, false)
