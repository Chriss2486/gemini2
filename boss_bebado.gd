extends AIBase

class_name BossBebado

# --- SISTEMA DE ÁUDIO ---
# Listas de sons (Carregadas via código no _ready)
var vozes_pensando: Array[AudioStream] = []
var vozes_raiva: Array[AudioStream] = []     # Socão / Rage
var vozes_tristeza: Array[AudioStream] = []  # Farkle dele
var vozes_vitoria: Array[AudioStream] = []   # Ganhou jogo
var vozes_provocacao: Array[AudioStream] = [] # Player deu Farkle
var vozes_derrota: Array[AudioStream] = []    # Perdeu jogo
var vozes_intro: Array[AudioStream] = []      # Começo
var vozes_vitoria_jogo: Array[AudioStream] = []

# --- ESTADOS ---
var ja_socou_mesa = false
var ja_atrapalhou_player = false

func _ready():
	boss_name = "Sylas"
	
	# 1. Configura Audio
	if not audiolines:
		audiolines = get_node_or_null("AudioStreamPlayer")
		if not audiolines:
			var novo_audio = AudioStreamPlayer.new()
			novo_audio.name = "AudioStreamPlayer"
			add_child(novo_audio)
			audiolines = novo_audio
			audiolines.volume_db = -10
			
	_carregar_sons_do_sylas()

func _carregar_sons_do_sylas():
	# --- PENSANDO / BÊBADO ---
	vozes_pensando = [
		load("res://audios/sylas/sounds/1.ogg"),
		load("res://audios/sylas/sounds/9.ogg"),
		load("res://audios/sylas/sounds/10.ogg"),
		load("res://audios/sylas/sounds/11.ogg"),
		
		
	]
	
	# --- RAIVA / SOCO ---
	vozes_raiva = [
		load("res://audios/sylas/sounds/3.ogg"),
		load("res://audios/sylas/sounds/5.ogg"),
		load("res://audios/sylas/sounds/8.ogg"),
	]
	
	# --- TRISTEZA / FARKLE ---
	vozes_tristeza = [
		load("res://audios/sylas/sounds/2.ogg"),
		load("res://audios/sylas/sounds/6.ogg"),
		load("res://audios/sylas/sounds/13.ogg"),
	]
	
	# --- VITÓRIA ---
	vozes_vitoria = [
		load("res://audios/sylas/sounds/4.ogg"),
		load("res://audios/sylas/sounds/7.ogg"),
		load("res://audios/sylas/sounds/12.ogg"),
	]
	
	vozes_provocacao = [
		load("res://audios/sylas/sylas_provoke1.mp3"),
		load("res://audios/sylas/sylas_provoke2.mp3")
	]
	
	vozes_derrota = [
		load("res://audios/sylas/sylas_lose1.mp3"),
		load("res://audios/sylas/sylas_lose2.mp3")
	]
	
	vozes_vitoria_jogo = [
		load("res://audios/sylas/sylas_win1.mp3"),
	]
	
	vozes_intro = [
		load("res://audios/sylas/sylas_beggining.mp3"),
	]
# ==============================================================================
# FUNÇÃO DE ÁUDIO
# ==============================================================================
func intro():
	print("COMECOOOOOU!")
	tocar_voz(vozes_intro, true)

func reagir_farkle_do_player():
	print("Bêbado: KKKKK Se ferrou!")
	tocar_voz(vozes_provocacao, true)

func reagir_vitoria_boss():
	print("Bêbado: GANHEI!")
	tocar_voz(vozes_vitoria_jogo, true)

func reagir_derrota_boss():
	print("Bêbado: PERDI?! LADRÃO!")
	tocar_voz(vozes_derrota, true)

func tocar_voz(lista_de_sons: Array[AudioStream], forcar: bool = false, velocidade: float = 1.0):
	print(">>> tocar_voz chamado!")
	
	if not audiolines: 
		print("❌ audiolines não existe!")
		return
	
	# Proteção se a lista estiver vazia (caso esqueça de colar algum caminho)
	if lista_de_sons.is_empty(): 
		print("❌ Lista de sons vazia!")
		return

	if audiolines.playing and not forcar: 
		print("⚠️ Áudio já está tocando e não é pra forçar")
		return

	var som_escolhido = lista_de_sons.pick_random()
	print("✅ Som escolhido: ", som_escolhido)
	audiolines.stream = som_escolhido
	
	audiolines.pitch_scale = randf_range(0.98, 1.05) * velocidade
	print("✅ Tocando com pitch_scale: ", audiolines.pitch_scale)
	audiolines.play()
	print("✅ Play() executado!")

