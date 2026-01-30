extends Resource
class_name LevelData

signal data_changed # Sinal importante para atualizações em tempo real

@export var level_id: int = 1
@export var level_name: String = ""
@export var sub_name: String = "Nova Taverna"
@export var level_icon: Texture2D
@export var defeated_level_icon: Texture2D
@export_enum("FACIL", "MEDIO", "DIFICIL") var dificuldade = 1
@export var target_score: int = 5000
@export var boss_script: GDScript 
@export var reward_skin_index: int = -1
@export_multiline var dialog_intro: String = "Boa sorte, forasteiro!"

@export var defeated: bool = false:
	set(valor):
		defeated = valor
		data_changed.emit() # Avisa que mudou!

func get_active_icon() -> Texture2D:
	if defeated and defeated_level_icon != null:
		return defeated_level_icon
	return level_icon

func get_display_name() -> String:
	if level_name.is_empty():
		return sub_name
	return level_name
