extends Node3D

class_name GameManager

# --- ESTADOS DO JOGO ---
enum State { MENU, SETUP, PLAYING_P1, PLAYING_P2, GAMEOVER, PAUSED }

var indices_disponiveis: Array = []
var current_state = State.MENU
var previous_state = State.MENU

# --- EXPORTS ---
@export_group("UI Paineis")
@export var ui_menu: Control
@export var ui_setup: Control
@export var ui_hud: Control
@export var ui_gameover: Control
@export var ui_settings: Control

@export_group("Cena 3D")
@export var dice_scene: PackedScene
@export var spawn_point: Marker3D
@export var spawn_point_p2: Marker3D
@export var tray_p1: Marker3D
@export var tray_p2: Marker3D
@export var light_manager: Node3D

@onready var ai_player = $AIPlayer 

# --- VARIÁVEIS DE JOGO ---
var score_p1 = 0
var score_p2 = 0
var target_score = 3000
var is_vs_ai = true
var ai_difficulty = 1

var round_score = 0
var active_dice = []
var locked_dice_count = 0
var rolling_count = 0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	change_state(State.MENU)
	
	var input = $InputHandler
	if input:
		input.swipe_detected.connect(acao_rolar)

# --- MÁQUINA DE ESTADOS ---
func change_state(new_state):
	current_state = new_state
	
	match current_state:
		State.MENU:
			_entrar_menu()
			
		State.SETUP:
			_entrar_setup()
			
		State.PLAYING_P1:
			_entrar_playing(1)
			
		State.PLAYING_P2:
			_entrar_playing(2)
			
		State.GAMEOVER:
			_entrar_gameover()

# --- FUNÇÕES DE ENTRADA DE ESTADO ---

func _entrar_menu():
	limpar_mesa()
	limpar_bandejas()
	
	# ✅ DESATIVA O DICEMANAGER (Autoload)
	if DiceManager:
		DiceManager.deactivate()
	
	_atualizar_visibilidade_ui(ui_menu)
	
	# IMPORTANTE: Esconde settings quando volta pro menu
	if ui_settings:
		ui_settings.visible = false
	
	if $placafinal:
		$placafinal.visible = true

func _entrar_setup():
	_atualizar_visibilidade_ui(ui_setup)
	
	if ui_settings:
		ui_settings.visible = false
	
	if $placafinal:
		$placafinal.visible = false

func _entrar_playing(player_num: int):
	_atualizar_visibilidade_ui(ui_hud)
	
	if ui_settings:
		ui_settings.visible = false
	
	if $placafinal:
		$placafinal.visible = false

	if DiceManager:
		DiceManager.activate()
	_iniciar_turno(player_num)

func _entrar_gameover():
	if ui_settings:
		ui_settings.visible = false
	
	_lidar_com_gameover()

func _atualizar_visibilidade_ui(ui_ativa):
	if ui_menu: ui_menu.visible = (ui_menu == ui_ativa)
	if ui_setup: ui_setup.visible = (ui_setup == ui_ativa)
	if ui_hud: ui_hud.visible = (ui_hud == ui_ativa)
	if ui_gameover: ui_gameover.visible = (ui_gameover == ui_ativa)
	# Settings é controlado manualmente no _entrar_*

# --- CONTROLE DE PAUSE ---


func forcar_retorno_menu():
	# PASSO 2: Esconde settings
	if ui_settings:
		ui_settings.visible = false
	
	# PASSO 3: Reseta variáveis de jogo
	score_p1 = 0
	score_p2 = 0
	round_score = 0
	rolling_count = 0
	locked_dice_count = 0
	
	# PASSO 4: Limpa a mesa
	limpar_mesa()
	limpar_bandejas()
	
	# ✅ PASSO 5: Desativa DiceManager
	if DiceManager:
		DiceManager.deactivate()
	change_state(State.MENU)

# --- INPUT ---

func _on_btn_options_pressed() -> void:
	ui_settings.show()
# --- MENU BUTTONS ---

func _on_btn_1v_1_pressed() -> void:
	is_vs_ai = false
	change_state(State.SETUP)
	if ui_setup and ui_setup.has_method("configurar_modo"):
		ui_setup.configurar_modo(false)

func _on_btn_1v_ia_pressed() -> void:
	is_vs_ai = true
	change_state(State.SETUP)
	_sincronizar_ui_p2()
	if ui_setup and ui_setup.has_method("configurar_modo"):
		ui_setup.configurar_modo(true)

func _sincronizar_ui_p2():
	if ui_hud and ui_hud.has_method("atualizar_orientacao_ui"):
		ui_hud.atualizar_orientacao_ui()

# --- INICIAR JOGO ---

