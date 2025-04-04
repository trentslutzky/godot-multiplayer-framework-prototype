extends Node

# Steam variables
var initializing: bool = true
var is_on_steam_deck: bool = false
var is_online: bool = false
var is_owned: bool = false
var steam_app_id: int = 480
var steam_id: int = 0
var steam_username: String = ""


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


func get_friends_in_lobbies() -> Dictionary:
	var results: Dictionary = {}

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

			if app_id != Steam.getAppID() or lobby is String:
				# Either not in this game, or not in a lobby
				continue

			results[fetched_steam_id] = lobby

	return results
