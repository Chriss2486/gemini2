extends Control

# Sinal para avisar a tela principal que este widget foi clicado
signal preview_clicked(widget_instance, die_index)

@export var die_index: int = 0
@onready var pivot_node = $SubViewportContainer/SubViewport/dado_low2
@onready var preview_dice_mesh = $SubViewportContainer/SubViewport/dado_low2
@onready var button_overlay: Button = $ButtonOverlay

var rotation_speed: float = 1.0

func _ready():
	print("[DieWidget %s] _ready iniciado." % die_index)
	
	# Aleatoriza a rotação inicial
	if pivot_node:
		pivot_node.rotation.y = deg_to_rad(randf_range(0, 360))
		pivot_node.rotation.x = deg_to_rad(randf_range(0, 360))
		rotation_speed = randf_range(0.3, 0.6) 
	else:
		print("[ERRO] DieWidget %s: pivot_node não encontrado!" % die_index)

	if button_overlay:
		button_overlay.pressed.connect(_on_button_pressed)
	else:
		print("[ERRO] DieWidget %s: button_overlay não encontrado!" % die_index)
		
	update_skin_visual()

func _process(delta):
	if pivot_node:
		pivot_node.rotate_y(rotation_speed * delta)
		pivot_node.rotate_x(rotation_speed * delta * 0.5)

func update_skin_visual():
	print("[DieWidget %s] Tentando atualizar visual..." % die_index)
	
	# 1. Busca o material salvo no GameData
	var material_to_use = GameData.get_material_for_die(die_index)
	
	print("[DieWidget %s] Material recebido: %s" % [die_index, material_to_use])
	
	# 2. Verifica se a mesh e o material existem
	if preview_dice_mesh and material_to_use:
		# Define o material especificamente no Slot 0 (Surface 0) desta instância
		preview_dice_mesh.set_surface_override_material(0, material_to_use)
		print("[DieWidget %s] Material aplicado com sucesso na Surface 0." % die_index)
	elif preview_dice_mesh == null:
		print("[ERRO] DieWidget %s: preview_dice_mesh é NULO." % die_index)
	elif material_to_use == null:
		print("[AVISO] DieWidget %s: Material é NULO (talvez seja a primeira vez ou erro no load)." % die_index)

func _on_button_pressed():
	print("[DieWidget %s] Clicado! Emitindo sinal..." % die_index)
	# Avisa quem estiver ouvindo (a cena principal) que fui clicado
	emit_signal("preview_clicked", self, die_index)


func _on_button_overlay_pressed() -> void:
	print("[DieWidget %s] Clicado! Emitindo sinal..." % die_index)
	# Avisa quem estiver ouvindo (a cena principal) que fui clicado
	emit_signal("preview_clicked", self, die_index)
