extends Node

@onready var manager = $".."

# Níveis de dificuldade
enum Dificuldade { FACIL, MEDIO, DIFICIL }
@export var dificuldade_atual: Dificuldade = Dificuldade.MEDIO

func iniciar_decisao(_manager_ref):
	manager = _manager_ref
	
	# Delay varia com dificuldade
	var delay_pensamento = _get_delay_pensamento()
	await get_tree().create_timer(delay_pensamento).timeout
	
	# --- 1. COLETAR DADOS DISPONÍVEIS ---
	var dados_disponiveis = []
	var valores_mesa = []
	
	for d in manager.active_dice:
		if is_instance_valid(d) and not d.is_locked():
			dados_disponiveis.append(d)
			valores_mesa.append(d.final_value)
	
	# Verifica Farkle ANTES de tentar selecionar
	if FarkleRules.is_farkle(valores_mesa):
		print("IA detectou Farkle (nenhum dado pontuável).")
		if manager.has_method("finalizar_turno_farkle"):
			manager.finalizar_turno_farkle()
		else:
			manager.acao_parar()
		return
	
	# --- 2. SELECIONAR DADOS ---
	var dados_escolhidos = _escolher_dados_por_dificuldade(dados_disponiveis, valores_mesa)
	
	if dados_escolhidos.is_empty():
		print("IA não conseguiu selecionar dados válidos.")
		manager.acao_parar()
		return
	
	# Simula os cliques nos dados
	for d in dados_escolhidos:
		if is_instance_valid(d):
			d.toggle_selection()
			await get_tree().create_timer(0.4).timeout
		else:
			return
	
	# --- 3. CALCULAR PONTUAÇÃO DA SELEÇÃO ---
	await get_tree().create_timer(0.6).timeout
	
	var valores_selecionados = []
	for d in dados_escolhidos:
		if is_instance_valid(d):
			valores_selecionados.append(d.final_value)
		else:
			print("Erro: Um dado foi removido antes do cálculo final.")
			return
	
	# Usa FarkleRules para calcular score
	var score_da_selecao = FarkleRules.calculate_score(valores_selecionados)
	var total_potencial = manager.round_score + score_da_selecao
	var dados_restantes_na_mao = dados_disponiveis.size() - dados_escolhidos.size()
	
	# --- 4. DECIDIR SE PARA OU ROLA ---
	var deve_rolar = _decidir_rolar_por_dificuldade(
		dados_restantes_na_mao, 
		total_potencial, 
		score_da_selecao,
		valores_mesa
	)
	
	# --- 5. EXECUTAR AÇÃO ---
	if deve_rolar:
		print("IA [%s] decidiu rolar novamente com %d dados (Score atual: %d)." % [
			Dificuldade.keys()[dificuldade_atual], 
			dados_restantes_na_mao,
			total_potencial
		])
		manager.acao_rolar()
	else:
		print("IA [%s] decidiu parar e bancar %d pontos." % [
			Dificuldade.keys()[dificuldade_atual], 
			total_potencial
		])
		manager.acao_parar()

# ===== FUNÇÕES DE DIFICULDADE =====

func _get_delay_pensamento() -> float:
	match dificuldade_atual:
		Dificuldade.FACIL:
			return randf_range(0.5, 0.8)
		Dificuldade.MEDIO:
			return randf_range(1.0, 1.5)
		Dificuldade.DIFICIL:
			return randf_range(1.5, 2.0)
	return 1.2

func _escolher_dados_por_dificuldade(dados_objs: Array, valores: Array) -> Array:
	match dificuldade_atual:
		Dificuldade.FACIL:
			return _escolher_dados_facil(dados_objs, valores)
		Dificuldade.MEDIO:
			return _escolher_dados_medio(dados_objs, valores)
		Dificuldade.DIFICIL:
			return _escolher_dados_dificil(dados_objs, valores)
	return []

