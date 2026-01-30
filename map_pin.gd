extends Area2D

@export var level_data: LevelData
@export var levelscreen: PackedScene

@onready var icone = $Control/VBoxContainer/TextureRect
@onready var label = $Control/VBoxContainer/Label
@onready var label2 = $Control/VBoxContainer/Label2

var posicao_mouse_press = Vector2.ZERO
const THRESHOLD_CLIQUE = 10.0 

func _ready() -> void:
	input_pickable = true
	input_event.connect(_on_input_event)
	
	if level_data:
		level_data.data_changed.connect(atualizar_visual_pin)
		atualizar_visual_pin()

func atualizar_visual_pin() -> void:
	if not level_data: return
	
	var display_name = level_data.get_display_name()
	label.text = display_name
	
	if level_data.level_name.is_empty():
		label2.text = ""
	elif display_name == level_data.sub_name:
		label2.text = ""
	else:
		label2.text = level_data.sub_name

	label.visible = not label.text.is_empty()
	label2.visible = not label2.text.is_empty()
	icone.texture = level_data.get_active_icon()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			posicao_mouse_press = event.position
		else:
			var movimento = (event.position - posicao_mouse_press).length()
			var mapa = get_parent()
			var mapa_arrastando = false
			
			if mapa and mapa.has_method("esta_arrastando_mapa"):
				mapa_arrastando = mapa.esta_arrastando_mapa()
			
			if movimento < THRESHOLD_CLIQUE and not mapa_arrastando:
				iniciar_sequencia_viagem()

func iniciar_sequencia_viagem() -> void:
	if not level_data: return
	var mapa = get_parent()
	if mapa and mapa.has_method("viajar_para_id"):
		if not mapa.is_connected("viagem_concluida", _ao_chegar_no_destino):
			mapa.viagem_concluida.connect(_ao_chegar_no_destino, CONNECT_ONE_SHOT)
		mapa.viajar_para_id(level_data.level_id)

func _ao_chegar_no_destino() -> void:
	if levelscreen:
		var menu = levelscreen.instantiate()
		
		if "level_data" in menu:
			menu.level_data = self.level_data
		
		var layer = CanvasLayer.new()
		get_tree().root.add_child(layer)
		layer.add_child(menu)
		
		# PRESET_CENTER é melhor para janelas de pergaminho
		if menu is Control:
			menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		if menu.has_method("atualizar_ui"):
			menu.atualizar_ui(level_data)
