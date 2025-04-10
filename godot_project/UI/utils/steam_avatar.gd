extends TextureRect
class_name SteamAvatarTextureRect

@onready var _steam: SteamService = SteamService

var my_steam_id: int = -1

func _ready() -> void:
	_steam.avatar_loaded.connect(_on_steam_avatar_loaded)

func _on_steam_avatar_loaded(steam_id: int, in_texture: ImageTexture) -> void:
	if my_steam_id == steam_id:
		texture = in_texture

func reload() -> void:
	if my_steam_id in _steam.steam_avatars:
		texture = _steam.steam_avatars.get(my_steam_id, null)
