extends GenericLobbyHandler
class_name SteamLobbyHandler

@onready var _steam: SteamService = SteamService
@onready var _lobby: LobbyService = LobbyService

@onready var peer: SteamMultiplayerPeer = SteamMultiplayerPeer.new()

func _ready() -> void:
	self.name = "SteamNetworkingHandler"
	peer.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)


func join_lobby(lobby_id_to_join: int = -1) -> void:
	if joining: return
	joining = true
	joining_lobby.emit()
	var error: Error = peer.connect_lobby(lobby_id_to_join)
	if error:
		joining = false
		push_warning("Error joining steam lobby", error)
		failed_to_create_or_join.emit("Failed to join lobby")
		return


func create_lobby() -> void:
	if creating: return
	creating = true
	creating_lobby.emit()
	var error: Error = peer.create_lobby(peer.LOBBY_TYPE_FRIENDS_ONLY, _lobby.MAX_PLAYERS)
	if error:
		creating = false
		push_warning("Error creating steam lobby", error)
		failed_to_create_or_join.emit("Failed to create a lobby")
		return
	multiplayer.set_multiplayer_peer(peer)


func _on_lobby_created(connect_status: int, this_lobby_id: int) -> void:
	creating = false
	if connect_status != 1: return
	_lobby.lobby_id = this_lobby_id
	peer.set_lobby_joinable(true)
	Steam.setLobbyJoinable(this_lobby_id, true)
	created = true
	created_lobby.emit()
	_steam.get_lobby_members()
	multiplayer.set_multiplayer_peer(peer)


func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	joining = false
	creating = false
	## If joining was successful
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		
		multiplayer.set_multiplayer_peer(peer)
		_lobby.lobby_id = this_lobby_id
	else:
		# Get the failure reason
		var fail_reason: String

		match response:
			Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: fail_reason = "This lobby no longer exists."
			Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: fail_reason = "You don't have permission to join this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_FULL: fail_reason = "The lobby is now full."
			Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR: fail_reason = "Uh... something unexpected happened!"
			Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED: fail_reason = "You are banned from this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED: fail_reason = "You cannot join due to having a limited account."
			Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: fail_reason = "This lobby is locked or disabled."
			Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: fail_reason = "This lobby is community locked."
			Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: fail_reason = "A user in the lobby has blocked you from joining."
			Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: fail_reason = "A user you have blocked is in the lobby."
		
		if joining:
			failed_to_create_or_join.emit(fail_reason)
			
		if creating:
			failed_to_create_or_join.emit(fail_reason)


# A user's information has changed. Steam will call this periodically
func _on_persona_change(_this_steam_id: int, _flag: int) -> void:
	if _lobby.lobby_id == -1: return
	_steam.get_lobby_members()


func close_peer() -> void:
	peer.close()
