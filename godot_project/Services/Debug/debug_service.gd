extends Node

const ARG_PLAYER_USERAME_OVERRIDE: String = "username"

@onready var _lobby: LobbyService = LobbyService

func _ready() -> void:
	var arguments: Dictionary[String, String] = {}
	for argument: String in OS.get_cmdline_args():
		if argument.contains("="):
			var key_value: PackedStringArray = argument.split("=")
			arguments[key_value[0].trim_prefix("--")] = key_value[1]
		else:
			# Options without an argument will be present in the dictionary,
			# with the value set to an empty string.
			arguments[argument.trim_prefix("--")] = ""

	if "username" in arguments:
		_lobby.my_player_data.username = arguments["username"]
	
	if "host" in arguments:
		await get_tree().create_timer(0.1).timeout
		_lobby.create_lobby()
	
	if "client" in arguments:
		await get_tree().create_timer(0.2).timeout
		_lobby.join_lobby()
