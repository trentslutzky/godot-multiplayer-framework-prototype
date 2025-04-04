extends Node

var handler: GenericNetworkingHandler

### SIGNALS ###
signal signal_joining_lobby
signal signal_lobby_joined
signal signal_failed_to_join_lobby(error_text: String)
signal signal_creating_lobby
signal signal_lobby_created
signal signal_failed_to_create_lobby(error_text: String)
signal signal_peer_set
signal reset_multiplayer_state

func _ready() -> void:
	## initialize handler ##
	init_new_networking_handler(false)
	multiplayer.server_disconnected.connect(_server_disconnected)


func _server_disconnected():
	reset_multiplayer_state.emit()


func init_new_networking_handler(use_steam: bool):
	if handler != null:
		handler.queue_free()
	if use_steam:
		handler = SteamNetworkingHandler.new() 
	else:
		handler = LocalNetworkingHandler.new()
	add_child(handler)
