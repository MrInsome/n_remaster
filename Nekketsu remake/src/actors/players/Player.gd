extends CharacterBase

# Основные параметры игрока
@export var is_active_player: bool = true

# Параметры рывка (даша)
@export var dash_speed_multiplier: float = 2.0
@export var dash_duration: float = 0.3
@export var dash_input_window: float = 0.25

# Параметры отбрасывания (нокаут)
@export var knockback_force: float = 200.0
@export var knockback_up: float = 200.0

# "Высота" над плоскостью (для прыжков)
var z_pos: float = 0.0
var z_vel: float = 0.0

# Состояния
enum State { IDLE, WALK, RUN, JUMP, FALLING, PUNCH, LOW_KICK, JUMP_KICK, JUMP_SLAM, HURT, DEAD, LOW_KICKED, SHOULDER_PUNCH, UNSTABLE_POS1, ROLL, KNOCKDOWN }
var state: State = State.IDLE
var lock_until_anim_end: bool = false

# Узлы
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Сигналы
signal landed

# Счетчик подряд идущих ударов
var _consecutive_hits: int = 0

# Вспомогательные переменные для даша
var _last_tap_time: float = 0.0
var _last_tap_dir: int = 0
var _dash_timer: float = 0.0

func _ready() -> void:
	health = max_health
	_last_tap_time = 0.0
	add_to_group("players")
	sprite.play("stand")
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_anim_finished)
	hitbox.area_entered.connect(_on_hitbox_area_entered)

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if is_active_player and not lock_until_anim_end:
		_update_tap_timer(delta)
		_handle_input(delta)
		_handle_jump(delta)
		_handle_attack()

	_apply_movement()
	_update_state_by_movement()
	_update_animation()

func _update_tap_timer(delta: float) -> void:
	_last_tap_time = max(_last_tap_time - delta, 0.0)

func _handle_input(delta: float) -> void:
	# Обработка направления
	var dir = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)

	# Детекция двойного нажатия для даша
	if Input.is_action_just_pressed("move_right"):
		if _last_tap_dir == 1 and _last_tap_time > 0.0:
			_dash_timer = dash_duration
		_last_tap_dir = 1
		_last_tap_time = dash_input_window
	elif Input.is_action_just_pressed("move_left"):
		if _last_tap_dir == -1 and _last_tap_time > 0.0:
			_dash_timer = dash_duration
		_last_tap_dir = -1
		_last_tap_time = dash_input_window

	# Вычисление текущей скорости с учётом даша
	var current_speed = speed
	if _dash_timer > 0.0:
		current_speed *= dash_speed_multiplier
		_dash_timer -= delta

	# Установка скорости движения и состояния
	if dir.length() > 0:
		dir = dir.normalized()
		velocity.x = dir.x * current_speed
		velocity.y = dir.y * current_speed
		state = State.RUN if _dash_timer > 0.0 else State.WALK
	else:
		velocity = Vector2.ZERO

func _handle_attack() -> void:
	# Атаки на земле
	if z_pos == 0.0 and state in [State.IDLE, State.WALK, State.RUN]:
		if Input.is_action_just_pressed("punch"):
			if _dash_timer > 0.0:
				_set_state(State.SHOULDER_PUNCH)
			else:
				_set_state(State.PUNCH)
		elif Input.is_action_just_pressed("kick"):
			_set_state(State.LOW_KICK)

	# Атаки в воздухе
	elif z_pos > 0.0 and state in [State.JUMP, State.FALLING]:
		if Input.is_action_just_pressed("kick"):
			_set_state(State.JUMP_KICK)
		elif Input.is_action_just_pressed("punch"):
			_set_state(State.JUMP_SLAM)

