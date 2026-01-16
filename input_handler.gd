extends Node

class_name InputHandler

signal swipe_detected
signal tap_detected(pos)
signal hold_completed
signal interaction_started
signal interaction_ended

# --- CONFIGURAÇÕES MAIS PERMISSIVAS ---
@export var min_swipe_distance: float = 50.0 # Mínimo de pixels para considerar swipe
@export var max_swipe_time: float = 1.0      # AUMENTADO: Tem até 1 segundo para arrastar
@export var tap_threshold: float = 10.0      # Se mover menos que isso, é clique

# --- ESTADO ---
var touch_start_pos = Vector2.ZERO
var touch_start_time = 0.0
var is_touching = false
var can_process_input = true

func _input(event):
	if not can_process_input: return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_touch(event.position)
			else:
				_end_touch(event.position)
	
	# Adicionei suporte a toque real (Mobile) caso precise
	elif event is InputEventScreenTouch:
		if event.pressed:
			_start_touch(event.position)
		else:
			_end_touch(event.position)

func _start_touch(pos: Vector2):
	is_touching = true
	touch_start_pos = pos
	touch_start_time = Time.get_ticks_msec() / 1000.0
	interaction_started.emit()

func _end_touch(pos: Vector2):
	if not is_touching: return
	is_touching = false
	interaction_ended.emit()
	
	var time_diff = (Time.get_ticks_msec() / 1000.0) - touch_start_time
	var drag_vector = pos - touch_start_pos
	var distance = drag_vector.length()

	# --- LÓGICA DE DETECÇÃO ---
	
	# 1. SWIPE (Arraste)
	if distance > min_swipe_distance and time_diff < max_swipe_time:
		swipe_detected.emit()
	# 2. TAP (Clique)
	elif distance < tap_threshold:
		tap_detected.emit(pos)

func cancel_touch():
	is_touching = false
	interaction_ended.emit()

# (Mantenha a função get_hold_progress igual estava antes)
func get_hold_progress() -> float:
	if not is_touching: return 0.0
	var current_time = Time.get_ticks_msec() / 1000.0
	var elapsed = current_time - touch_start_time
	if (get_viewport().get_mouse_position() - touch_start_pos).length() > tap_threshold:
		return 0.0
	if elapsed < 0.3: return 0.0 # Delay fixo
	var progress = (elapsed - 0.3) / 0.5 # Tempo fixo
	if progress >= 1.0:
		hold_completed.emit()
		is_touching = false
		return 1.0
	return progress
