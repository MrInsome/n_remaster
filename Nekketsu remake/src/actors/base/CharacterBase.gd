extends CharacterBody2D
class_name CharacterBase

# Базовый класс для всех персонажей: управление здоровьем и базовыми параметрами
@export var speed: float = 200.0
@export var jump_force: float = 400.0
@export var gravity_z: float = 800.0
@export var max_health: int = 100

signal health_changed(new_health: int, max_health: int)
signal died

var health: int

func _ready() -> void:
	# Инициализация здоровья при старте
	health = max_health

func apply_damage(amount: int, _from_dir: Vector2 = Vector2.ZERO) -> void:
	# Универсальная функция получения урона
	health = clamp(health - amount, 0, max_health)
	emit_signal("health_changed", health, max_health)
	if health == 0:
		emit_signal("died")

func is_alive() -> bool:
	return health > 0
