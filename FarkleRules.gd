extends RefCounted
class_name FarkleRules

# --- FUNÇÃO DE SCORE (ESTRITA) ---
# Usada para mostrar pontos na UI. Se selecionar dado que não pontua, retorna 0.
static func calculate_score(dice_values: Array) -> int:
	if dice_values.is_empty():
		return 0
		
	var score = 0
	var counts = _get_counts(dice_values)
	var remaining_counts = counts.duplicate()

	# 1. SEQUÊNCIAS
	if counts[1] >= 1 and counts[2] >= 1 and counts[3] >= 1 and counts[4] >= 1 and counts[5] >= 1 and counts[6] >= 1:
		score = 1500
		_consume_counts(remaining_counts, [1,2,3,4,5,6])
		return _validate_and_return(score, remaining_counts)
	
	elif counts[2] >= 1 and counts[3] >= 1 and counts[4] >= 1 and counts[5] >= 1 and counts[6] >= 1:
		score += 750
		_consume_counts(remaining_counts, [2,3,4,5,6])

	elif counts[1] >= 1 and counts[2] >= 1 and counts[3] >= 1 and counts[4] >= 1 and counts[5] >= 1:
		score += 500
		_consume_counts(remaining_counts, [1,2,3,4,5])

	# 2. TRINCAS E MULTIPLICADORES (3, 4, 5 ou 6 dados)
	# Lógica: 3 dados (base), 4 dados (base*2), 5 dados (base*4), 6 dados (base*8)
	for num in range(1, 7):
		var qty = remaining_counts[num]
		if qty >= 3:
			var base_points = 1000 if num == 1 else num * 100
			var multiplier = pow(2, qty - 3)
			score += int(base_points * multiplier)
			remaining_counts[num] = 0

	# 3. DADOS AVULSOS (1 e 5)
	score += remaining_counts[1] * 100
	remaining_counts[1] = 0
	
	score += remaining_counts[5] * 50
	remaining_counts[5] = 0
	
	# Retorna o score ou 0 se houver "lixo" na seleção
	return _validate_and_return(score, remaining_counts)

# --- FUNÇÃO DE FARKLE (PERMISSIVA) ---
# Usada pelo Manager para saber se o jogador PERDEU a vez.
static func is_farkle(dice_values: Array) -> bool:
	if dice_values.is_empty(): return false
	
	var counts = _get_counts(dice_values)
	
	# 1. Qualquer 1 ou 5 salva do Farkle
	if counts[1] > 0 or counts[5] > 0:
		return false
		
	# 2. Qualquer trinca salva do Farkle
	for n in range(1, 7):
		if counts[n] >= 3:
			return false
			
	# 3. Qualquer sequência de 5 ou 6 dados salva do Farkle
	if counts[2] >= 1 and counts[3] >= 1 and counts[4] >= 1 and counts[5] >= 1:
		if counts[1] >= 1 or counts[6] >= 1:
			return false

	return true

# --- HELPERS ---

static func _validate_and_return(current_score: int, remaining: Dictionary) -> int:
	for val in remaining.values():
		if val > 0:
			return 0 # Seleção inválida: contém dados que não pontuam sozinhos
	return current_score

static func is_die_valid_candidate(die_value: int, all_dice_values: Array) -> bool:
	if die_value == 1 or die_value == 5: return true
	var counts = _get_counts(all_dice_values)
	if counts[die_value] >= 3: return true
	
	# Straights
	if counts[1]>=1 and counts[2]>=1 and counts[3]>=1 and counts[4]>=1 and counts[5]>=1:
		if counts[6]>=1 or die_value <= 5: return true
	if counts[2]>=1 and counts[3]>=1 and counts[4]>=1 and counts[5]>=1 and counts[6]>=1:
		if die_value >= 2: return true

	return false

static func _get_counts(dice_values: Array) -> Dictionary:
	var c = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0}
	for v in dice_values:
		if v >= 1 and v <= 6:
			c[v] += 1
	return c

static func _consume_counts(counts_dict: Dictionary, numbers_to_remove: Array):
	for n in numbers_to_remove:
		if counts_dict.has(n) and counts_dict[n] > 0:
			counts_dict[n] -= 1
