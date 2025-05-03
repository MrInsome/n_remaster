extends CharacterBase
class_name Enemy

# Простейший ИИ противника: обнаружение и погоня за игроком
@export var detection_radius: float = 200.0
@export var chase_speed_multiplier: float = 1.0

var _player: CharacterBase = null

func _ready() -> void:
	# Найти игрока по группе "player"
	var players = get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		_player = players[0] as CharacterBase
	else:
		push_warning("Player node not found in group 'player'")

func _physics_process(delta: float) -> void:
	if not is_alive():
		return
	# Логика детекции и погони
	if _player and _player.is_alive():
		var dist := global_position.distance_to(_player.global_position)
		if dist <= detection_radius:
			var dir := (_player.global_position - global_position).normalized()
			velocity.x = dir.x * speed * chase_speed_multiplier
		else:
			velocity.x = 0
	else:
		velocity.x = 0
	# Обработка гравитации
	velocity.y += gravity_z * delta
	# Перемещение тела с учётом коллизий
	move_and_slide()
