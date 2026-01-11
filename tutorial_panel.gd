extends Control

class_name TutorialUI

# --- EXPORTS ---
@export var tutorial_images: Array[Texture2D] # Arraste suas 4 imagens aqui no Inspector

# --- NÓS ---
@onready var tutorial_image_display: TextureRect = $TutorialImage
@onready var prev_button: Button = $HBoxContainer/PrevButton
@onready var next_button: Button = $HBoxContainer/NextButton
@onready var close_button: Button = $CloseButton

# --- VARIÁVEIS INTERNAS ---
var current_image_index = 0

func _ready():
	self.hide() # Começa escondido
	
	# Conecta os botões
	prev_button.pressed.connect(_on_prev_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# Garante que os botões estão habilitados/desabilitados corretamente no início
	_update_navigation_buttons()

func show_tutorial():
	self.visible = true
	current_image_index = 0 # Começa sempre na primeira imagem
	_display_current_image()
	_update_navigation_buttons()

func _display_current_image():
	if tutorial_images.is_empty():
		tutorial_image_display.texture = null
		return
	
	# Garante que o índice está dentro dos limites
	current_image_index = clamp(current_image_index, 0, tutorial_images.size() - 1)
	
	tutorial_image_display.texture = tutorial_images[current_image_index]
	
	_update_navigation_buttons()

func _update_navigation_buttons():
	if tutorial_images.is_empty():
		prev_button.disabled = true
		next_button.disabled = true
		return
		
	prev_button.disabled = (current_image_index == 0)
	next_button.disabled = (current_image_index == tutorial_images.size() - 1)

# --- FUNÇÕES DE BOTÕES ---
func _on_prev_button_pressed():
	current_image_index -= 1
	_display_current_image()

func _on_next_button_pressed():
	current_image_index += 1
	_display_current_image()

func _on_close_button_pressed():
	self.hide()