func iniciar_jogo(points: int, difficulty: int = 1):
	if $placafinal:
		$placafinal.hide()
	
	target_score = points
	ai_difficulty = clamp(difficulty, 0, 2)
	
	print("=== INICIANDO JOGO ===")
	print("Meta:", target_score)
	
	if is_vs_ai:
		_configurar_dificuldade_ia()
	
	score_p1 = 0
	score_p2 = 0
	
	if ui_setup:
		ui_setup.visible = false
	
	change_state(State.PLAYING_P1)

func _configurar_dificuldade_ia():
	if not ai_player: return
	if "Dificuldade" in ai_player:
		match ai_difficulty:
			0: ai_player.dificuldade_atual = ai_player.Dificuldade.FACIL
			1: ai_player.dificuldade_atual = ai_player.Dificuldade.MEDIO
			2: ai_player.dificuldade_atual = ai_player.Dificuldade.DIFICIL
	else:
		ai_player.dificuldade_atual = ai_difficulty

func cancelar_selecao():
	change_state(State.MENU)

# --- TURNO ---

func _iniciar_turno(player_num):
	print("Iniciando turno Jogador", player_num)
	if light_manager and light_manager.has_method("trocar_turno"):
		light_manager.trocar_turno(player_num)
	
	indices_disponiveis = [0, 1, 2, 3, 4, 5]
	round_score = 0
	limpar_bandejas()
	locked_dice_count = 0
	limpar_mesa()
	
	if current_state == State.PLAYING_P2 and is_vs_ai:
		acao_rolar()

func spawn_dice(quantidade: int):
	rolling_count = quantidade
	$AudioStreamPlayer.play()
	await get_tree().create_timer(0.5).timeout
	
	if current_state == State.MENU:
		return
	
	var origem = Vector3.ZERO
	if spawn_point:
		origem = spawn_point.global_position
	
	if current_state == State.PLAYING_P2 and spawn_point_p2:
		origem = spawn_point_p2.global_position
	
	for i in range(quantidade):
		if i >= indices_disponiveis.size():
			break
		var indice_real = indices_disponiveis[i]
		var dado = dice_scene.instantiate()
		if "original_index" in dado:
			dado.original_index = indice_real
		var material_skin = GameData.get_material_for_die(indice_real)
		if material_skin:
			dado.apply_skin(material_skin)
		add_child(dado)
		dado.global_position = origem + Vector3(randf()-0.5, randf()-0.5, randf()-0.5) * 0.5
		
		if "manager" in dado: dado.manager = self
		
		if dado.has_signal("roll_finished"):
			dado.roll_finished.connect(_on_dado_parou)
		
		active_dice.append(dado)
		
		# ... restante do código de física ...
		if dado is RigidBody3D:
			dado.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
			var direcao = (Vector3.ZERO - dado.global_position).normalized()
			direcao.x += randf_range(-0.2, 0.2)
			direcao.z += randf_range(-0.2, 0.2)
			direcao = direcao.normalized()
			
			var forca_arremesso = 30.0
			var forca_subida = 15.0
			var forca_giro = 50.0
			
			dado.apply_impulse(direcao * forca_arremesso + Vector3.UP * forca_subida)
			dado.apply_torque_impulse(Vector3(randf(), randf(), randf()).normalized() * forca_giro)

func _on_dado_parou(_dado_ref = null):
	rolling_count -= 1
	if rolling_count <= 0:
		_todos_dados_pararam()

func _todos_dados_pararam():
	rolling_count = 0
	var valores = []
	
	for d in active_dice:
		if is_instance_valid(d) and not d.is_locked():
			valores.append(d.final_value)
	
	if valores.is_empty():
		return
	
	if FarkleRules.is_farkle(valores):
		if ui_hud and ui_hud.has_method("exibir_farkle_aviso"):
			ui_hud.exibir_farkle_aviso()
		
		await get_tree().create_timer(2.0).timeout
		
		while current_state == State.PAUSED:
			await get_tree().create_timer(0.1).timeout
		
		if current_state == State.MENU:
			return
		
		_passar_a_vez(0)
		return
	
	if current_state == State.PLAYING_P2 and is_vs_ai and ai_player:
		ai_player.iniciar_decisao(self)

# --- AÇÕES ---

