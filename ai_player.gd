extends Node

class_name AIBase

var manager
var boss_name: String = "IA"
var boss_color: Color = Color.WHITE
@export var audiolines: AudioStreamPlayer

enum Dificuldade { FACIL, MEDIO, DIFICIL }
@export var dificuldade_atual: Dificuldade = Dificuldade.MEDIO

# 🆕 Função de inicialização (IA padrão)
func inicializar_boss():
	boss_name = "IA"
	boss_color = Color.WHITE

	
# --- FUNÇÃO PRINCIPAL (O CÉREBRO) ---
func iniciar_decisao(_manager_ref):
	manager = _manager_ref
	
	# Hook 1: Tempo de pensar
	await get_tree().create_timer(_get_delay_pensamento()).timeout
	
	# Coleta dados
	var dados_disponiveis = []
	var valores_mesa = []
	for d in manager.active_dice:
		if is_instance_valid(d) and not d.is_locked():
			dados_disponiveis.append(d)
			valores_mesa.append(d.final_value)
	
	if dados_disponiveis.is_empty(): return

	# Hook 2: Reação ao Farkle (Permite ao Bêbado dar rage quit)
	if FarkleRules.is_farkle(valores_mesa):
		_handle_farkle_event()
		return
	
	# Hook 3: Estratégia de Seleção (A Inteligência volta aqui)
	var dados_escolhidos = _escolher_dados_estrategia(dados_disponiveis, valores_mesa)
	
	# Fallback de segurança 
	if dados_escolhidos.is_empty():
		dados_escolhidos = _tentar_recuperacao_de_emergencia(dados_disponiveis)

	# --- ANIMAÇÃO VISUAL ---
	for d in dados_escolhidos:
		if is_instance_valid(d) and not d.is_selected:
			d.toggle_selection()
			await get_tree().create_timer(0.2).timeout
	
	# Correção de integridade visual
	_garantir_selecao_visual(dados_escolhidos)
	
	# --- CÁLCULOS E DECISÃO ---
	await get_tree().create_timer(0.5).timeout
	
	var valores_finais = []
	for d in dados_escolhidos: if is_instance_valid(d): valores_finais.append(d.final_value)
	var score_da_selecao = FarkleRules.calculate_score(valores_finais)

	# Proteção contra seleção inválida (0 pontos)
	if score_da_selecao == 0:
		_corrigir_selecao_zero(dados_disponiveis, dados_escolhidos)
		return 

	var total_se_parar = manager.score_p2 + manager.round_score + score_da_selecao
	var pontos_na_mesa = manager.round_score + score_da_selecao
	var dados_restantes = dados_disponiveis.size() - dados_escolhidos.size()
	
	# Hook 4: Decisão de Risco (A Cura da Viciada volta aqui)
	var deve_rolar = _decidir_risco(dados_restantes, pontos_na_mesa, score_da_selecao, total_se_parar)
	
	# Lógica do "Rapa do Tacho" (Se vai parar, pega as sobras válidas)
	if not deve_rolar:
		_executar_rapa_do_tacho(dados_disponiveis, dados_escolhidos)

	# Execução
	if deve_rolar:
		manager.acao_rolar()
	else:
		manager.acao_parar()

# ==============================================================================
# MÉTODOS VIRTUAIS (Feitos para serem sobrescritos, MAS COM LÓGICA PADRÃO FORTE)
# ==============================================================================

func _get_delay_pensamento() -> float:
	return randf_range(0.8, 1.5)

func _handle_farkle_event():
	# Padrão: Aceita e passa a vez
	if manager.has_method("finalizar_turno_farkle"):
		manager.finalizar_turno_farkle()
	else:
		manager.acao_parar()

func _escolher_dados_estrategia(dados_objs, valores) -> Array:
	match dificuldade_atual:
		Dificuldade.FACIL: 
			if randf() < 0.3: return _escolher_dados_basico(dados_objs, valores)
			return _escolher_dados_otimizado(dados_objs, valores)
		Dificuldade.MEDIO: 
			return _escolher_dados_otimizado(dados_objs, valores)
		Dificuldade.DIFICIL: 
			return _escolher_dados_dificil(dados_objs, valores)
	return []

# A Lógica "Cura da Viciada" original
func _decidir_risco(dados_restantes, pontos_mesa, _score_sel, total_geral) -> bool:
	if total_geral >= manager.target_score: return false # Ganhou
	if dados_restantes == 0: return true # Hot Dice
	
	# ANÁLISE DE PLACAR
	var diferenca = manager.score_p2 - manager.score_p1
	var meta_pontos_turno = 350
	var arriscar_com_2_dados = false
	var arriscar_com_1_dado = false
	
	if diferenca > 1500: meta_pontos_turno = 250 # Ganhando muito, joga seguro
	elif diferenca < -1500: # Perdendo feio
		meta_pontos_turno = 800
		arriscar_com_2_dados = true
		if diferenca < -3000: arriscar_com_1_dado = true

	# PROBABILIDADE
	match dados_restantes:
		5: return pontos_mesa < (meta_pontos_turno * 3)
		4: return pontos_mesa < (meta_pontos_turno * 2)
		3: 
			if pontos_mesa >= meta_pontos_turno: return false
			return true
		2:
			if arriscar_com_2_dados: return true
			if pontos_mesa < 150: return true
			return false
		1:
			return arriscar_com_1_dado
	return false

# ==============================================================================
# INTELIGÊNCIA DE SELEÇÃO (O CÉREBRO RESTAURADO)
# ==============================================================================

