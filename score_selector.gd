extends PanelContainer

@onready var number_list = $Panel/VBoxContainer/WheelContainer/NumberList
@onready var scroll_container = $Panel/VBoxContainer/WheelContainer
@onready var difficulty_container = $Panel/VBoxContainer/HBoxContainer
@onready var difficulty_option: OptionButton = $Panel/VBoxContainer/HBoxContainer/OptionButton

var custom_font = load("res://Almendra/Almendra-Regular.ttf")

# Configurações do Seletor de Score
var min_score = 1500
var max_score = 10000
var step_score = 500
var default_score = 3000

# --- AJUSTES VISUAIS ---
var item_height = 90.0
var separation = 0
var visible_items = 3

var current_selected_index = 0
var is_dragging = false
var labels: Array[Label] = []

# 🆕 Dificuldade/Boss selecionado
var selected_difficulty: int = 1 # 0=Fácil, 1=Médio, 2=Difícil, 3=Sylas
var selected_boss_id: String = "PADRAO" # "PADRAO" ou "BEBADO"
var is_vs_ai_mode: bool = true

func _ready():
	_setup_difficulty_option()
	
	# Configuração do Container de Scroll
	var window_height = (item_height * visible_items) + (separation * (visible_items - 1))
	scroll_container.custom_minimum_size.y = window_height
	scroll_container.clip_contents = true
	
	# IMPORTANTE: Desativa comportamentos que brigam com o Snap manual
	scroll_container.get_v_scroll_bar().modulate.a = 0
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll_container.scroll_deadzone = 0
	
	scroll_container.gui_input.connect(_on_scroll_input)
	
	gerar_lista()
	
	# Aguarda o motor de UI estabilizar
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Seleciona o valor padrão (3000)
	var start_index = (default_score - min_score) / step_score
	selecionar_indice(int(start_index))

# 🆕 Configura as 4 opções (3 dificuldades + Sylas)
func _setup_difficulty_option():
	difficulty_option.clear()
	difficulty_option.add_item("Easy", 0)
	difficulty_option.add_item("Medium", 1)
	difficulty_option.add_item("Hard", 2)
	difficulty_option.add_separator() # Separador visual
	difficulty_option.add_item("🍺 Sylas (Boss)", 3)
	
	difficulty_option.selected = 1 # Médio por padrão
	difficulty_option.item_selected.connect(_on_difficulty_changed)

# 🆕 Callback quando muda a dificuldade/boss
func _on_difficulty_changed(index: int):
	selected_difficulty = index
	
	# Define qual Boss/IA usar
	if index == 4:
		# Sylas selecionado
		selected_boss_id = "BEBADO"
		print("🍺 Boss Sylas selecionado!")
	else:
		# IA padrão com dificuldade
		selected_boss_id = "PADRAO"
		print("IA selecionada - Dificuldade: ", ["Fácil", "Médio", "Difícil"][index])

func configurar_modo(vs_ai: bool):
	is_vs_ai_mode = vs_ai
	if difficulty_container:
		difficulty_container.visible = vs_ai
		difficulty_container.modulate.a = 1.0 if vs_ai else 0.0

func gerar_lista():
	for child in number_list.get_children():
		child.queue_free()
	labels.clear()
	
	var window_height = (item_height * visible_items) + (separation * (visible_items - 1))
	var spacer_size = (window_height / 2) - (item_height / 2)
	
	# Spacer Topo
	var spacer_top = Control.new()
	spacer_top.custom_minimum_size.y = spacer_size
	number_list.add_child(spacer_top)
	
	# Números
	for score in range(min_score, max_score + 1, step_score):
		var lbl = Label.new()
		lbl.text = str(score)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size.y = item_height
		lbl.add_theme_font_override("font", custom_font)
		lbl.add_theme_font_size_override("font_size", 60)
		
		lbl.pivot_offset = Vector2(0, item_height / 2)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		number_list.add_child(lbl)
		labels.append(lbl)
	
	# Spacer Fundo
	var spacer_bot = Control.new()
	spacer_bot.custom_minimum_size.y = spacer_size
	number_list.add_child(spacer_bot)

func _process(delta):
	var viewport_center_y = scroll_container.global_position.y + (scroll_container.size.y / 2)
	var total_item_height = item_height + separation
	
	# --- EFEITO VISUAL ---
	for lbl in labels:
		var label_center_y = lbl.global_position.y + (lbl.size.y / 2)
		var dist = abs(viewport_center_y - label_center_y)
		
		lbl.pivot_offset = lbl.size / 2
		
		var scale_factor = clamp(remap(dist, 0, 180, 1.4, 0.4), 0.4, 1.4)
		var alpha_factor = clamp(remap(dist, 0, 150, 1.0, 0.3), 0.3, 1.0)
		
		lbl.scale = Vector2(scale_factor, scale_factor)
		lbl.modulate.a = alpha_factor

	# --- SNAP SUAVE ---
	if not is_dragging:
		var target_y = current_selected_index * total_item_height
		var current_y = scroll_container.scroll_vertical
		
		if abs(current_y - target_y) > 0.5:
			scroll_container.scroll_vertical = lerp(float(current_y), float(target_y), 15.0 * delta)
		else:
			scroll_container.scroll_vertical = target_y

func _on_scroll_input(event):
	var total_item_height = item_height + separation
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			if not is_dragging:
				calculate_snap()
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			current_selected_index = clamp(current_selected_index - 1, 0, labels.size() - 1)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			current_selected_index = clamp(current_selected_index + 1, 0, labels.size() - 1)
	
	if event is InputEventMouseMotion and is_dragging:
		scroll_container.scroll_vertical -= event.relative.y
		current_selected_index = round(scroll_container.scroll_vertical / total_item_height)
		current_selected_index = clamp(current_selected_index, 0, labels.size() - 1)

func calculate_snap():
	var total_item_height = item_height + separation
	current_selected_index = clamp(round(scroll_container.scroll_vertical / total_item_height), 0, labels.size() - 1)

func selecionar_indice(idx):
	current_selected_index = clamp(idx, 0, labels.size() - 1)
	scroll_container.scroll_vertical = current_selected_index * (item_height + separation)

# 🆕 Atualizado: Passa dificuldade E boss_id
func _on_play_button_pressed() -> void:
	var score_final = min_score + (current_selected_index * step_score)
	var gm = get_parent()
	
	if gm and gm.has_method("iniciar_jogo"):
		if is_vs_ai_mode:
			# Se for Sylas (índice 3), dificuldade não importa
			# Se for IA padrão (0,1,2), passa a dificuldade
			var diff_to_pass = selected_difficulty if selected_boss_id == "PADRAO" else 0
			gm.iniciar_jogo(score_final, diff_to_pass, selected_boss_id)
		else:
			gm.iniciar_jogo(score_final, 0, "")

func _on_cancel_button_pressed() -> void:
	var gm = get_parent()
	if gm and gm.has_method("cancelar_selecao"):
		gm.cancelar_selecao()
