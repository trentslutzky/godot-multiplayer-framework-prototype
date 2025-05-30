extends Control

@export_category("Main Menu")
@export var menu_landing: Control
@export var main_menu_host_button: Button
@export var main_menu_join_button: Button
@export var main_menu_quit_button: Button

@export_category("Lobby Menu")
@export var lobby_menu: Control

@export_category("Loading Screen")
@export var loading: Control
@export var loading_text: RichTextLabel

@export_category("Join Menu")
@export var join_menu: Control
@export var back_button: Button

@export_category("Other")
@export var error_text: RichTextLabel

@onready var _lobby: LobbyService = LobbyService
@onready var _steam: SteamService = SteamService
@onready var _game_sequence: GameSequence = GameSequence

func _ready() -> void:
	show_main_menu()
	
	# main menu
	main_menu_host_button.pressed.connect(_on_main_menu_host_button_pressed)
	main_menu_join_button.pressed.connect(_on_main_menu_join_button_pressed)
	main_menu_quit_button.pressed.connect(_on_main_menu_quit_button_pressed)
	
	# join menu
	back_button.pressed.connect(_on_join_menu_back_button_pressed)
	
	# lobby signals
	_lobby.creating_lobby.connect(_on_creating_lobby)
	_lobby.joining_lobby.connect(_on_joining_lobby)
	_lobby.joined_lobby.connect(_on_lobby_joined)
	_lobby.created_lobby.connect(_on_lobby_joined)
	_lobby.lobby_error.connect(_on_lobby_error)
	_lobby.left_lobby.connect(_on_left_lobby)
	
	# game sequence signals
	_game_sequence.game_starting.connect(_on_game_sequence_game_starting)
	
	error_text.text = ""


func _on_creating_lobby() -> void:
	_show_loading_screen("Creating lobby...")

func _on_joining_lobby() -> void:
	_show_loading_screen("Joining lobby...")


func _on_lobby_joined() -> void:
	_show_lobby_menu()


func _on_left_lobby() -> void:
	show_main_menu()


func _on_lobby_error(error: String) -> void:
	error_text.text = error
	show_main_menu()


func _on_main_menu_host_button_pressed() -> void:
	_lobby.create_lobby()


func _on_main_menu_join_button_pressed() -> void:
	if OS.has_feature("steam"):
		_steam.get_friends_in_lobbies()
		show_join_menu()
	else:
		_lobby.join_lobby()


func _on_join_menu_back_button_pressed() -> void:
	show_main_menu()


func _on_main_menu_quit_button_pressed() -> void:
	get_tree().quit()


func _on_game_sequence_game_starting() -> void:
	self.visible = false


func _show_loading_screen(text: String = "") -> void:
	menu_landing.visible = false
	lobby_menu.visible = false
	loading.visible = true
	join_menu.visible = false
	loading_text.text = text
	error_text.text = ""


func _show_lobby_menu() -> void:
	menu_landing.visible = false
	lobby_menu.visible = true
	loading.visible = false
	join_menu.visible = false


func show_main_menu() -> void:
	menu_landing.visible = true
	lobby_menu.visible = false
	loading.visible = false
	join_menu.visible = false


func show_join_menu() -> void:
	menu_landing.visible = false
	lobby_menu.visible = false
	loading.visible = false
	join_menu.visible = true
