extends Control

class_name GameHUD

# --- REFERÊNCIAS ---
# O GameManager precisa estar no node pai ou definido corretamente
@onready var manager = $".."
# O InputHandler é irmão deste nó na árvore (MANTIDO)
@onready var input_handler = $"../InputHandler" 

# --- REFERÊNCIAS UI PLAYER 1 ---
@onready var p1_name_lbl = $p1/VBoxContainer/HBoxContainer/p1_name
@onready var p1_total_lbl = $p1/VBoxContainer/HBoxContainer2/p1_total
@onready var p1_round_lbl = $p1/VBoxContainer/HBoxContainer3/p1_round
@onready var p1_selected_lbl = $p1/VBoxContainer/HBoxContainer4/p1_selecionado

# --- REFERÊNCIAS UI PLAYER 2 ---
@onready var p2_container = $p2
@onready var p2_name_lbl = $p2/VBoxContainer/HBoxContainer/p2_name
@onready var p2_total_lbl = $p2/VBoxContainer/HBoxContainer2/p2_total
@onready var p2_round_lbl = $p2/VBoxContainer/HBoxContainer3/p2_round
@onready var p2_selected_lbl = $p2/VBoxContainer/HBoxContainer4/p2_selecionado

# --- REFERENCIAS UI PONTUAÇÃO ---
@onready var final_score: Label = $selected_score
@onready var p1_scorebar = $P1_progress
@onready var p2_scorebar = $P2_progress

# --- COMPONENTES VISUAIS EXTRAS ---
@onready var radial_progress = $TextureProgressBar
@onready var farkle_screen = $Farklescreen
@onready var sfx_farkle = $AwwSfx422271

func _ready():
	self.hide() 
	
	if radial_progress:
		radial_progress.visible = false
		radial_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
		radial_progress.value = 0
		
	if farkle_screen:
		farkle_screen.visible = false
		farkle_screen.modulate.a = 0

func _process(_delta: float) -> void:
	if not visible or not manager: 
		return
	
	atualizar_textos()
	atualizar_barras()
	
	if input_handler:
		gerenciar_radial_menu()

func atualizar_textos():
	if final_score:
		final_score.text = str(manager.target_score)
		
	var selected_score = _calcular_score_selecionado_atual()
	var round_score = manager.round_score
	
	# --- ATUALIZA P1 ---
	if p1_name_lbl: p1_name_lbl.text = "Player 1"
	if p1_total_lbl: p1_total_lbl.text = str(manager.score_p1)

	if manager.current_state == GameManager.State.PLAYING_P1:
		p1_round_lbl.text = str(round_score)
		p1_selected_lbl.text = str(selected_score) if selected_score > 0 else ""
	else:
		p1_round_lbl.text = ""
		p1_selected_lbl.text = ""

	# --- ATUALIZA P2 (COM NOME DINÂMICO) ---
	# 🆕 Pega o nome do Boss se for IA
	var p2_display_name = "Player 2"
	if manager.is_vs_ai and manager.ai_player:
		if "boss_name" in manager.ai_player:
			p2_display_name = manager.ai_player.boss_name
		else:
			p2_display_name = "IA" # Fallback
	
	if p2_name_lbl: p2_name_lbl.text = p2_display_name
	if p2_total_lbl: p2_total_lbl.text = str(manager.score_p2)

	# Verifica se é a vez do P2
	if manager.current_state == GameManager.State.PLAYING_P2:
		p2_round_lbl.text = str(round_score)
		p2_selected_lbl.text = str(selected_score) if selected_score > 0 else ""
		
		# Ajusta rotação da UI (se for humano vs humano local, vira a tela)
		if p2_container:
			p2_container.rotation = 0 if manager.is_vs_ai else deg_to_rad(180)
	else:
		p2_round_lbl.text = ""
		p2_selected_lbl.text = ""