func _decidir_rolar_por_dificuldade(dados_restantes: int, total_potencial: int, score_selecao: int, valores_mesa: Array) -> bool:
	match dificuldade_atual:
		Dificuldade.FACIL:
			return _decidir_rolar_facil(dados_restantes, total_potencial)
		Dificuldade.MEDIO:
			return _decidir_rolar_medio(dados_restantes, total_potencial, score_selecao)
		Dificuldade.DIFICIL:
			return _decidir_rolar_dificil(dados_restantes, total_potencial, score_selecao, valores_mesa)
	return false

# ===== FÁCIL: Conservadora e comete erros =====

func _escolher_dados_facil(dados_objs: Array, valores: Array) -> Array:
	var selecao = []
	
	# 40% de chance de escolher de forma subótima
	if randf() < 0.4:
		# Pega apenas alguns 1s e 5s, ignora trincas às vezes
		for d in dados_objs:
			if is_instance_valid(d) and (d.final_value == 1 or d.final_value == 5):
				if randf() < 0.6:  # Nem sempre pega todos
					selecao.append(d)
		
		# Se pegou algo, retorna, senão usa estratégia normal
		if not selecao.is_empty():
			return selecao
	
	# Comportamento normal mas não otimizado
	return _escolher_dados_basico(dados_objs, valores)

func _decidir_rolar_facil(dados_restantes: int, total_potencial: int) -> bool:
	# IA fácil para muito cedo
	if dados_restantes == 0:
		return true  # Hot dice
	elif total_potencial >= 250:  # Para cedo demais!
		return false
	elif dados_restantes == 1:
		return false  # Muito medrosa
	elif dados_restantes == 2:
		return randf() < 0.25  # Raramente arrisca com 2
	else:
		return randf() < 0.65  # Às vezes para mesmo com 3+

# ===== MÉDIO: Balanceada =====

func _escolher_dados_medio(dados_objs: Array, valores: Array) -> Array:
	return _escolher_dados_otimizado(dados_objs, valores)

func _decidir_rolar_medio(dados_restantes: int, total_potencial: int, score_selecao: int) -> bool:
	if dados_restantes == 0:
		return true  # Hot dice sempre
	elif dados_restantes >= 4:
		return true  # Seguro com 4+
	elif dados_restantes >= 3:
		return total_potencial < 500  # Arrisca se tem pouco
	elif dados_restantes == 2:
		return total_potencial < 300  # Conservadora com 2
	else:
		return total_potencial < 200  # Muito conservadora com 1

# ===== DIFÍCIL: Agressiva e inteligente =====

func _escolher_dados_dificil(dados_objs: Array, valores: Array) -> Array:
	# Avalia TODAS as combinações possíveis e escolhe a melhor
	var melhor_selecao = []
	var melhor_score = 0
	var melhor_eficiencia = 0.0
	
	# Testa diferentes estratégias
	var estrategias = [
		_escolher_dados_otimizado(dados_objs, valores),
		_escolher_apenas_trincas(dados_objs, valores),
		_escolher_tudo_valido(dados_objs, valores)
	]
	
	for estrategia in estrategias:
		if estrategia.is_empty():
			continue
			
		var valores_sel = []
		for d in estrategia:
			if is_instance_valid(d):
				valores_sel.append(d.final_value)
		
		var score = FarkleRules.calculate_score(valores_sel)
		var dados_usados = estrategia.size()
		var eficiencia = float(score) / float(dados_usados) if dados_usados > 0 else 0
		
		# Prioriza alta eficiência (mais pontos por dado)
		if eficiencia > melhor_eficiencia or (eficiencia == melhor_eficiencia and score > melhor_score):
			melhor_selecao = estrategia
			melhor_score = score
			melhor_eficiencia = eficiencia
	
	return melhor_selecao

func _decidir_rolar_dificil(dados_restantes: int, total_potencial: int, score_selecao: int, valores_mesa: Array) -> bool:
	# Hot dice sempre rola
	if dados_restantes == 0:
		return true
	
	# Calcula probabilidade real de Farkle
	var prob_farkle = _calcular_prob_farkle(dados_restantes)
	
	# Avalia o "valor esperado" da próxima jogada
	var valor_esperado = _calcular_valor_esperado(dados_restantes, prob_farkle)
	
	# Estratégia adaptativa baseada no score
	if total_potencial >= 700:
		# Conservadora quando tem muitos pontos
		return prob_farkle < 0.25
	elif total_potencial >= 500:
		# Balanceada
		return prob_farkle < 0.4 and dados_restantes >= 3
	elif total_potencial >= 300:
		# Mais agressiva
		return prob_farkle < 0.5 or dados_restantes >= 4
	else:
		# Muito agressiva quando tem poucos pontos
		return dados_restantes >= 2

