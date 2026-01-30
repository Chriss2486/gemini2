extends Sprite2D
# Referência ao script principal do mapa
@onready var mapa = get_node("/root/Mapa")  # Ajuste o caminho se necessário

var indice_anterior = 0

func _ready():
	await get_tree().process_frame
	indice_anterior = mapa.indice_fase_atual

func _process(_delta: float) -> void:
	var indice_atual = mapa.indice_fase_atual
	
	# Detecta se avançou ou voltou - SEM THRESHOLD
	if indice_atual > indice_anterior:
		# AVANÇANDO -> FLIPADO
		flip_h = true
		indice_anterior = indice_atual
	elif indice_atual < indice_anterior:
		# VOLTANDO -> NÃO FLIPADO
		flip_h = false
		indice_anterior = indice_atual
