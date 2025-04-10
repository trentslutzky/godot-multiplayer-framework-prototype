extends MarginContainer
class_name LobbiesListItem

@export var steam_avatar_texture_rect: SteamAvatarTextureRect
@export var steam_username_label: RichTextLabel
@export var join_button: Button 

var steam_id: int
var lobby_id: int

@onready var _lobby: LobbyService = LobbyService
@onready var _steam: SteamService = SteamService

func _ready() -> void:
	join_button.pressed.connect(_on_join_button_pressed)
	steam_avatar_texture_rect.my_steam_id = steam_id
	steam_avatar_texture_rect.reload()
	if _steam.steam_usernames:
		steam_username_label.text = _steam.steam_usernames.get(steam_id)


func _on_join_button_pressed() -> void:
	_lobby.handler.join_lobby(lobby_id)
