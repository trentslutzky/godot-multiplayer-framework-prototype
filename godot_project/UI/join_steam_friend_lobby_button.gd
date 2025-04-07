extends Button

var steam_username: String
var steam_lobby_id: int

@onready var _lobby := LobbyService

func _ready() -> void:
	text = steam_username
	prints(steam_username, steam_lobby_id)
	
func _pressed():
	_lobby.handler.join_lobby(steam_lobby_id)
