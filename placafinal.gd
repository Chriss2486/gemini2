extends Node3D


func _ready() -> void:
	hide()
	await get_tree().create_timer(0.1).timeout
	show()
	$AnimationPlayer.play("PlaneAction_001")
