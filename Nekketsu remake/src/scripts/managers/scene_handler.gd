extends CanvasLayer
@onready var overlay := $ColorRect
@onready var anim    := $AnimationPlayer

func _ready() -> void:
	overlay.visible = false
	overlay.modulate.a = 0.0

func transition_to(callback: Callable) -> void:
	overlay.visible = true

	# --- Затухание ---
	if anim.has_animation("fade_out"):
		anim.play("fade_out")
		await anim.animation_finished
	else:
		await get_tree().process_frame   # минимум один кадр — на всякий случай

	# --- Смена состояния (бой, меню и т.п.) ---
	callback.call()

	# --- Проявление ---
	if anim.has_animation("fade_in"):
		anim.play("fade_in")
		await anim.animation_finished

	overlay.visible = false
