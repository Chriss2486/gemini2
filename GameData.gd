extends Node

var available_skins: Array[Dictionary] = [
	{
		"name": "Padrão",
		"path": "res://dice_skins/original.tres", 
		"icon": null 
	},
	{
		"name": "Ouro",
		"path": "res://dice_skins/gold.tres",
		"icon": null
	},
	{
		"name": "Glow",
		"path": "res://dice_skins/glow.tres",
		"icon": null
	},
	{
		"name": "Saphire",
		"path": "res://dice_skins/saphire.tres",
		"icon": null
	}
]

var selected_skin_indices: Array[int] = [0, 0, 0, 0, 0, 0]

# No GameData.gd
var _material_cache = {}

func _ready():
	# Carrega todos os materiais na memória assim que o jogo abre
	for skin in available_skins:
		var path = skin["path"]
		_material_cache[path] = load(path)

func get_material_for_die(die_index: int) -> Material:
	var skin_index = selected_skin_indices[die_index]
	var data = available_skins[skin_index]
	var path = data["path"]

	# 1. Se o material já estiver na memória (cache), retorna ele direto
	if _material_cache.has(path):
		return _material_cache[path]
	
	# 2. Se não estiver, carrega do disco UMA ÚNICA VEZ
	if ResourceLoader.exists(path):
		var loaded_material = load(path)
		_material_cache[path] = loaded_material # Guarda no "baú" (cache)
		return loaded_material
	
	return null