# ==============================================================================
# LÓGICA DO BOSS
# ==============================================================================

# OVERRIDE 1: O Bêbado pensa devagar
func _get_delay_pensamento() -> float:
	# Só fala 30% das vezes quando está pensando
	if randf() < 0.3:
		tocar_voz(vozes_pensando)
	return randf_range(0.7, 1.0)

# ⚠️ CORREÇÃO: O nome da função tem que ser igual ao que o Manager chama
func verificar_interferencia_inteligente(dados_disponiveis: Array, valores: Array, round_score_atual: int) -> bool:
	if ja_atrapalhou_player: 
		return false
	
	# Calcula qual seria a MELHOR jogada do player
	var melhor_selecao = _escolher_dados_otimizado(dados_disponiveis, valores)
	var pontos_dessa_jogada = 0
	
	if not melhor_selecao.is_empty():
		var valores_selecao = []
		for d in melhor_selecao:
			valores_selecao.append(d.final_value)
		pontos_dessa_jogada = FarkleRules.calculate_score(valores_selecao)
	
	# Total que o player teria se pegasse os melhores dados
	var total_na_mesa = round_score_atual + pontos_dessa_jogada
	
	# Lógica de interferência
	if total_na_mesa >= 300:
		var chance_de_socar = 0.50
		if randf() < chance_de_socar:
			print("💢 Bêbado: TÁ FAZENDO PONTO DEMAIS! *SOCÃO*")
			tocar_voz(vozes_raiva, true, 1.1) # Mais rápido quando tá puto
			
			ja_atrapalhou_player = true
			manager.aplicar_socao_na_mesa()
			return true
		else:
			print("🤔 Bêbado: Hmmm... vou deixar passar...")
			# Só fala 40% das vezes quando deixa passar
			if randf() < 0.4:
				tocar_voz(vozes_pensando, false, 0.95) # Mais devagar quando tá pensativo
			
	return false

# OVERRIDE 2: Reação ao Farkle (O Rage Quit)
func _handle_farkle_event():
	print("Bêbado: Farkle?!")

	# ✅ Agora ele só fica puto e aceita o farkle
	print("Bêbado: Ahh... que @#$%! Garçom, mais uma!")
	
	# 70% de chance de ficar bravo (mas não fazer nada)
	if randf() < 0.5:
		tocar_voz(vozes_raiva, true, 1.15)
	else:
		tocar_voz(vozes_tristeza, true, 0.9)
	
	ja_socou_mesa = false 
	manager.finalizar_turno_farkle()

# OVERRIDE 3: Estratégia de Seleção
func _escolher_dados_estrategia(dados_objs, valores) -> Array:
	# Aqui a mágica da herança: chamamos a função do PAI (AIBase)
	# Não precisa reescrever o código todo!
	return _escolher_dados_otimizado(dados_objs, valores)

# OVERRIDE 4: Avaliação de Risco
func _decidir_risco(dados_restantes, pontos_mesa, _score_sel, total_geral) -> bool:
	if total_geral >= manager.target_score: 
		tocar_voz(vozes_vitoria, true, 1.05)
		return false
		
	if dados_restantes == 0: return true
	
	# Parar nos 500
	if pontos_mesa >= 500:
		if randf() < 0.85:
			# Só comemora 60% das vezes
			if randf() < 0.6:
				tocar_voz(vozes_vitoria, false, 1.0)
			return false
	
	if ja_socou_mesa: return randf() < 0.1
	if dados_restantes >= 3: return true
	if dados_restantes == 2: return randf() < 0.5
	if dados_restantes == 1: return randf() < 0.2
	
	return false

# Resetar a flag quando o turno dele começa
func iniciar_decisao(manager_ref):
	ja_atrapalhou_player = false
	ja_socou_mesa = false
	super.iniciar_decisao(manager_ref)
