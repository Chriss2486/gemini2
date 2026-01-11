extends Control

@onready var game_manager = $".."

# --- REFERÊNCIAS DA UI ---
@onready var close_button: TextureButton = $PanelContainer/Panel/CloseButton
@onready var music_button: TextureButton = $PanelContainer/Panel/OptionsContainer/Volumes/Music/MusicButton
@onready var music_slider: HSlider = $PanelContainer/Panel/OptionsContainer/Volumes/Music/MusicSlider/MusicSlider
@onready var sfx_button: TextureButton = $PanelContainer/Panel/OptionsContainer/Volumes/SFX/SFXButton
@onready var sfx_slider: HSlider = $PanelContainer/Panel/OptionsContainer/Volumes/SFX/SFXSlider/SFXSlider
@onready var menu_button: Button = $"PanelContainer/Panel/OptionsContainer/Menu Button"

# Índices dos canais de áudio
var bus_music_idx: int = 1
var bus_sfx_idx: int = 2

# Caminho do arquivo de save (Funciona em PC e Mobile)
const SAVE_PATH = "user://game_settings.cfg"
var config = ConfigFile.new()

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	bus_music_idx = AudioServer.get_bus_index("musica")
	bus_sfx_idx = AudioServer.get_bus_index("efeitos")

	# Configura Sliders
	music_slider.max_value = 1.0
	music_slider.step = 0.05
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.05

	# --- CARREGAR CONFIGURAÇÕES SALVAS ---
	load_settings()

# --- SISTEMA DE SAVE / LOAD ---

func save_settings():
	# Salva Música
	config.set_value("audio", "music_vol", music_slider.value)
	config.set_value("audio", "music_mute", AudioServer.is_bus_mute(bus_music_idx))
	
	# Salva SFX
	config.set_value("audio", "sfx_vol", sfx_slider.value)
	config.set_value("audio", "sfx_mute", AudioServer.is_bus_mute(bus_sfx_idx))
	
	# Grava no disco
	config.save(SAVE_PATH)

func load_settings():
	var err = config.load(SAVE_PATH)
	
	# Se o arquivo existe, carregamos os valores guardados
	var music_vol = config.get_value("audio", "music_vol", 0.8)
	var music_mute = config.get_value("audio", "music_mute", false)
	var sfx_vol = config.get_value("audio", "sfx_vol", 1.0)
	var sfx_mute = config.get_value("audio", "sfx_mute", false)

	# Se o arquivo NÃO existe, pegamos os valores atuais do motor
	if err != OK:
		music_vol = db_to_linear(AudioServer.get_bus_volume_db(bus_music_idx))
		sfx_vol = db_to_linear(AudioServer.get_bus_volume_db(bus_sfx_idx))
	
	# APLICAÇÃO FINAL (Isso vai disparar os sinais de slider automaticamente)
	music_slider.value = music_vol
	sfx_slider.value = sfx_vol
	
	# Mute e Visual (precisam ser forçados após o slider)
	AudioServer.set_bus_mute(bus_music_idx, music_mute)
	AudioServer.set_bus_mute(bus_sfx_idx, sfx_mute)
	_atualizar_icone_mute(music_button, music_mute)
	_atualizar_icone_mute(sfx_button, sfx_mute)

# Helper visual para pintar o botão de cinza se estiver mutado
func _atualizar_icone_mute(botao: TextureButton, is_muted: bool):
	botao.modulate = Color(0.5, 0.5, 0.5) if is_muted else Color(1, 1, 1)

# --- FUNÇÕES DE VOLUME ---

func _on_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(bus_music_idx, linear_to_db(value))
	var is_low = value < 0.01
	AudioServer.set_bus_mute(bus_music_idx, is_low)
	_atualizar_icone_mute(music_button, is_low)
	save_settings()

func _on_sfx_slider_value_changed(value: float) -> void:
	if bus_sfx_idx == -1: return 
	
	AudioServer.set_bus_volume_db(bus_sfx_idx, linear_to_db(value))
	var is_low = value < 0.01
	AudioServer.set_bus_mute(bus_sfx_idx, is_low)
	_atualizar_icone_mute(sfx_button, is_low)
	save_settings()

# --- FUNÇÕES DE MUTE ---

func _on_music_button_toggled(toggled_on: bool) -> void:
	# Assume botão ToggleMode = true
	AudioServer.set_bus_mute(bus_music_idx, toggled_on)
	_atualizar_icone_mute(music_button, toggled_on)
	save_settings() # <--- SALVA AO CLICAR

func _on_sfx_button_toggled(toggled_on: bool) -> void:
	# Assume botão ToggleMode = true
	AudioServer.set_bus_mute(bus_sfx_idx, toggled_on)
	_atualizar_icone_mute(sfx_button, toggled_on)
	save_settings() # <--- SALVA AO CLICAR

# --- NAVEGAÇÃO ---

func _on_close_button_pressed():
		self.visible = false
	
func _on_menu_button_pressed() -> void:
	self.visible = false
	if game_manager:
		game_manager.forcar_retorno_menu()
