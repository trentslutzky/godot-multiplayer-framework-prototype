class_name LocalLobbyHandler
extends GenericLobbyHandler

# IPv4 localhost as a placeholder
const DEFAULT_SERVER_IP: String = "127.0.0.1"
# Port can be anything. set to 7001 to not interfere
const PORT: int = 7001

# Local instance of the lobby service
@onready var _lobby: LobbyService = LobbyService

# The multiplayer peer for this handler
@onready var _peer: ENetMultiplayerPeer


func _ready() -> void:
	# set the name so that we can see what the handler is in the tree
	self.name = "LocalNetworkingHandler"


## Attempt creating a lobby (using localhost)
func create_lobby() -> void:
	# emit the creating lobby signal
	creating_lobby.emit()
	# Initialize the peer
	_peer = ENetMultiplayerPeer.new()
	# Create a server and error out if there's an error
	var error: Error = _peer.create_server(PORT, _lobby.MAX_PLAYERS)
	if error:
		failed_to_create_or_join.emit("could_not_join", "Couldn't create a lobby. Error " + str(error))
		reset()
		return
	# set the local peer to initialized peer
	multiplayer.multiplayer_peer = _peer
	# emit the created lobby signal
	created_lobby.emit()


## Attemt to join the local lobby
func join_lobby(_lobby_id: int = -1) -> void:
	# emit thejoining_lobby signal
	joining_lobby.emit()
	# Initialize the peer
	_peer = ENetMultiplayerPeer.new()
	# Try to join a lobby and error out if there's an error
	var error: Error = _peer.create_client(DEFAULT_SERVER_IP, PORT)
	if error:
		failed_to_create_or_join.emit(error)
		reset()
		return
	# set the local peer to initialized peer
	multiplayer.multiplayer_peer = _peer
	# if we haven't connected after a second, that means a server
	# probably isn't running.
	await get_tree().create_timer(1.0).timeout
	if _peer.get_connection_status() != 2:
		failed_to_create_or_join.emit("no_lobby", "There isn't a local lobby running.")
		reset()

## Closes the handler's multiplayer peer
func close_peer() -> void:
	_peer.close()
	reset()