func _escolher_dados_otimizado(dados_objs: Array, valores: Array) -> Array:
	var selecao = []
	var counts = {}
	for v in valores: counts[v] = counts.get(v, 0) + 1
	var dados_pool = dados_objs.duplicate()
	
	# 1. SEQUÊNCIA REAL (1-6)
	if counts.size() == 6: return dados_objs.duplicate()
	
	# 2. SEQUÊNCIA BAIXA (1-5)
	if counts.get(1,0)>=1 and counts.get(2,0)>=1 and counts.get(3,0)>=1 and counts.get(4,0)>=1 and counts.get(5,0)>=1:
		var temp_pool = dados_pool.duplicate()
		var temp_sel = []
		var sucesso = true
		for v in range(1, 6):
			if not _mover_dado_para_selecao(v, temp_pool, temp_sel):
				sucesso = false; break
		if sucesso:
			dados_pool = temp_pool
			selecao.append_array(temp_sel)
			_pegar_sobras_validas(dados_pool, selecao)
			return selecao

	# 3. SEQUÊNCIA ALTA (2-6)
	if counts.get(2,0)>=1 and counts.get(3,0)>=1 and counts.get(4,0)>=1 and counts.get(5,0)>=1 and counts.get(6,0)>=1:
		var temp_pool = dados_pool.duplicate()
		var temp_sel = []
		var sucesso = true
		for v in range(2, 7):
			if not _mover_dado_para_selecao(v, temp_pool, temp_sel):
				sucesso = false; break
		if sucesso:
			dados_pool = temp_pool
			selecao.append_array(temp_sel)
			_pegar_sobras_validas(dados_pool, selecao)
			return selecao

	# 4. TRINCAS E MULTIPLICADORES
	var prioridade_trincas = [1, 6, 5, 4, 3, 2]
	for val in prioridade_trincas:
		if counts.get(val, 0) >= 3:
			for _i in range(3): _mover_dado_para_selecao(val, dados_pool, selecao)
			# Pega 4º, 5º, 6º iguais se houver
			while counts.get(val, 0) > 3:
				if not _mover_dado_para_selecao(val, dados_pool, selecao): break

	# 5. SOBRAS (1s e 5s)
	_pegar_sobras_validas(dados_pool, selecao)
	return selecao

func _escolher_dados_dificil(dados_objs: Array, valores: Array) -> Array:
	var selecao_base = _escolher_dados_otimizado(dados_objs, valores)
	if selecao_base.size() == dados_objs.size(): return selecao_base # Hot dice
		
	# ECONOMIA INTELIGENTE
	var dados_restantes = dados_objs.size() - selecao_base.size()
	if dados_restantes < 5 and dados_restantes > 0:
		var contagem_selecao = {}
		for d in selecao_base: contagem_selecao[d.final_value] = contagem_selecao.get(d.final_value, 0) + 1
			
		# Solta um 5 se não for trinca
		if contagem_selecao.get(5, 0) > 0 and contagem_selecao[5] < 3:
			for i in range(selecao_base.size()):
				if selecao_base[i].final_value == 5:
					selecao_base.remove_at(i)
					return selecao_base
		
		# Solta um 1 se isso garantir 5 dados na mesa (pra tentar pontuar alto no proximo roll)
		if contagem_selecao.get(1, 0) > 0 and contagem_selecao[1] < 3:
			if (dados_restantes + 1) == 5:
				for i in range(selecao_base.size()):
					if selecao_base[i].final_value == 1:
						selecao_base.remove_at(i)
						return selecao_base
	return selecao_base

func _escolher_dados_basico(dados_objs: Array, valores: Array) -> Array:
	var selecao = []
	var counts = {}
	for v in valores: counts[v] = counts.get(v, 0) + 1
	
	for val in counts:
		if counts[val] >= 3:
			var pegos = 0
			for d in dados_objs:
				if d.final_value == val and pegos < 3:
					selecao.append(d); pegos += 1
	for d in dados_objs:
		if d not in selecao and (d.final_value == 1 or d.final_value == 5): selecao.append(d)
	return selecao

# ==============================================================================
# HELPERS TÉCNICOS
# ==============================================================================

func _mover_dado_para_selecao(valor: int, pool: Array, selecao: Array) -> bool:
	for i in range(pool.size()):
		if pool[i].final_value == valor:
			selecao.append(pool[i])
			pool.remove_at(i)
			return true
	return false

func _pegar_sobras_validas(pool: Array, selecao: Array):
	var para_remover = []
	for d in pool:
		if d.final_value == 1 or d.final_value == 5:
			selecao.append(d)
			para_remover.append(d)
	for d in para_remover: pool.erase(d)

func _tentar_recuperacao_de_emergencia(pool):
	for d in pool: 
		if is_instance_valid(d) and (d.final_value == 1 or d.final_value == 5): return [d]
	return []

func _garantir_selecao_visual(escolhidos):
	for d in escolhidos:
		if is_instance_valid(d) and not d.is_selected: d.is_selected = true

func _corrigir_selecao_zero(pool, errados):
	_resetar_selecao_invalida(errados)
	var seguro = _tentar_recuperacao_de_emergencia(pool)
	if not seguro.is_empty():
		seguro[0].is_selected = true
		manager.acao_rolar()

func _executar_rapa_do_tacho(pool, escolhidos):
	for d in pool:
		if is_instance_valid(d) and d not in escolhidos:
			if d.final_value == 1 or d.final_value == 5:
				escolhidos.append(d)
				if not d.is_selected: d.toggle_selection()

func _resetar_selecao_invalida(dados):
	for d in dados:
		if is_instance_valid(d): 
			d.is_selected = false
			if "outline_mesh" in d and d.outline_mesh: d.outline_mesh.hide()
