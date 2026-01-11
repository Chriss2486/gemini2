extends Node

# --- SINAIS ---
signal dice_rolled(results: Array)
signal score_updated(current_turn_score: int, potential_score: int)
signal farkle_triggered
signal hot_dice_triggered
signal turn_ended(final_score: int)

# --- CONFIGURAÇÕES ---
const TOTAL_DICE = 6

# --- ESTADOS ---
enum DieState { 
	ACTIVE,   # Na mesa, vai ser rolado
	SELECTED, # Jogador clicou (mas não confirmou)
	BANKED    # Já pontuado (não rola mais)
}

var dice_data: Array = []
var current_turn_score: int = 0
var turn_history: Array = []
var dice_nodes_3d: Array = []

# ⚠️ IMPORTANTE: Flag para saber se o manager está "ativo"
var is_active: bool = false

func _ready():
	# Autoloads sempre rodam o _ready, mesmo quando a cena muda
	reset_manager()

# ============================================================
# RESET COMPLETO - CHAME ISSO QUANDO TROCAR DE CENA/ESTADO
# ============================================================
func reset_manager():
	_disconnect_all_signals()
	_initialize_dice()
	current_turn_score = 0
	turn_history.clear()
	dice_nodes_3d.clear()
	is_active = false

func _disconnect_all_signals():
	for sig in ["dice_rolled", "score_updated", "farkle_triggered", "hot_dice_triggered", "turn_ended"]:
		var connections = get_signal_connection_list(sig)
		for conn in connections:
			if conn.callable.is_valid():
				disconnect(sig, conn.callable)

func _initialize_dice():
	dice_data.clear()
	for i in range(TOTAL_DICE):
		dice_data.append({
			"id": i,
			"value": 1,
			"state": DieState.ACTIVE
		})

# ============================================================
# ATIVAR/DESATIVAR O MANAGER (Chamado pelo GameManager)
# ============================================================
func activate():
	reset_manager()
	is_active = true

func deactivate():
	is_active = false

# ============================================================
# AÇÕES PRINCIPAIS
# ============================================================

func roll_dice():
	if not is_active:
		return
	
	if not _validate_selection_before_roll():
		return
	
	_commit_selected_dice()
	_check_hot_dice()
	
	var dice_to_roll = []
	var values_result = []
	
	for die in dice_data:
		if die["state"] == DieState.ACTIVE:
			die["value"] = randi_range(1, 6)
			dice_to_roll.append(die)
			values_result.append(die["value"])
			
	emit_signal("dice_rolled", values_result)
	
	if FarkleRules.is_farkle(values_result):
		current_turn_score = 0
		_reset_turn_visuals()
		emit_signal("farkle_triggered")
	else:
		_update_score_signals()

func toggle_die_selection(index: int):
	if not is_active:
		return
	
	if index < 0 or index >= TOTAL_DICE:
		return
	
	var die = dice_data[index]
	
	if die["state"] == DieState.BANKED:
		return
	
	if die["state"] == DieState.ACTIVE:
		die["state"] = DieState.SELECTED
	else:
		die["state"] = DieState.ACTIVE
	
	_update_score_signals()

func bank_and_end_turn():
	if not is_active:
		return
	
	if not _validate_selection_before_roll():
		return
	
	_commit_selected_dice()
	
	emit_signal("turn_ended", current_turn_score)
	
	_reset_game_state()

# ============================================================
# LÓGICA INTERNA
# ============================================================

func _get_current_selection_points() -> int:
	var selected_values = []
	for die in dice_data:
		if die["state"] == DieState.SELECTED:
			selected_values.append(die["value"])
	
	return FarkleRules.calculate_score(selected_values)

func _commit_selected_dice():
	var points = _get_current_selection_points()
	if points > 0:
		current_turn_score += points
		
		for die in dice_data:
			if die["state"] == DieState.SELECTED:
				die["state"] = DieState.BANKED

func _validate_selection_before_roll() -> bool:
	var active_count = 0
	var selected_count = 0
	var banked_count = 0
	
	for die in dice_data:
		match die["state"]:
			DieState.ACTIVE: active_count += 1
			DieState.SELECTED: selected_count += 1
			DieState.BANKED: banked_count += 1
	
	# Primeira rolagem (tudo active, nada banked/selected)
	if banked_count == 0 and selected_count == 0:
		return true
	
	# Rolagens subsequentes: precisa ter selecionado algo válido
	if selected_count > 0:
		var potential = _get_current_selection_points()
		return potential > 0
	
	return false

func _check_hot_dice():
	var all_banked = true
	for die in dice_data:
		if die["state"] != DieState.BANKED:
			all_banked = false
			break
	
	if all_banked:
		print("HOT DICE! Todos os 6 dados pontuaram. Rola tudo de novo!")
		emit_signal("hot_dice_triggered")
		for die in dice_data:
			die["state"] = DieState.ACTIVE

func _reset_game_state():
	current_turn_score = 0
	for die in dice_data:
		die["state"] = DieState.ACTIVE
		die["value"] = 1
	_update_score_signals()

func _reset_turn_visuals():
	_reset_game_state()

func _update_score_signals():
	if not is_active:
		return
	
	var selection_points = _get_current_selection_points()
	emit_signal("score_updated", current_turn_score, selection_points)

# ============================================================
# INTEGRAÇÃO 3D
# ============================================================

func register_die_node(node: Node3D, id: int):
	while dice_nodes_3d.size() <= id:
		dice_nodes_3d.append(null)
	dice_nodes_3d[id] = node

func unregister_die_node(id: int):
	if id >= 0 and id < dice_nodes_3d.size():
		dice_nodes_3d[id] = null

func unregister_all_dice_nodes():
	dice_nodes_3d.clear()
