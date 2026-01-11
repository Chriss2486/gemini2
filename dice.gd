extends RigidBody3D

class_name Dice

# SINAL: Avisa quem estiver ouvindo (Manager) que este dado parou
signal roll_finished(die_ref)

# --- REFERÊNCIAS INTERNAS ---
@onready var hit_sound = $HitSound
@onready var outline_mesh = $outline
@onready var value_label = $Label3D
@onready var visual_mesh = $dado_low2
@onready var manager = $"."

var material_skin_inicial: Material = null
# --- REFERÊNCIA EXTERNA ---
# Injetada pelo Manager no momento do spawn


# --- CONFIGURAÇÕES (Ajustáveis no Inspector) ---
@export_group("Física do Dado")
@export var stop_threshold: float = 0.1      # Velocidade mínima para considerar parado
@export var time_to_confirm: float = 0.5     # Tempo que deve ficar abaixo do threshold
@export var table_height: float = 1.43       # Altura Y da mesa (chão da colisão)
@export var stack_limit_offset: float = 0.10 # Margem acima da mesa para considerar empilhado

# --- ESTADOS ---
var is_selected: bool = false
var is_rolling: bool = true
var final_value: int = 0
var original_index: int = -1

# --- VARIÁVEIS DE CONTROLE ---
var stop_timer: float = 0.0
var last_hit_time: float = 0.0
var hit_cooldown: float = 0.0 # Evita spam de som de colisão
var is_banked: bool = false # Define se o dado já foi "salvo" na bandeja

# Mapeamento das faces (Vetor de direção Local -> Valor da face)
var faces = {
	Vector3.UP: 6,
	Vector3.DOWN: 1,
	Vector3.FORWARD: 3,
	Vector3.BACK: 4,
	Vector3.RIGHT: 5,
	Vector3.LEFT: 2
}

func _ready():
	contact_monitor = true
	max_contacts_reported = 3
	can_sleep = false 
	input_ray_pickable = false # Começa não clicável (pois nasce rolando)
	if material_skin_inicial and visual_mesh:
		visual_mesh.set_surface_override_material(0, material_skin_inicial)
	body_entered.connect(_on_body_entered)
	
	# Garante estado visual inicial
	atualizar_visual()

func _process(delta):
	if is_rolling:
		# Verifica velocidades Linear e Angular
		if linear_velocity.length() < stop_threshold and angular_velocity.length() < stop_threshold:
			stop_timer += delta
			
			if stop_timer >= time_to_confirm:
				verificar_parada()
		else:
			stop_timer = 0.0

# Chamado quando o dado parece ter parado
func verificar_parada():
	var altura_limite = table_height + stack_limit_offset
	
	# LÓGICA ANTI-EMPILHAMENTO
	# Se o dado parou mas está flutuando muito acima da mesa, ele está em cima de outro dado
	if global_position.y > altura_limite:
		print("Dice: Detectado empilhamento. Aplicando força de fuga...")
		resolver_empilhamento()
		return 

	# Se passou no teste de altura, finaliza
	finalizar_rolagem()

func resolver_empilhamento():
	sleeping = false 
	# Empurrão lateral aleatório + um pouco para cima
	var direcao_fuga = Vector3(randf_range(-10, 10), 0.5, randf_range(-10, 10)).normalized()
	
	# Forças ajustadas (o 100.0 anterior podia ser muito forte dependendo da massa)
	apply_central_impulse(direcao_fuga * 50.0) 
	apply_torque_impulse(Vector3(randf(), randf(), randf()) * 30.0)
	
	stop_timer = 0.0 
	
func is_locked() -> bool:
	# O dado é considerado "travado" se ele já foi pontuado (banked)
	return is_banked


func finalizar_rolagem():
	is_rolling = false
	stop_timer = 0.0
	
	# TRAVA TOTAL DE FÍSICA
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true # Isso transforma o dado em um objeto estático temporariamente
	
	input_ray_pickable = true 
	final_value = get_current_face()
	roll_finished.emit(self)

# Chamado pelo Manager quando vamos jogar esse dado novamente
func reset_dice():
	is_rolling = true
	is_selected = false
	stop_timer = 0.0
	sleeping = false
	input_ray_pickable = false # Trava clique durante o voo
	atualizar_visual()

# --- INPUT E SELEÇÃO ---

func _input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# TRAVA 1: Se o dado ainda está rolando, ignora
		if is_rolling:
			return
			
		# TRAVA 2: Pergunta ao manager se o humano pode clicar agora
		if manager and not manager.pode_interagir_humano():
			return
		
		# Se passou, alterna seleção
		toggle_selection()

func toggle_selection():
	is_selected = !is_selected
	atualizar_visual()

	if manager:
		if manager.has_method("atualizar_interface_apos_clique"):
			manager.atualizar_interface_apos_clique()

func atualizar_visual():
	if outline_mesh: outline_mesh.visible = is_selected
	if value_label: value_label.visible = is_selected

# --- UTILITÁRIOS ---

func get_current_face() -> int:
	var closest_face = 1
	var max_dot = -2.0 # Menor que -1.0 para garantir update
	
	for direction in faces.keys():
		# Converte a direção local (Ex: Vector3.UP) para rotação global atual
		var global_dir = global_transform.basis * direction
		# Compara com o "Céu" (Vector3.UP global)
		var dot = global_dir.dot(Vector3.UP)
		
		if dot > max_dot:
			max_dot = dot
			closest_face = faces[direction]
			
	return closest_face

func _on_body_entered(body):
	if body.is_in_group("MESA") or body.is_in_group("DICE"):
		var current_time = Time.get_ticks_msec() / 1000.0
		
		if current_time - last_hit_time > hit_cooldown:
			var velocity = linear_velocity.length()
			
			if velocity > 0.5:
				# Mapeia a velocidade para o volume
				# Velocidade 0.5 (mínima) -> -25dB (quase inaudível)
				# Velocidade 10.0 (máxima) -> 0dB (volume original do arquivo)
				var vol = remap(velocity, 0.0, 10.0, -15.0, -10.0)
				hit_sound.volume_db = clamp(vol, -30.0, 5.0) # Clamp de segurança
				
				# O Pitch fica fixo em 1.0 (som original) 
				# ou com uma variação minúscula apenas para dar naturalidade
				hit_sound.pitch_scale = randf_range(0.75, 0.85)
				
				hit_sound.play()
				last_hit_time = current_time
				
func apply_skin(material_resource: Material):
	material_skin_inicial = material_resource
	if visual_mesh:
		visual_mesh.set_surface_override_material(0, material_resource)
