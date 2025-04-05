extends GenericLobbyHandler
class_name SteamLobbyHandler

@onready var _lobby := LobbyService

func _ready() -> void:
	self.name = "SteamNetworkingHandler"
	peer = SteamMultiplayerPeer.new()
	peer.lobby_created.connect(_on_lobby_created)
	peer.lobby_joined.connect(_on_lobby_joined)


func join_lobby(lobby_id_to_join = -1):
	joining = true
	_lobby.joining_lobby.emit()
	_lobby.steam_usernames.clear()
	peer.connect_lobby(lobby_id_to_join)


func create_lobby():
	if creating: return
	creating = true
	_lobby.creating_lobby.emit()
	peer.create_lobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, _lobby.MAX_PLAYERS)


func _on_lobby_created(connect_status: int, this_lobby_id: int) -> void:
	prints("_on_lobby_created", this_lobby_id)
	creating = false
	if connect_status != 1: return
	_lobby.lobby_id = this_lobby_id
	peer.set_lobby_joinable(true)
	_lobby.created_lobby.emit()


func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	prints("_on_lobby_joined", this_lobby_id, response)
	# If joining was successful
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		_lobby.lobby_id = this_lobby_id
		multiplayer.multiplayer_peer = peer
		if joining:
			joining = false
			_lobby.joined_lobby.emit()
		if creating:
			creating = false
			_lobby.created_lobby.emit()
		# Get the lobby members
		get_lobby_members()
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
			joining = false
			_lobby.failed_to_join_lobby.emit(fail_reason)

		if creating:
			creating = false
			_lobby.failed_to_create_lobby.emit(fail_reason)


# grabs steam information for players in the steam lobby
func get_lobby_members() -> void:
	_lobby.steam_usernames.clear()
	var num_members: int = Steam.getNumLobbyMembers(_lobby.lobby_id)
	# Get the data of these players from Steam
	for this_member in range(0, num_members):
		# Get the member's Steam ID
		var member_steam_id: int = Steam.getLobbyMemberByIndex(_lobby.lobby_id, this_member)
		# Get the member's Steam name
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		# Add them to the list
		_lobby.steam_usernames.set(member_steam_id, member_steam_name)
		
		for player_peer_id in _lobby.players_data:
			if _lobby.players_data[player_peer_id].steam_id == member_steam_id:
				_lobby.players_data[player_peer_id].username = member_steam_name


# A user's information has changed. Steam will call this periodically
func _on_persona_change(_this_steam_id: int, _flag: int) -> void:
	if _lobby.lobby_id == -1: return
	get_lobby_members()
