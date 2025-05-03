extends Node
var current_state := "menu"
var players: Array = []

func _ready() -> void:
	# откладываем, чтобы меню создалось после того,
	# как Main окончательно войдёт в дерево
	call_deferred("show_menu")

func show_menu() -> void:
	var menu_scene := preload("res://src/scenes/Menu.tscn")
	var menu := menu_scene.instantiate()

	# Можно добавить либо к себе…
	# add_child(menu)

	# …либо к корневой сцене, но через call_deferred
	get_tree().current_scene.call_deferred("add_child", menu)

	menu.battle_requested.connect(_on_battle_requested)


func _on_battle_requested() -> void:
	get_node("/root/Main/SceneHandler").transition_to(start_battle)

func start_battle() -> void:
	# уничтожаем меню, если нужно
	for c in get_tree().current_scene.get_children():
		if c is Control and c.name == "Menu":
			c.queue_free()

	var hud_scene := preload("res://src/ui/hud/hud.tscn")
	var hud := hud_scene.instantiate()
	get_tree().current_scene.add_child(hud)

	var player_scene := preload("res://src/actors/players/Player.tscn")
	var arena : Node2D = get_parent().get_node("Arena")

	var p1 := player_scene.instantiate()
	p1.position   = arena.get_node("SpawnPoints/P1").global_position
	p1.is_active_player = true
	hud.update_health(p1.health, p1.max_health)
	p1.health_changed.connect(hud.update_health)

	var p2 := player_scene.instantiate()
	p2.position   = arena.get_node("SpawnPoints/P2").global_position
	p2.is_active_player = false

	arena.add_child(p1)
	arena.add_child(p2)

	# музыка арены
	var music := AudioStreamPlayer.new()
	music.stream = preload("res://assets/audio/music/20 - The Final Match.mp3")
	arena.add_child(music)
	music.play()

	players = [p1, p2]
	current_state = "battle"
