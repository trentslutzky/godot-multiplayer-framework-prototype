extends Node

## App ID of this game. Using 480 as the placeholder ID in testing.
const STEAM_APP_ID: int = 480

## A cache of steam_id: steam_username for all users we've fetched. We maintain a cache here so
## that we always have a steam username anywhere we'd get back just a steam id.
var steam_usernames: Dictionary[int, String]

## A cache of steam avatars similar to steam_usernames. Save them in a variable to
## avoid requesting a new avatar from steam whenever we need it.
var steam_avatars: Dictionary[int, ImageTexture]

var initializing: bool = true ## Is steam currently initializing
var is_on_steam_deck: bool = false ## Is the user on steam deck
var is_online: bool = false ## Is the user online
var is_owned: bool = false ## Does the user own this game
var steam_id: int = -1 ## The user's steam ID
var steam_username: String = "" ## The user's steam username

# SIGNALS
signal initialized ## Called on successful initialization of steam
signal friends_lobby_list_updated(lobby_ids: Dictionary[int, int]) ## Recieved new data on friends' lobbies
signal got_steam_username(steam_id: int, steam_username: String) ## Recieved a new steam username for a steam user
signal avatar_loaded(avatar_id: int, avatar_texture: ImageTexture) ## When we load a steam avatar


func _init() -> void:
	if not OS.has_environment("steam"): return
	# Set the game's Steam app ID. Using 
	OS.set_environment("SteamAppId", str(STEAM_APP_ID))
	OS.set_environment("SteamGameId", str(STEAM_APP_ID))


func _ready() -> void:
	if not OS.has_environment("steam"): return
	_initialize_steam()
	Steam.avatar_loaded.connect(_on_steam_avatar_loaded)


# Connects to steam, ensures the user is logged in, sets some user details.
# Must run when the game starts
func _initialize_steam() -> void:
	print("INIT STEAM")
	var initialize_response: Dictionary = Steam.steamInit() # initialize steam

	if initialize_response["status"] > 1: # anything > 1 is an error state.
		push_error("Failed to initialize Steam. Shutting down. %s" % initialize_response)

	# Populate my steam variables
	is_on_steam_deck = Steam.isSteamRunningOnSteamDeck()
	is_online = Steam.loggedOn()
	is_owned = Steam.isSubscribed()
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()
	
	# Go ahead and fetch this user's steam avatar
	Steam.getPlayerAvatar(3, steam_id)

	# Check if this user owns the game
	if !is_owned:
		push_error("User does not own this game!")
	
	# finish and emit signal
	initializing = false
	initialized.emit()


func _process(_delta: float) -> void:
	if not initialized: return
	Steam.run_callbacks() # required to maintain a connection to the steam API

## Triggers a request for friends' steam lobbies. On success, will emit signal friends_lobby_list_updated
func get_friends_in_lobbies() -> void:
	var results: Dictionary[int, int] = {}

	for i: int in range(0, Steam.getFriendCount()):
		var fetched_steam_id: int = Steam.getFriendByIndex(i, Steam.FRIEND_FLAG_IMMEDIATE)
		var game_info: Dictionary = Steam.getFriendGamePlayed(fetched_steam_id)

		if game_info.is_empty():
			# This friend is not playing a game
			continue
		else:
			# They are playing a game, check if it's the same game as ours
			var app_id: int = game_info["id"]
			var lobby: Variant = game_info["lobby"]

			if app_id != Steam.getAppID() or lobby is String or lobby == 0:
				# Either not in this game, or not in a lobby
				continue

			results[fetched_steam_id] = lobby

			# if we haven't cached a steam username, fetch one
			if not steam_usernames.has(fetched_steam_id):
				var member_steam_name: String = Steam.getFriendPersonaName(fetched_steam_id)
				steam_usernames[fetched_steam_id] = member_steam_name

			# if we haven't cached a steam avatar, fetch one
			if not steam_avatars.has(fetched_steam_id):
				Steam.getPlayerAvatar(3, fetched_steam_id)

	# emit signal
	friends_lobby_list_updated.emit(results)

## Fetch information on the users This will update _lobby.players_data
func get_lobby_members(lobby_id: int) -> void:
	var num_members: int = Steam.getNumLobbyMembers(lobby_id)
	# Get the data of these players from Steam
	for this_member: int in range(0, num_members):
		# Get the member's Steam ID
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, this_member)
		# Get the member's Steam name
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		# Kick off a request for the member's Steam avatar
		Steam.getPlayerAvatar(3, member_steam_id)
		# Emit signal
		got_steam_username.emit(member_steam_id, member_steam_name)
		# Cache the steam username
		steam_usernames[member_steam_id] = member_steam_name


# connect to Steam.avatar_loaded so that we can cache steam avatars to avoid requesting them from steam
# every time we need them.
func _on_steam_avatar_loaded(avatar_id: int, size: int, data: Array) -> void:
	# convert the raw data to an image
	var avatar_image: Image = Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, data)
	# make an ImageTexture from the image
	var avatar_texture: ImageTexture = ImageTexture.create_from_image(avatar_image)
	# save that image in `steam_avatars`
	steam_avatars.set(avatar_id, avatar_texture)
	# emit signal
	avatar_loaded.emit(avatar_id, avatar_texture)
