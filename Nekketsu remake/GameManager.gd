extends Node

var current_state: String = "menu"  # Состояния: menu, battle, lobby, game_over
var players = []                    # Массив активных игроков

func switch_state(new_state: String) -> void:
	# Логика переключения между меню, битвой и т.д.
	pass
