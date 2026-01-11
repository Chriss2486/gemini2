extends Light3D

@export_group("Configurações da Chama")
@export var intensidade_base: float = 70.0
@export var variacao_brilho: float = 3.0
@export var velocidade_oscilacao: float = 5.0

@export_group("Configurações de Movimento")
@export var tremer_posicao: bool = true
@export var raio_tremor: float = 0.08
@export var velocidade_tremor: float = 4.0

@onready var posicao_original: Vector3 = position

var tempo: float = 0.0
var seed_aleatoria: float = 0.0

func _ready() -> void:
	seed_aleatoria = randf_range(0.0, 1000.0)
	posicao_original = position

func _process(delta: float) -> void:
	tempo += delta * velocidade_oscilacao
	var tempo_com_seed = tempo + seed_aleatoria

	var noise = sin(tempo_com_seed) * cos(tempo_com_seed * 1.3) + sin(tempo_com_seed * 0.6)
	light_energy = intensidade_base + (noise * variacao_brilho)
	
	if tremer_posicao:
		var deslocamento = Vector3(
			sin(tempo_com_seed * velocidade_tremor * 0.85),
			cos(tempo_com_seed * velocidade_tremor * 1.15),
			sin(tempo_com_seed * velocidade_tremor * 0.7)
		) * raio_tremor
		
		position = posicao_original + deslocamento
