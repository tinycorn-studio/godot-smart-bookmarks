# enemy_boss.gd
# Mock enemy boss script for Smart Bookmarks demonstration.
class_name MockEnemyBoss
extends CharacterBody2D

@export var boss_name: String = "Dragon Lord"
@export var max_health: int = 1500
@export var attack_power: int = 80

var phase: int = 1

func trigger_phase_two() -> void:
	phase = 2
	print("Boss entering phase 2 with increased aggression!")