func atualizar_barras():
	if not manager or manager.target_score <= 0: return

	# 1. Configura o valor máximo (Meta)
	p1_scorebar.max_value = manager.target_score
	p2_scorebar.max_value = manager.target_score
	
	# 2. Garante que o P2 cresça da direita para a esquerda (se não configurou no editor)
	p2_scorebar.fill_mode = ProgressBar.FILL_END_TO_BEGIN # Ou 1 no Godot 4
	
	# 3. Animação suave dos valores
	# Criamos um tween para cada barra para o movimento não ser "seco"
	var tween = create_tween().set_parallel(true)
	
	tween.tween_property(p1_scorebar, "value", manager.score_p1, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	tween.tween_property(p2_scorebar, "value", manager.score_p2, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		
func atualizar_orientacao_ui():
	if not manager: return
	if p2_container:
		p2_container.rotation = 0 if manager.is_vs_ai else deg_to_rad(180)



func gerenciar_radial_menu():
	# Lógica para saber se pode mostrar o menu radial
	var selected_score = _calcular_score_selecionado_atual()
	var pontos_totais_mesa = manager.round_score + selected_score
	
	# Regras para aparecer o radial:
	# 1. Tem input de toque?
	# 2. Tem pontos para salvar?
	# 3. Os dados pararam de rolar? (rolling_count == 0)
	# 4. É a vez de um humano? (pode_interagir_humano no Manager)
	
	var pode_interagir = manager.rolling_count == 0 and manager.pode_interagir_humano()
	
	if input_handler.is_touching and pontos_totais_mesa > 0 and pode_interagir:
		var progress = input_handler.get_hold_progress()
		
		if progress > 0:
			radial_progress.visible = true
			radial_progress.global_position = get_viewport().get_mouse_position() - (radial_progress.size / 2) - Vector2(0, 50)
			radial_progress.value = progress * 100
			
			if progress >= 1.0:
				radial_progress.modulate = Color.GREEN
				manager.acao_parar()
			else:
				radial_progress.modulate = Color.WHITE
		else:
			radial_progress.visible = false
	else:
		if radial_progress and radial_progress.visible:
			radial_progress.visible = false
			radial_progress.value = 0

# --- HELPER: Calcula pontos visualmente ---
# O Manager faz isso internamente, mas a UI precisa saber antes de confirmar
func _calcular_score_selecionado_atual() -> int:
	var valores_selecionados = []
	
	# Percorre os dados ativos no Manager
	for d in manager.active_dice:
		# Verifica se o dado é válido e se tem a propriedade is_selected
		if is_instance_valid(d) and "is_selected" in d and d.is_selected:
			if "final_value" in d:
				valores_selecionados.append(d.final_value)
	
	if valores_selecionados.is_empty():
		return 0
		
	return FarkleRules.calculate_score(valores_selecionados)

# --- FARKLE SCREEN (Chamado pelo Manager) ---
# Adicionei esta função pública para o Manager poder chamar quando der Farkle
func exibir_farkle_aviso():
	exibir_tela_farkle()
	var t = create_tween()
	t.tween_interval(1.5)
	t.tween_callback(ocultar_farkle_screen)

func exibir_tela_farkle():
	
	if manager.current_state == manager.State.PLAYING_P2 and not manager.is_vs_ai:
		farkle_screen.rotation = deg_to_rad(180)
	else:
		farkle_screen.rotation = deg_to_rad(0)
	
	if farkle_screen:
		farkle_screen.visible = true
		farkle_screen.modulate.a = 0
		var label = farkle_screen.get_child(0) # Assume que tem um Label dentro
		if label is Label:
			label.scale = Vector2.ONE
			label.pivot_offset = label.size / 2
		
		if sfx_farkle: sfx_farkle.play()
		
		var tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(farkle_screen, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
		
		if label:
			tw.tween_property(label, "scale", Vector2(1.5, 1.5), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.chain().tween_property(label, "scale", Vector2(1.0, 1.0), 0.1)

func ocultar_farkle_screen():
	if farkle_screen and farkle_screen.visible:
		var tw = create_tween()
		tw.tween_property(farkle_screen, "modulate:a", 0.0, 0.2)
		tw.tween_callback(func(): farkle_screen.hide())
