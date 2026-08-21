# player.gd
# Mock player script for Smart Bookmarks demonstration.
class_name MockPlayer
extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = -400.0
@export var health: int = 100

var gravity: float = 980.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		
	move_and_slide()
