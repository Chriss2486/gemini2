extends Node2D

signal viagem_concluida

# --- REFERÊNCIAS ---
@onready var caminho_follow: PathFollow2D = $Caminho/CaminhoFollow
@onready var personagem: Sprite2D = $Caminho/CaminhoFollow/Personagem
@onready var camera: Camera2D = $Camera2D

# --- CONFIGURAÇÕES ---
var level_positions = {
	"1-1": 192.33, "1-2": 500.68, "1-boss": 791.65,
	"2-1": 1075.6, "2-2": 1274.0, "2-3": 1474.3, "2-boss": 1810.84,
	"3-1": 2276.79, "3-2": 2516.04, "3-3": 2861.74, "3-boss": 3279.04,
	"4-1": 3527.04, "4-2": 3797.79, "4-3": 4044.79, "4-boss": 4336.04,
	"5-1": 4534.54, "5-2": 4881.59, "5-3": 5137.49, "5-4": 5370.94, "5-boss": 5580.22,
	"6-1": 5849.84, "6-2": 6160.29, "6-3": 6328.74, "6-4": 6623.64, "6-boss": 6783.99
}

@onready var lista_de_fases = level_positions.keys()
var indice_fase_atual = 0
var seguindo_personagem = true
var ultima_posicao_x = 0.0

# --- CONTROLES DE ARRASTO MELHORADOS ---
var esta_arrastando = false
var posicao_inicial_mouse = Vector2.ZERO
var arrasto_acumulado = Vector2.ZERO
var velocidade_arrasto = Vector2.ZERO
var ultima_posicao_mouse = Vector2.ZERO

# Configurações de sensibilidade
const THRESHOLD_ARRASTO = 10.0  # Pixels mínimos para considerar arrasto
const FRICÇÃO_INERCIA = 0.92     # Quanto maior, mais desliza (0-1)
const VELOCIDADE_MIN_INERCIA = 0.5  # Velocidade mínima para aplicar inércia
const SENSIBILIDADE_ARRASTO = 1.0   # Multiplica a velocidade do arrasto

# Configurações de viagem
const VELOCIDADE_VIAGEM = 500.0  # Unidades por segundo (ajuste conforme necessário)
const TEMPO_MIN_VIAGEM = 1.0     # Tempo mínimo de viagem em segundos
const TEMPO_MAX_VIAGEM = 5.0     # Tempo máximo de viagem em segundos

func _ready():
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 2048
	camera.limit_bottom = 1536
	
	var fase_inicial = lista_de_fases[indice_fase_atual]
	caminho_follow.progress = level_positions[fase_inicial]
	camera.global_position = personagem.global_position
	ultima_posicao_x = personagem.global_position.x

func _process(delta: float) -> void:
	# Atualiza flip do personagem
	var pos_x_atual = personagem.global_position.x
	var deslocamento = pos_x_atual - ultima_posicao_x
	
	if abs(deslocamento) > 0.5:
		personagem.flip_h = (deslocamento > 0)
	ultima_posicao_x = pos_x_atual

	# Segue o personagem quando necessário
	if seguindo_personagem:
		camera.global_position = personagem.global_position
	
	# Aplica inércia quando não está arrastando
	if not esta_arrastando and velocidade_arrasto.length() > VELOCIDADE_MIN_INERCIA:
		camera.global_position += velocidade_arrasto * delta * 60.0
		velocidade_arrasto *= FRICÇÃO_INERCIA
		aplicar_limites_camera()
	
	# Atalhos de teclado (opcional para debug)
	if Input.is_action_just_pressed("ui_accept"): avancar_fase()
	if Input.is_action_just_pressed("ui_cancel"): voltar_fase()

func _input(event):
	# Detecta início do toque/clique
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			iniciar_arrasto(event.position)
		else:
			finalizar_arrasto()
	
	# Detecta movimento durante o arrasto
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		processar_arrasto(event)

func iniciar_arrasto(pos: Vector2):
	posicao_inicial_mouse = pos
	ultima_posicao_mouse = pos
	arrasto_acumulado = Vector2.ZERO
	velocidade_arrasto = Vector2.ZERO
	esta_arrastando = false  # Só vira true se passar do threshold

func processar_arrasto(event: InputEventMouseMotion):
	arrasto_acumulado += event.relative
	
	# Só considera arrasto se passar do threshold
	if not esta_arrastando and arrasto_acumulado.length() > THRESHOLD_ARRASTO:
		esta_arrastando = true
		seguindo_personagem = false
	
	# Se está realmente arrastando, move a câmera
	if esta_arrastando:
		var delta_movimento = event.relative * SENSIBILIDADE_ARRASTO
		camera.global_position -= delta_movimento
		
		# Calcula velocidade para inércia
		velocidade_arrasto = -(event.position - ultima_posicao_mouse) * SENSIBILIDADE_ARRASTO
		
		aplicar_limites_camera()
	
	ultima_posicao_mouse = event.position

func finalizar_arrasto():
	# Se não passou do threshold, não considera como arrasto
	if arrasto_acumulado.length() < THRESHOLD_ARRASTO:
		esta_arrastando = false
		velocidade_arrasto = Vector2.ZERO

func aplicar_limites_camera():
	var view_size = get_viewport_rect().size / 2
	camera.global_position.x = clamp(
		camera.global_position.x, 
		camera.limit_left + view_size.x, 
		camera.limit_right - view_size.x
	)
	camera.global_position.y = clamp(
		camera.global_position.y, 
		camera.limit_top + view_size.y, 
		camera.limit_bottom - view_size.y
	)

# Função pública para verificar se está arrastando (usada pelos pins)
func esta_arrastando_mapa() -> bool:
	return esta_arrastando

# --- NAVEGAÇÃO ---

func viajar_para_fase(nome_fase: String):
	if level_positions.has(nome_fase):
		seguindo_personagem = true
		esta_arrastando = false  # Cancela qualquer arrasto
		velocidade_arrasto = Vector2.ZERO
		
		var destino = level_positions[nome_fase]
		var posicao_atual = caminho_follow.progress
		var distancia = abs(destino - posicao_atual)
		
		# Calcula tempo baseado na distância
		var duracao = distancia / VELOCIDADE_VIAGEM
		duracao = clamp(duracao, TEMPO_MIN_VIAGEM, TEMPO_MAX_VIAGEM)
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property(caminho_follow, "progress", destino, duracao)
		
		tween.finished.connect(func(): viagem_concluida.emit())

func viajar_para_id(id: int):
	if id >= 0 and id < lista_de_fases.size():
		indice_fase_atual = id
		viajar_para_fase(lista_de_fases[id])

func avancar_fase():
	if indice_fase_atual < lista_de_fases.size() - 1:
		viajar_para_id(indice_fase_atual + 1)

func voltar_fase():
	if indice_fase_atual > 0:
		viajar_para_id(indice_fase_atual - 1)
