extends Node
## LobbyService
##
## Handles creating and joining lobbies, as well as maintaining player data
## Utilizes multiplayer "handlers" so that we can have separate logic for
## steam networking versus local networking.
##
## - UI elements should call the create_lobby and join_lobby functions on this class
## and then subscribe to signals for the rest of the lobby related actions.
##
## - Anything that needs access to player data can reference LobbyService.players which
## will be synced. They can listen to players_changed signal for changes.

# SIGNALS
signal joining_lobby  ## local peer started joining the lobby
signal joined_lobby  ## local peer joined the lobby
signal creating_lobby  ## local peer started creating lobby
signal created_lobby  ## lobby created successfully
signal lobby_error(error_text: String)  ## emitted with `error_text` on any lobby-related error
signal players_changed(players: Dictionary[int, PlayerData])  ## the players dict chagned
signal left_lobby  ## local peer left the lobby

# CCONSTANTS
const MAX_PLAYERS: int = 8  ## max players for the lobby

## raw data representation of players (to be synchronized with multiplayersynchronizer)
@export var _players_raw: Dictionary[int, Dictionary]

## Dictionary of all players in the lobby. In the form of PlayerData objeccts.
var players: Dictionary[int, PlayerData]

## The multiplayer handler for the lobby. Defined as GenericLobbyHandler but will be
## initialized as a SteamLobbyHandler or LocalLobbyHandler.
var _handler: GenericLobbyHandler

## local player's player data dictionary
@onready var my_player_data: PlayerData = PlayerData.new()

# pull in the multiplayer synchronizer from the scene
@onready var _synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

# connect to other services
@onready var _steam: SteamService = SteamService


func _ready() -> void:
	# set a placeholder username
	my_player_data.username = "player_" + str(randi_range(1000, 9000))
	# Initialize the lobby handler. If we're using steam set it to SteamLobbyHandler
	_handler = SteamLobbyHandler.new() if OS.has_feature("steam") else LocalLobbyHandler.new()
	# Add it to the tree so signals work
	add_child(_handler)

	# connect handler signals. For most just pass then to LobbyService signals
	_handler.creating_lobby.connect(creating_lobby.emit)
	_handler.joining_lobby.connect(joining_lobby.emit)
	_handler.joined_lobby.connect(joined_lobby.emit)
	_handler.created_lobby.connect(_on_handler_created_lobby)
	_handler.failed_to_create_or_join.connect(lobby_error.emit)

	# connect other signals
	Steam.steam_server_disconnected.connect(_on_steam_server_disconnected)
	multiplayer.peer_disconnected.connect(_on_multiplayer_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_multiplayer_server_disconnected)
	multiplayer.peer_connected.connect(_on_multiplayer_peer_connected)
	_synchronizer.delta_synchronized.connect(_on_synchronizer_delta_synchronized)
	_steam.initialized.connect(_on_steam_initialized)
	_steam.got_steam_username.connect(_on_steam_got_steam_username)


#region Signal functions


# Will be called by the steam service when initialized.
func _on_steam_initialized() -> void:
	# if using steam, set the steam id and username of my player data
	my_player_data.steam_id = SteamService.steam_id
	my_player_data.username = SteamService.steam_username


# called whenever there is a sync event from the multiplayer synchronizer on this service. This
# will be called on the clients but not the server.
func _on_synchronizer_delta_synchronized() -> void:
	# new player data will come in as a raw dictonary. So update the local PlayerData objects for
	# each player by iterating over the raw dictonary and updating the players var
	for player_id: int in _players_raw:
		var raw_player: Dictionary = _players_raw.get(player_id)
		var player_object: PlayerData = PlayerData.deserialize(raw_player)
		players.set(player_id, player_object)
	# if a player_id is missing from the list, remove them from players as well.
	for player_id: int in players:
		if player_id not in _players_raw.keys():
			players.erase(player_id)
	# emit the signal to the rest of the game knows players changed.
	players_changed.emit(players)


# called via multiplayer.peer_disconnected signal when another player disconnects
func _on_multiplayer_peer_disconnected(peer_id: int) -> void:
	# all we do here is remove them from `players` and `players_raw`
	_players_raw.erase(peer_id)
	players.erase(peer_id)
	players_changed.emit(players)


