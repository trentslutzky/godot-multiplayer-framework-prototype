extends Control

@onready var _net := NetworkingService
@onready var _lobby := LobbyService

var lobby_id: String = ""

@export_category("buttons")
@export var host_button: Button
@export var join_button: Button
@export var lobby_joined_label: RichTextLabel
@export var players_data_label: RichTextLabel
@export var use_steam_checkbox: CheckBox
@export var lobby_id_linedit: LineEdit
@export var main_landing: Control

func _ready() -> void:
	## connect local signals ##
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	use_steam_checkbox.toggled.connect(_use_steam_checkbox_toggled)
	lobby_id_linedit.text_changed.connect(_lobby_id_linedit_changed)
	
	## reset UI elements ##
	lobby_joined_label.text = ""

	_net.signal_joining_lobby.connect(_on_joining_lobby)
	_net.signal_creating_lobby.connect(_on_joining_lobby)
	_net.signal_lobby_created.connect(_on_lobby_joined)
	_net.signal_lobby_joined.connect(_on_lobby_joined)
	_net.signal_failed_to_create_lobby.connect(_lobby_create_or_join_failed)
	_net.signal_failed_to_join_lobby.connect(_lobby_create_or_join_failed)
	
	multiplayer.server_disconnected.connect(_server_disconnected)


func _server_disconnected():
	lobby_joined_label.text = "The lobby closed."
	main_landing.visible = true


func _process(delta: float) -> void:
	if not _lobby.in_lobby:
		players_data_label.text = ""
		return
	players_data_label.text = "my_peer_id: " + str(multiplayer.get_unique_id()) + "\n" + str(_lobby.players)


func _on_joining_lobby():
	lobby_joined_label.text = "Joining..."
	main_landing.visible = false


func _on_lobby_joined():
	lobby_joined_label.text = "Joined!"
	main_landing.visible = false


func _lobby_create_or_join_failed(error: int):
	lobby_joined_label.text = "Failed to join lobby"
	main_landing.visible = true


func _on_host_button_pressed():
	_net.handler.lobby_host()


func _on_join_button_pressed():
	_net.handler.lobby_join(int(lobby_id))


func _use_steam_checkbox_toggled(toggled_on: bool):
	_net.init_new_networking_handler(toggled_on)


func _lobby_id_linedit_changed(text: String):
	lobby_id = text
