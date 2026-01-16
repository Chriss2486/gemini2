extends Control

# Referências para as duas linhas de dados
@onready var hbox1 = $PanelContainer/Panel/Vbox/HBox1
@onready var hbox2 = $PanelContainer/Panel/Vbox/HBox2
@onready var skin_grid = $PanelContainer/Panel/GridContainer
@onready var close_button = $PanelContainer/Panel/CloseButton

var current_selecting_die_index: int = -1
var active_preview_widget: Control = null

func _ready():
	
	if hbox1:
		for widget in hbox1.get_children():
			if widget.has_signal("preview_clicked"):
				widget.preview_clicked.connect(_on_preview_widget_clicked)
	if hbox2:
		for widget in hbox2.get_children():
			if widget.has_signal("preview_clicked"):
				widget.preview_clicked.connect(_on_preview_widget_clicked)

	# 2. Popular o grid de skins disponíveis
	populate_skin_list()

func populate_skin_list():
	if skin_grid == null:
		return

	for child in skin_grid.get_children():
		child.queue_free()
	
	var total_skins = GameData.available_skins.size()
	
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

func _on_preview_widget_clicked(widget_ref, die_idx):
	current_selecting_die_index = die_idx
	active_preview_widget = widget_ref

func _on_skin_list_button_pressed(skin_index_chosen):
	if current_selecting_die_index != -1:
		# 1. Salva a escolha no Autoload
		GameData.selected_skin_indices[current_selecting_die_index] = skin_index_chosen
		# 2. Atualiza o visual do dado que estava girando
		if active_preview_widget:
			active_preview_widget.update_skin_visual()
		# 3. Reseta seleção
		current_selecting_die_index = -1

func _on_close_button_pressed() -> void:
	hide()
