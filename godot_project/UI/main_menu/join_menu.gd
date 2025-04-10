extends Control

var list_item_scene: PackedScene = preload("res://UI/main_menu/components/lobbies_list/lobbies_list_item.tscn")

@export var refresh_button: Button
@export var lobbies_list: VBoxContainer

@onready var _steam := SteamService

func _ready() -> void:
	_steam.friends_lobby_list_updated.connect(_on_steam_friends_lobby_list_updated)
	refresh_button.pressed.connect(_on_refresh_button_pressed)


func _on_refresh_button_pressed():
	for child in lobbies_list.get_children():
		child.queue_free()
	_steam.get_friends_in_lobbies()


func _on_steam_friends_lobby_list_updated():
	for child in lobbies_list.get_children():
		child.queue_free()
	for steam_id in _steam.friends_lobby_ids:
		var new_list_item = list_item_scene.instantiate()
		new_list_item.steam_id = steam_id
		new_list_item.lobby_id = _steam.friends_lobby_ids[steam_id]
		lobbies_list.add_child(new_list_item)
