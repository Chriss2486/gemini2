extends OmniLight3D

@export var eh_player_1: bool = true
@export var energia_ativa: float = 2.5
@export var energia_espera: float = 0.3

var e_minha_vez: bool = false

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	var tempo = Time.get_ticks_msec() * 0.001
	
	if e_minha_vez:
		var pulse = lerp(0.6, 1.0, (sin(tempo * 3.5) + 1.0) * 0.5)
		light_energy = pulse * energia_ativa
	else:
		var pulse = lerp(0.2, 0.5, (sin(tempo * 1.0) + 1.0) * 0.5)
		light_energy = pulse * energia_espera
		
func set_active(p1_active: bool):
	if eh_player_1:
		e_minha_vez = p1_active
	else:
		e_minha_vez = not p1_active