# called via multiplayer.server_disconnected signal when the server disconnects
func _on_multiplayer_server_disconnected() -> void:
	_reset()
	left_lobby.emit()


# called via SteamService.server_disconnected signal if we disconnected from steam for some reason
func _on_steam_server_disconnected() -> void:
	_reset()
	left_lobby.emit()
	lobby_error.emit("There was an error joining the steam lobby!")


# called via multiplayer.peer_connected signal when a new peer connects.
func _on_multiplayer_peer_connected(peer_id: int) -> void:
	# NOTE: we are treating this function as the primary lobby_joined event, as we're checking if
	# the peer that connected is peer_id of 1, thus we connected to the server. I've found that this is
	# the most reliable way to capture a lobby_joined event with the timing of everything.
	if peer_id == 1:
		# if we connected to server, register the player then, emit the joined_lobby signal
		_register_player.rpc_id(1, my_player_data.serialize())
		joined_lobby.emit()


# called via the handler.created_lobby signal. here we just want to register the player in the lobby
func _on_handler_created_lobby() -> void:
	_register_player.rpc_id(1, my_player_data.serialize())
	created_lobby.emit()


# called via SteamService.got_steam_username signal. This can happen at radom times. The usernames
# we recieve when the player joins may not be the actual username they have set currently. If we
# recieve a new username, just upddate players dictionary immediately.
func _on_steam_got_steam_username(steam_id: int, steam_username: String) -> void:
	for player_id: int in _players_raw:
		if _players_raw[player_id]["steam_id"] == steam_id:
			_players_raw[player_id]["username"] = steam_username
			players[player_id].username = steam_username


#endregion

#region RPC functions

# seems like we need this for now because steam doesn't trigger a
# disconnect event when you leave the lobby.
@rpc("any_peer", "call_remote", "reliable")
func _notify_lobby_leave() -> void:
	var peer_id: int = multiplayer.get_remote_sender_id()
	_players_raw.erase(peer_id)
	players.erase(peer_id)
	players_changed.emit(players)
	if peer_id == 1:
		lobby_error.emit("The host closed the lobby")
		leave_lobby()


# RPC function to register the local player in the players dictionary on the server. We need to do
# this because the server won't have context of the player other than the steam_id and peer_id.
# We'll need this to grab any other game-specific data of the player.
# NOTE: this should probably always be called via `.rpc_id(1)` as only the server should get this.
@rpc("any_peer", "call_local", "reliable")
func _register_player(player_data_raw: Dictionary[String, Variant]) -> void:
	if not multiplayer.is_server():
		return  # make sure we don't do anything if we're not the server
	var remote_sender_id: int = multiplayer.get_remote_sender_id()
	# turn the raw player_data into a PlayerData object
	var new_player: PlayerData = PlayerData.deserialize(player_data_raw)
	new_player.peer_id = remote_sender_id
	# deserialize then re-serialize here so that we can make sure any logic in the PlayerData class can
	# run in case there is custom logic we need in the future.
	_players_raw.set(remote_sender_id, new_player.serialize())
	players.set(remote_sender_id, new_player)
	# emit the signal so the rest of the game knows
	players_changed.emit(players)
	# if we're using steam, just tell steam to fetch any new steam data for the players in the lobby
	if OS.has_feature("steam"):
		_steam.get_lobby_members(_handler.lobby_id)


#endregion


# Pass create and join lobby functions to handler
func create_lobby() -> void:
	print("TEST?")
	_handler.create_lobby()


func join_lobby(lobby_id: int = -1) -> void:
	_handler.join_lobby(lobby_id)


# resets the players data. Should happen when we leave a lobby.
func _reset() -> void:
	players = {}
	_players_raw = {}


# public func to trigger a leave lobby
func leave_lobby() -> void:
	# tell the rest of the peer that we're leaving. (needed for steam lobbies)
	_notify_lobby_leave.rpc()
	# tell the handler we should disconnect
	_handler.close_peer()
	# reset the lobby state
	_reset()
	# emit the left_lobby signal
	left_lobby.emit()
