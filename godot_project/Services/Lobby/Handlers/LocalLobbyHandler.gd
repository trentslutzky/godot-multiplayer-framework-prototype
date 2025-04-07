extends GenericLobbyHandler
class_name LocalLobbyHandler

const DEFAULT_SERVER_IP = "127.0.0.1"  # IPv4 localhost as a placeholder
const PORT = 7001

@onready var _lobby := LobbyService

func _ready() -> void:
	self.name = "LocalNetworkingHandler"
	peer = ENetMultiplayerPeer.new()

# starts a lobby (using localhost)
func create_lobby() -> void:
	_lobby.creating_lobby.emit()
	# init a multiplayer peer object
	var error = peer.create_server(PORT, _lobby.MAX_PLAYERS)
	if error:
		if error != ERR_ALREADY_IN_USE:
			push_warning(error)
			_lobby.failed_to_create_lobby.emit(error)
			return
	# set the local peer to initialized peer
	multiplayer.multiplayer_peer = peer
	_lobby.created_lobby.emit()


func join_lobby(_lobby_id = -1) -> void:
	_lobby.joining_lobby.emit()
	# init a multiplayer peer object
	var error = peer.create_client(DEFAULT_SERVER_IP, PORT)
	if error:
		if error != ERR_ALREADY_IN_USE:
			push_warning(error)
			_lobby.failed_to_join_lobby.emit(error)
			return
	multiplayer.multiplayer_peer = peer
	joining = true
	# if we haven't connected after a second, that means a server
	# probably isn't running.
	await get_tree().create_timer(2.0).timeout
	if joining:
		if peer.get_connection_status() != 2:
			_lobby.failed_to_join_lobby.emit("lobby isn't running")
			joining = false


func _process(_delta: float) -> void:
	if not joined and joining:
		if peer.get_connection_status() == 2:
			joined = true
			joining = false
			_lobby.joined_lobby.emit()
