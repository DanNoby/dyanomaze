extends Label

var current_score: int = 0
var base_scale: Vector2

func _ready():
	pivot_offset = size / 2.0
	base_scale = scale
	text = str("SCORE: ", current_score)
	modulate = Color(1, 1, 1) # Ensure it starts pure white

# We added 'flash_color' to the arguments here
func add_score(amount: int, do_pulse: bool = false, flash_color: Color = Color(1, 1, 1)):
	current_score += amount
	text = str("SCORE: ", current_score)
	
	if do_pulse:
		pulse_effect(flash_color)

func pulse_effect(flash_color: Color):
	var tween = create_tween()
	
	# 1. The Scale Pop
	tween.tween_property(self, "scale", base_scale * 1.8, 0.05).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", base_scale, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	# 2. The Color Flash (Uses whatever color was passed in, then fades back to white)
	modulate = flash_color
	tween.parallel().tween_property(self, "modulate", Color(1, 1, 1), 0.3)
