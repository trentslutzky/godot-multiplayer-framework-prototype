extends Button
class_name LobbyMenuPlayerItem

var player_data: PlayerData

@export var username_label: RichTextLabel
@export var host_label: RichTextLabel
@export var avatar: SteamAvatarTextureRect

func _ready() -> void:
	username_label.text = player_data.username
	host_label.visible = player_data.peer_id == 1
	avatar.my_steam_id = player_data.steam_id
	avatar.reload()
