extends Node

@onready var _lobby := LobbyService

const PACKET_READ_LIMIT = 999

func _ready() -> void:
	Steam.network_messages_session_request.connect(_on_network_messages_session_request)
	Steam.network_messages_session_failed.connect(_on_network_messages_session_failed)
	
func _process(_delta) -> void:
	# If the player is connected, read packets
	if _lobby.lobby_id > 0:
		read_messages()

func _on_network_messages_session_request(remote_id: int) -> void:
	# Get the requester's name
	var this_requester: String = Steam.getFriendPersonaName(remote_id)
	print("%s is requesting a P2P session" % this_requester)

	# Accept the P2P session; can apply logic to deny this request if needed
	Steam.acceptSessionWithUser(remote_id)

	# Make the initial handshake
	make_p2p_handshake()

func _on_network_messages_session_failed():
	pass
