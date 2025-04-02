extends GenericNetworkingHandler
class_name SteamNetworkingHandler

@onready var _lobby := LobbyService


func _ready() -> void:
	Steam.relay_network_status.connect(steam_network_status_change)
	self.name = "SteamNetworkingHandler"
	# set up signal for the lobby_joined callback
	Steam.lobby_joined.connect(_on_lobby_joined)
	peer = SteamMultiplayerPeer.new()
	_net.signal_peer_set.emit()

# Was running into the network trying to register before it was "fully?" connected through
# steam. this waits until it gets a network_status of 100 before joining, which seems to work.
func steam_network_status_change(
	available: int,
	_ping_measurement: int,
	_available_config: int,
	_available_relay: int,
	_debug_message: String
):
	if available == 100 and joining == true:
		joining = false
		_net.signal_lobby_joined.emit()


func lobby_join(lobby_id_to_join = -1):
	_net.signal_joining_lobby.emit()
	if lobby_id_to_join == -1:
		push_error("[SteamMultiplayerHandler] No lobby ID supplied to lobby_join()")
		_net.signal_failed_to_join_lobby.emit(-1)
		return

	# init a multiplayer peer object
	peer = SteamMultiplayerPeer.new()
	_net.signal_peer_set.emit()
	# join a lobby
	Steam.joinLobby(lobby_id_to_join)
	# tell the peer to connect to the lobby we joined
	peer.connect_lobby(lobby_id_to_join)
	# send connected peer to godot multiplayer
	multiplayer.multiplayer_peer = peer


func lobby_host():
	_net.signal_creating_lobby.emit()
	# init a multiplayer peer object
	peer = SteamMultiplayerPeer.new()
	_net.signal_peer_set.emit()
	# create a lobby
	peer.create_lobby(peer.LOBBY_TYPE_FRIENDS_ONLY, 4)
	# send connected peer to godot multiplayer
	multiplayer.multiplayer_peer = peer
	# set up callback signals
	peer.lobby_joined.connect(_on_lobby_joined)
	peer.lobby_created.connect(_on_lobby_created)


func _on_lobby_created(connect_status: int, this_lobby_id: int) -> void:
	# connect 1 means we connected successfully
	if connect_status != 1:
		_net.signal_lobby_created.emit()
		return
	# Set the lobby ID (will probably use this later)
	_lobby.lobby_id = this_lobby_id
	# Set this lobby as joinable, just in case, though this should be done by default
	Steam.setLobbyJoinable(this_lobby_id, true)
	# Allow P2P connections to fallback to being relayed through Steam if needed
	Steam.allowP2PPacketRelay(true)
	# tell gamestate we connected
	_net.signal_lobby_created.emit()


func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	# If joining was not successful
	if response != Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		# if we weren't successful, call on_lobby_joined with null
		_net.signal_failed_to_join_lobby.emit(-1)
		return
	# Set the lobby ID (will probably use this later)
	_lobby.lobby_id = this_lobby_id
	# set joining = true so the signal listener picks up a sucessful connection (see _ready function)
	joining = true