func acao_rolar():
	if current_state != State.PLAYING_P1 and current_state != State.PLAYING_P2:
		return
	if rolling_count > 0:
		return
	if dice_scene == null:
		return
	
	if active_dice.is_empty():
		spawn_dice(6)
		return
	
	var selected_dice = _get_selected_dice()
	var score_selecionado = _calcular_pontos_selecionados(selected_dice)
	
	if score_selecionado == 0:
		print("BLOQUEADO: Selecione dados para pontuar!")
		return
	
	round_score += score_selecionado
	_bloquear_dados(selected_dice)
	limpar_mesa()
	
	var dados_restantes = 6 - locked_dice_count
	if dados_restantes == 0:
		print("HOT DICE!")
		limpar_bandejas()
		dados_restantes = 6
		limpar_decorativos()
		
		# --- ADICIONE ISTO ---
		# Se deu Hot Dice, todos os dados voltam pro jogo
		indices_disponiveis = [0, 1, 2, 3, 4, 5]
	
	spawn_dice(dados_restantes)

func acao_parar():
	if current_state != State.PLAYING_P1 and current_state != State.PLAYING_P2:
		return
	if rolling_count > 0:
		return
	
	var selected_dice = _get_selected_dice()
	var score_selecionado = _calcular_pontos_selecionados(selected_dice)
	
	if score_selecionado == 0 and round_score == 0:
		return
	
	var total_final = round_score + score_selecionado
	_passar_a_vez(total_final)

func _passar_a_vez(pontos_ganhos):
	if current_state == State.PLAYING_P1:
		score_p1 += pontos_ganhos
		if score_p1 >= target_score:
			change_state(State.GAMEOVER)
			return
		change_state(State.PLAYING_P2)
	
	elif current_state == State.PLAYING_P2:
		score_p2 += pontos_ganhos
		if score_p2 >= target_score:
			change_state(State.GAMEOVER)
			return
		change_state(State.PLAYING_P1)

# --- GAMEOVER ---

func _lidar_com_gameover():
	# ✅ Desativa DiceManager antes das animações
	if DiceManager:
		DiceManager.deactivate()
	
	if score_p2 >= target_score:
		ui_gameover.rotation_degrees = 180
	else:
		ui_gameover.rotation_degrees = 0
	
	ui_gameover.pivot_offset = ui_gameover.size / 2
	ui_gameover.visible = true
	ui_gameover.modulate.a = 0
	ui_gameover.show()
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(ui_gameover, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
	
	for child in ui_gameover.get_children():
		if child is Label:
			child.pivot_offset = child.size / 2
			var jump = create_tween()
			jump.tween_property(child, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK)
			jump.tween_property(child, "scale", Vector2(1.0, 1.0), 0.2)
	
	await get_tree().create_timer(3.0).timeout
	
	var fade_out = create_tween()
	await fade_out.tween_property(ui_gameover, "modulate:a", 0.0, 0.5).finished
	
	ui_gameover.hide()
	ui_gameover.rotation_degrees = 0
	get_tree().reload_current_scene()

# --- HELPERS ---

func _get_selected_dice() -> Array:
	var list = []
	for d in active_dice:
		if is_instance_valid(d) and "is_selected" in d and d.is_selected:
			list.append(d)
	return list

func _calcular_pontos_selecionados(dice_list) -> int:
	var valores = []
	for d in dice_list:
		valores.append(d.final_value)
	return FarkleRules.calculate_score(valores)

func _bloquear_dados(dice_list):
	var bandeja = tray_p1 if current_state == State.PLAYING_P1 else tray_p2
	
	var espacamento_horizontal = 4.0
	var espacamento_vertical = 4.0
	var dados_por_fileira = 3
	
	for d in dice_list:
		d.is_selected = false
		d.is_banked = true
		d.outline_mesh.hide()
		d.process_mode = Node.PROCESS_MODE_DISABLED
		active_dice.erase(d)
		if "original_index" in d:
			indices_disponiveis.erase(d.original_index)
		
		var col = locked_dice_count % dados_por_fileira
		var row = floor(locked_dice_count / dados_por_fileira)
		
		locked_dice_count += 1
		
		if bandeja:
			var offset_local = (bandeja.global_basis.x * col * espacamento_horizontal) + \
							   (bandeja.global_basis.z * row * espacamento_vertical)
			
			var dest = bandeja.global_position + offset_local
			var tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
			tween.tween_property(d, "global_position", dest, 0.5)

func limpar_bandejas():
	for child in get_children():
		if child.has_method("is_locked") and child.is_banked:
			child.queue_free()
	locked_dice_count = 0

func limpar_mesa():
	for d in active_dice:
		if is_instance_valid(d):
			d.queue_free()
	active_dice.clear()

func limpar_decorativos():
	pass

func pode_interagir_humano() -> bool:
	if current_state == State.PLAYING_P1:
		return true
	if current_state == State.PLAYING_P2 and not is_vs_ai:
		return true
	return false

func _on_btn_tuto_pressed() -> void:
	if has_node("TutorialPanel"):
		$TutorialPanel.show_tutorial()


func _on_button_pressed() -> void:
	$DiceSkins.show()