# ===== FUNÇÕES DE SELEÇÃO DE DADOS =====

func _escolher_dados_basico(dados_objs: Array, valores: Array) -> Array:
	var selecao = []
	var counts = {}
	
	for v in valores:
		counts[v] = counts.get(v, 0) + 1
	
	# Pega trincas
	for val in counts:
		if counts[val] >= 3:
			var encontrados = 0
			for d in dados_objs:
				if is_instance_valid(d) and d.final_value == val and encontrados < 3:
					selecao.append(d)
					encontrados += 1
	
	# Pega 1s e 5s avulsos
	for d in dados_objs:
		if is_instance_valid(d) and not d in selecao:
			if d.final_value == 1 or d.final_value == 5:
				selecao.append(d)
	
	return selecao

func _escolher_dados_otimizado(dados_objs: Array, valores: Array) -> Array:
	var selecao = []
	var counts = {}
	
	for v in valores:
		counts[v] = counts.get(v, 0) + 1
	
	# 1. Detecta sequências completas (prioridade máxima)
	if _tem_sequencia_completa(counts):
		return dados_objs.duplicate()
	
	# 2. Pega todos os dados de trincas ou mais
	for val in counts:
		if counts[val] >= 3:
			for d in dados_objs:
				if is_instance_valid(d) and d.final_value == val:
					selecao.append(d)
	
	# 3. Pega 1s e 5s que sobraram
	for d in dados_objs:
		if is_instance_valid(d) and not d in selecao:
			if d.final_value == 1 or d.final_value == 5:
				selecao.append(d)
	
	return selecao

func _escolher_apenas_trincas(dados_objs: Array, valores: Array) -> Array:
	var selecao = []
	var counts = {}
	
	for v in valores:
		counts[v] = counts.get(v, 0) + 1
	
	# Pega apenas trincas (deixa 1s e 5s para próxima rodada)
	for val in counts:
		if counts[val] >= 3:
			var encontrados = 0
			for d in dados_objs:
				if is_instance_valid(d) and d.final_value == val and encontrados < counts[val]:
					selecao.append(d)
					encontrados += 1
	
	return selecao

func _escolher_tudo_valido(dados_objs: Array, valores: Array) -> Array:
	var selecao = []
	
	# Pega todos os dados que podem pontuar
	for d in dados_objs:
		if is_instance_valid(d):
			if FarkleRules.is_die_valid_candidate(d.final_value, valores):
				selecao.append(d)
	
	return selecao

# ===== FUNÇÕES AUXILIARES =====

func _tem_sequencia_completa(counts: Dictionary) -> bool:
	# 1-2-3-4-5-6
	if counts.get(1,0) >= 1 and counts.get(2,0) >= 1 and counts.get(3,0) >= 1 and \
	   counts.get(4,0) >= 1 and counts.get(5,0) >= 1 and counts.get(6,0) >= 1:
		return true
	return false

func _calcular_prob_farkle(num_dados: int) -> float:
	# Probabilidades calculadas para Farkle padrão
	match num_dados:
		1: return 0.667  # 66.7%
		2: return 0.444  # 44.4%
		3: return 0.278  # 27.8%
		4: return 0.162  # 16.2%
		5: return 0.077  # 7.7%
		6: return 0.023  # 2.3%
	return 0.5

func _calcular_valor_esperado(num_dados: int, prob_farkle: float) -> float:
	# Estima o valor médio que pode ganhar vs perder tudo
	var score_medio_esperado = num_dados * 30  # ~30 pontos por dado em média
	var valor_esperado = score_medio_esperado * (1.0 - prob_farkle)
	return valor_esperado
