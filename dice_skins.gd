extends Control

# Referências para as duas linhas de dados
@onready var hbox1 = $PanelContainer/Panel/Vbox/HBox1
@onready var hbox2 = $PanelContainer/Panel/Vbox/HBox2
@onready var skin_grid = $PanelContainer/Panel/GridContainer
@onready var close_button = $PanelContainer/Panel/CloseButton

var current_selecting_die_index: int = -1
var active_preview_widget: Control = null

func _ready():
	print("[TelaSelecao] _ready iniciado.")
	
	# 1. Conectar sinais da PRIMEIRA fileira
	if hbox1:
		print("[TelaSelecao] HBox1 encontrado. Conectando filhos...")
		for widget in hbox1.get_children():
			if widget.has_signal("preview_clicked"):
				widget.preview_clicked.connect(_on_preview_widget_clicked)
				print("[TelaSelecao] Conectado ao widget: ", widget.name)
	else:
		print("[ERRO] HBox1 não encontrado!")

	# 1. Conectar sinais da SEGUNDA fileira
	if hbox2:
		print("[TelaSelecao] HBox2 encontrado. Conectando filhos...")
		for widget in hbox2.get_children():
			if widget.has_signal("preview_clicked"):
				widget.preview_clicked.connect(_on_preview_widget_clicked)
				print("[TelaSelecao] Conectado ao widget: ", widget.name)
	else:
		print("[ERRO] HBox2 não encontrado!")

	# 2. Popular o grid de skins disponíveis
	populate_skin_list()

func populate_skin_list():
	print("[TelaSelecao] Populando lista de skins...")
	
	if skin_grid == null:
		print("[ERRO] skin_grid (GridContainer) é NULO! Verifique o caminho.")
		return

	for child in skin_grid.get_children():
		child.queue_free()
	
	var total_skins = GameData.available_skins.size()
	print("[TelaSelecao] Total de skins encontradas no GameData: ", total_skins)
	
	for i in range(total_skins):
		var skin_data = GameData.available_skins[i]
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(100, 80)
		
		if skin_data.has("icon") and skin_data["icon"] != null:
			var icon_tex = load(skin_data["icon"])
			btn.icon = icon_tex
			btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			btn.expand_icon = true
		else:
			btn.text = skin_data["name"]
		
		# Conecta o clique passando o índice 'i'
		btn.pressed.connect(_on_skin_list_button_pressed.bind(i))
		
		skin_grid.add_child(btn)
	
	print("[TelaSelecao] Grid populado com botões.")

func _on_preview_widget_clicked(widget_ref, die_idx):
	print("[TelaSelecao] Recebi clique do Dado Índice: ", die_idx)
	current_selecting_die_index = die_idx
	active_preview_widget = widget_ref
	
	# Se tiver lógica de mostrar popup, adicione prints aqui também
	# print("Abrindo popup para dado ", die_idx)

func _on_skin_list_button_pressed(skin_index_chosen):
	print("[TelaSelecao] Botão de Skin pressionado. Skin Index: ", skin_index_chosen)
	
	if current_selecting_die_index != -1:
		print(" >> Aplicando Skin %s no Dado %s" % [skin_index_chosen, current_selecting_die_index])
		
		# 1. Salva a escolha no Autoload
		GameData.selected_skin_indices[current_selecting_die_index] = skin_index_chosen
		
		# 2. Atualiza o visual do dado que estava girando
		if active_preview_widget:
			print(" >> Chamando update_skin_visual no widget...")
			active_preview_widget.update_skin_visual()
		else:
			print("[ERRO] active_preview_widget é nulo na hora de aplicar!")
		
		# 3. Reseta seleção
		current_selecting_die_index = -1
	else:
		print("[AVISO] Nenhuma dado selecionado (current_selecting_die_index é -1). Clique no dado 3D primeiro.")


func _on_close_button_pressed() -> void:
	hide()
