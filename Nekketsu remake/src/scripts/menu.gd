extends Control
signal battle_requested

func _ready() -> void:
	$VBoxContainer/BattleButton.pressed.connect(_on_battle_pressed)

func _on_battle_pressed() -> void:
	battle_requested.emit()
