extends Button

var player_data: PlayerData

func _ready() -> void:
	$username.text = player_data.username
	$host_label.visible = player_data.peer_id == 1
	$avatar.my_steam_id = player_data.steam_id
	$avatar.reload()
