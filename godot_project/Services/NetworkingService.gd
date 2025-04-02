extends Node

var handler: GenericNetworkingHandler

var is_server := false

### SIGNALS ###
signal signal_joining_lobby
signal signal_lobby_joined
signal signal_failed_to_join_lobby(error_text: String)
signal signal_creating_lobby
signal signal_lobby_created
signal signal_failed_to_create_lobby(error_text: String)
signal signal_peer_set

func _ready() -> void:
	## initialize handler ##
	init_new_networking_handler(false)

func init_new_networking_handler(use_steam: bool):
	if handler != null:
		handler.queue_free()
	handler = SteamNetworkingHandler.new() if use_steam else LocalNetworkingHandler.new()
	add_child(handler)