func _handle_jump(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and z_pos == 0.0:
		z_vel = jump_force
		_set_state(State.JUMP)

	if z_pos > 0.0 or z_vel > 0.0:
		z_vel -= gravity_z * delta
		z_pos = max(0.0, z_pos + z_vel * delta)
		if z_pos == 0.0 and z_vel <= 0.0:
			z_vel = 0.0
			emit_signal("landed")

func _apply_movement() -> void:
	collision_shape.disabled = z_pos > 0.0
	move_and_slide()
	sprite.position.y = -z_pos

func _update_state_by_movement() -> void:
	if state in [State.PUNCH, State.LOW_KICK, State.JUMP_KICK, State.JUMP_SLAM, State.HURT, State.DEAD, State.LOW_KICKED, State.SHOULDER_PUNCH, State.UNSTABLE_POS1, State.ROLL, State.KNOCKDOWN]:
		return

	if z_pos > 0.0:
		state = State.JUMP if z_vel > 0.0 else State.FALLING
	elif velocity.length() < 1.0:
		state = State.IDLE

func _update_animation() -> void:
	match state:
		State.IDLE:           sprite.play("stand")
		State.WALK:           sprite.play("walk")
		State.RUN:            sprite.play("run")
		State.JUMP:           sprite.play("jump")
		State.FALLING:        sprite.play("falling")
		State.PUNCH:          sprite.play("punch")
		State.LOW_KICK:       sprite.play("low_kick")
		State.JUMP_KICK:      sprite.play("jump_kick")
		State.JUMP_SLAM:      sprite.play("jump_slam")
		State.HURT:           sprite.play("punched")
		State.LOW_KICKED:     sprite.play("low_kicked")
		State.SHOULDER_PUNCH: sprite.play("shoulder_punch")
		State.UNSTABLE_POS1:  sprite.play("unstable_pos_1")
		State.ROLL:           sprite.play("roll")
		State.KNOCKDOWN:      sprite.play("fall")
		State.DEAD:           sprite.play("slamed_back")

	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

func _set_state(s: State) -> void:
	state = s
	lock_until_anim_end = s in [State.PUNCH, State.LOW_KICK, State.JUMP_KICK, State.JUMP_SLAM, State.HURT, State.LOW_KICKED, State.SHOULDER_PUNCH, State.UNSTABLE_POS1, State.ROLL]
	_update_animation()

func _on_anim_finished() -> void:
	match state:
		# Обычные атаки и урон
		State.PUNCH, State.LOW_KICK, State.JUMP_KICK, State.JUMP_SLAM, State.SHOULDER_PUNCH, State.LOW_KICKED, State.HURT:
			_set_state(State.IDLE)
		# Специальная логика после 3 ударов
		State.UNSTABLE_POS1:
			_set_state(State.ROLL)
		State.ROLL:
			_start_fall_sequence()
		# Смерть
		State.DEAD:
			queue_free()

func _start_fall_sequence() -> void:
	# Падение на 2 секунды с анимацией "fall"
	state = State.KNOCKDOWN
	sprite.play("fall")
	# Заблокировать ввод до конца последовательности
	lock_until_anim_end = true
	# Дождаться 2 секунд
	await get_tree().create_timer(2.0).timeout
	# Сброс хитов и возврат в стойку
	_consecutive_hits = 0
	_set_state(State.IDLE)

func _on_frame_changed() -> void:
	if state in [State.PUNCH, State.LOW_KICK, State.SHOULDER_PUNCH]:
		hitbox.monitoring = sprite.frame in [2, 3, 4]
	#elif state in [State.JUMP_KICK, State.JUMP_SLAM]:
		#hitbox.monitoring = sprite.frame in [0, 1]
	else:
		hitbox.monitoring = false

func _on_hitbox_area_entered(area: Area2D) -> void:
	var target = area.get_parent()
	if target != self and target is CharacterBody2D:
		var dir = (target.global_position - global_position).normalized()
		target.take_damage(10, dir, state)

func take_damage(amount: int, from_dir: Vector2 = Vector2.ZERO, attack_state: int = -1) -> void:
	if state == State.DEAD:
		return
	apply_damage(amount, from_dir)
	if health == 0:
		_set_state(State.DEAD)
		return
	# Увеличиваем число подряд идущих ударов
	_consecutive_hits += 1
	# Если 3 удара подряд — запускаем специальную логику
	if _consecutive_hits >= 3:
		_trigger_knockdown_sequence(from_dir)
	else:
		# Обычная реакция на урон
		if attack_state in [State.LOW_KICK, State.JUMP_KICK]:
			_set_state(State.LOW_KICKED)
		else:
			_set_state(State.HURT)
		

func _trigger_knockdown_sequence(from_dir: Vector2) -> void:
	# Устанавливаем скорость отбрасывания
	velocity = from_dir * knockback_force
	z_vel = knockback_up
	# Начинаем последовательность: нестабильная поза
	_set_state(State.UNSTABLE_POS1)
	lock_until_anim_end = true
