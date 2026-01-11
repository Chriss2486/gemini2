extends Node3D

@onready var manager = $".."
@onready var p1 = $p1Light
@onready var p2 = $p2Light
@onready var candle_p_1 = $CandleP1
@onready var candle_p_2 = $CandleP2


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
	_alternar_chama(luz, true) # Liga a chama
	
	var tween = get_tree().create_tween()
	tween.tween_property(luz, "intensidade_base", 70.0, 0.5)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

func esconder_luz(luz: Light3D):
	if not luz: return
	
	_alternar_chama(luz, false) # Desliga a chama
	
	var tween = get_tree().create_tween()
	tween.tween_property(luz, "intensidade_base", 0.0, 0.5)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)

	tween.tween_callback(func(): luz.visible = false)

# Função para encontrar a vela certa e acessar o filho 0 (chama)
func _alternar_chama(luz: Light3D, ligar: bool):
	var vela = candle_p_1 if luz == p1 else candle_p_2
	
	if vela and vela.get_child_count() > 0:
		var chama = vela.get_child(0) # Pega o filho 0
		
		# Se for partículas, usa emitting. Se for objeto comum, usa visible.
		if chama.has_method("set_emitting") or "emitting" in chama:
			chama.emitting = ligar
		else:
			chama.visible = ligar
