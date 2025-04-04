extends GenericNetworkingHandler
class_name LocalNetworkingHandler

const DEFAULT_SERVER_IP = "127.0.0.1"  # IPv4 localhost as a placeholder
const PORT = 7001
const MAX_PEERS = 4  # can change. set as 4 for testing

@onready var _net := NetworkingService

func _ready() -> void:
	self.name = "LocalNetworkingHandler"

# starts a lobby (using localhost)
func lobby_host() -> void:
	_net.signal_creating_lobby.emit()
	peer = ENetMultiplayerPeer.new()
	_net.signal_peer_set.emit()
	# init a multiplayer peer object
	var error = peer.create_server(PORT, MAX_PEERS)
	if error:
		push_warning(error)
		_net.signal_failed_to_create_lobby.emit(error)
		return
	# set the local peer to initialized peer
	multiplayer.multiplayer_peer = peer
	_net.signal_lobby_created.emit()


func lobby_join(_lobby_id = -1) -> void:
	_net.signal_joining_lobby.emit()
	peer = ENetMultiplayerPeer.new()
	_net.signal_peer_set.emit()
	# init a multiplayer peer object
	var error = peer.create_client(DEFAULT_SERVER_IP, PORT)
	if error:
		push_warning(error)
		_net.signal_failed_to_join_lobby.emit(error)
		return
	multiplayer.multiplayer_peer = peer
	joining = true
	# if we haven't connected after a second, that means a server
	# probably isn't running.
	await get_tree().create_timer(2.0).timeout
	if joining:
		if peer.get_connection_status() != 2:
			_net.signal_failed_to_join_lobby.emit(-1)
			joining = false


func _process(_delta: float) -> void:
	if not joined and joining:
		if peer.get_connection_status() == 2:
			joined = true
			joining = false
			_net.signal_lobby_joined.emit()
