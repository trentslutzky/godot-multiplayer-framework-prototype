extends GenericLobbyHandler
class_name LocalLobbyHandler

const DEFAULT_SERVER_IP: String = "127.0.0.1"  # IPv4 localhost as a placeholder
const PORT: int = 7001

@onready var _lobby: LobbyService = LobbyService
@onready var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

func _ready() -> void:
	self.name = "LocalNetworkingHandler"

# starts a lobby (using localhost)
func create_lobby() -> void:
	peer = ENetMultiplayerPeer.new()
	creating_lobby.emit()
	# init a multiplayer peer object
	var error: Error = peer.create_server(PORT, _lobby.MAX_PLAYERS)
	if error:
		if error != ERR_ALREADY_IN_USE:
			failed_to_create_or_join.emit("There is already a local lobby running.")
			reset()
			return
	# set the local peer to initialized peer
	multiplayer.multiplayer_peer = peer
	created_lobby.emit()


func join_lobby(_lobby_id: int = -1) -> void:
	peer = ENetMultiplayerPeer.new()
	joining_lobby.emit()
	# init a multiplayer peer object
	var error: Error = peer.create_client(DEFAULT_SERVER_IP, PORT)
	if error:
		if error != ERR_ALREADY_IN_USE:
			push_warning(error)
			failed_to_create_or_join.emit(error)
			return
	multiplayer.multiplayer_peer = peer
	joining = true
	# if we haven't connected after a second, that means a server
	# probably isn't running.
	await get_tree().create_timer(1.0).timeout
	if joining:
		if peer.get_connection_status() != 2:
			failed_to_create_or_join.emit("There isn't a local lobby running.")
			reset()


func _process(_delta: float) -> void:
	if not joined and joining and not created:
		if peer.get_connection_status() == 2:
			joined = true
			joining = false
			joined_lobby.emit()
