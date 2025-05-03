extends CanvasLayer
@onready var bar: TextureProgressBar = $HealthBar

func update_health(value: int, max_value: int) -> void:
	bar.max_value = max_value
	bar.value     = clamp(value, 0, max_value)
