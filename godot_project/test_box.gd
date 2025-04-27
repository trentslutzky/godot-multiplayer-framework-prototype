extends CSGBox3D

@export var username_label: Label3D

@onready var _lobby: LobbyService = LobbyService


func _ready() -> void:
	username_label.text = _lobby.players.get(get_multiplayer_authority()).get("username")


func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if Input.is_action_pressed("ui_left"):
		self.position += Vector3(-0.05, 0, 0)
	if Input.is_action_pressed("ui_right"):
		self.position += Vector3(0.05, 0, 0)
	if Input.is_action_pressed("ui_up"):
		self.position += Vector3(0, 0.05, 0)
	if Input.is_action_pressed("ui_down"):
		self.position += Vector3(0, -0.05, 0)
