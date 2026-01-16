extends Control

# Sinal para avisar a tela principal que este widget foi clicado
signal preview_clicked(widget_instance, die_index)

@export var die_index: int = 0
@onready var pivot_node = $SubViewportContainer/SubViewport/dado_low2
@onready var preview_dice_mesh = $SubViewportContainer/SubViewport/dado_low2
@onready var button_overlay: Button = $ButtonOverlay

var rotation_speed: float = 1.0

func _ready():
	# Aleatoriza a rotação inicial
	if pivot_node:
		pivot_node.rotation.y = deg_to_rad(randf_range(0, 360))
		pivot_node.rotation.x = deg_to_rad(randf_range(0, 360))
		rotation_speed = randf_range(0.3, 0.6) 

	if button_overlay:
		button_overlay.pressed.connect(_on_button_pressed)
		
	update_skin_visual()

func _process(delta):
	if pivot_node:
		pivot_node.rotate_y(rotation_speed * delta)
		pivot_node.rotate_x(rotation_speed * delta * 0.5)

func update_skin_visual():
	# 1. Busca o material salvo no GameData
	var material_to_use = GameData.get_material_for_die(die_index)
	
	# 2. Verifica se a mesh e o material existem
	if preview_dice_mesh and material_to_use:
		# Define o material especificamente no Slot 0 (Surface 0) desta instância
		preview_dice_mesh.set_surface_override_material(0, material_to_use)

func _on_button_pressed():
	emit_signal("preview_clicked", self, die_index)

func _on_button_overlay_pressed() -> void:
	emit_signal("preview_clicked", self, die_index)
