extends Node3D

@onready var manager = $".."
@onready var p1 = $p1_flies/p1_light
@onready var p2 = $p2_flies/p2_light
@onready var candle_p_1 = $p1_flies # Agora representa o GPUParticles3D do P1
@onready var candle_p_2 = $p2_flies # Agora representa o GPUParticles3D do P2

func trocar_turno(player):
	if player == 1:
		esconder_luz(p2)
		mostrar_luz(p1)
	else:
		esconder_luz(p1)
		mostrar_luz(p2)

func mostrar_luz(luz: Light3D):
	if not luz: return
	
	luz.visible = true
	_alternar_chama(luz, true) # Ativa a emissão de partículas (vagalumes)
	
	var tween = get_tree().create_tween()
	# No 3D usamos light_energy em vez de intensidade_base
	tween.tween_property(luz, "light_energy", 2.5, 0.5)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

func esconder_luz(luz: Light3D):
	if not luz: return
	
	_alternar_chama(luz, false) # Para a emissão das partículas
	
	var tween = get_tree().create_tween()
	# Em vez de apagar totalmente, podemos deixar um brilho residual (0.2) 
	# ou zerar (0.0) conforme sua preferência
	tween.tween_property(luz, "light_energy", 0.0, 0.5)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)

	# A luz só fica invisível após o fade out
	tween.tween_callback(func(): luz.visible = false)

# Função adaptada para GPUParticles3D ou Mesh com Shader
func _alternar_chama(luz: Light3D, ligar: bool):
	var sistema_vagalumes = candle_p_1 if luz == p1 else candle_p_2
	
	if sistema_vagalumes:
		if sistema_vagalumes is GPUParticles3D:
			sistema_vagalumes.emitting = ligar
		if sistema_vagalumes.get_child_count() > 0:
			var chama = sistema_vagalumes.get_child(0)
			
			if chama is GPUParticles3D:
				chama.emitting = ligar
			else:
				chama.visible = ligar
