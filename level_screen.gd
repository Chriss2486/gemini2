extends Control


@onready var level: Label = $ScoreSelector/Panel/VBoxContainer/Level
@onready var title: Label = $ScoreSelector/Panel/VBoxContainer/Title
@onready var subtitle: Label = $ScoreSelector/Panel/VBoxContainer/Subtitle
@onready var dificulty: TextureRect = $ScoreSelector/Panel/VBoxContainer/dificulty


@export var level_data: LevelData

func _ready() -> void:
	atualizar_ui(level_data)
	
func atualizar_ui(data: LevelData):
	level.text = "level: " + str(data.level_id + 1)
	
	var display_name = data.get_display_name()
	title.text = display_name
	
	# Se o level_name estiver vazio, não mostramos subtítulo
	if data.level_name.is_empty():
		subtitle.text = ""
	# NOVO: Se o título exibido for igual ao sub_name, escondemos o título
	# e deixamos apenas o sub_name (ou vice-versa, dependendo da sua preferência)
	elif display_name == data.sub_name:
		title.text = "" # Esconde o título principal
		subtitle.text = data.sub_name # Mantém apenas o sub_name
	else:
		subtitle.text = data.sub_name

	# Garante que os Labels não ocupem espaço se estiverem vazios
	title.visible = not title.text.is_empty()
	subtitle.visible = not subtitle.text.is_empty()
	
	update_difficulty_texture(data.dificuldade)

func update_difficulty_texture(valor_dificuldade):
	match valor_dificuldade:
		0:
			dificulty.texture = load("res://textures/dificulties/contender.png")
		1:
			dificulty.texture = load("res://textures/dificulties/veteran.png")
		2:
			dificulty.texture = load("res://textures/dificulties/master.png")


func _on_exit_pressed() -> void:
	queue_free()
