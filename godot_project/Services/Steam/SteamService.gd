extends Node

var steam_usernames: Dictionary[int, String]
var friends_lobby_ids: Dictionary[int, int]

# Steam variables
var initializing: bool = true
var is_on_steam_deck: bool = false
var is_online: bool = false
var is_owned: bool = false
var steam_app_id: int = 480
var steam_id: int = -1
var steam_username: String = ""

signal initialized
signal friends_lobby_list_updated

@onready var _lobby := LobbyService

func _init() -> void:
	# Set your game's Steam app ID here
	OS.set_environment("SteamAppId", str(steam_app_id))
	OS.set_environment("SteamGameId", str(steam_app_id))


func _ready() -> void:
	_initialize_steam()


func _process(_delta: float) -> void:
	Steam.run_callbacks()


func _initialize_steam() -> void:
	var initialize_response: Dictionary = Steam.steamInitEx()

	initializing = false

	if initialize_response["status"] > 0:
		push_error("Failed to initialize Steam. Shutting down. %s" % initialize_response)

	# Gather additional data
	is_on_steam_deck = Steam.isSteamRunningOnSteamDeck()
	is_online = Steam.loggedOn()
	is_owned = Steam.isSubscribed()
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()

	# Check if account owns the game
	if !is_owned:
		push_error("User does not own this game!")
	
	initialized.emit()
	get_friends_in_lobbies()


func get_friends_in_lobbies() -> void:
	var results: Dictionary[int, int] = {}

	for i in range(0, Steam.getFriendCount()):
		var fetched_steam_id: int = Steam.getFriendByIndex(i, Steam.FRIEND_FLAG_IMMEDIATE)
		var game_info: Dictionary = Steam.getFriendGamePlayed(fetched_steam_id)

		if game_info.is_empty():
			# This friend is not playing a game
			continue
		else:
			# They are playing a game, check if it's the same game as ours
			var app_id: int = game_info["id"]
			var lobby = game_info["lobby"]

			if app_id != Steam.getAppID() or lobby is String or lobby == 0:
				# Either not in this game, or not in a lobby
				continue

			results[fetched_steam_id] = lobby
			
			var member_steam_name: String = Steam.getFriendPersonaName(fetched_steam_id)
			steam_usernames.set(fetched_steam_id, member_steam_name)

	friends_lobby_ids = results
	friends_lobby_list_updated.emit()

# grabs steam information for players in the steam lobby
func get_lobby_members() -> void:
	steam_usernames.clear()
	var num_members: int = Steam.getNumLobbyMembers(_lobby.lobby_id)
	# Get the data of these players from Steam
	for this_member in range(0, num_members):
		# Get the member's Steam ID
		var member_steam_id: int = Steam.getLobbyMemberByIndex(_lobby.lobby_id, this_member)
		# Get the member's Steam name
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		# Kick off a request for the member's Steam avatar
		Steam.getMediumFriendAvatar(member_steam_id)
		# Add them to the list
		steam_usernames.set(member_steam_id, member_steam_name)
		
		for player_peer_id in _lobby.players_data:
			if _lobby.players_data[player_peer_id]["steam_id"] == member_steam_id:
				_lobby.players_data[player_peer_id]["steam_id"] = member_steam_name
		for player_peer_id in _lobby.players_data_raw:
			if _lobby.players_data_raw[player_peer_id]["steam_id"] == member_steam_id:
				_lobby.players_data_raw[player_peer_id]["steam_id"] = member_steam_name
		
