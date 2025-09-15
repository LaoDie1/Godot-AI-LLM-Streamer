#============================================================
#    Bullet
#============================================================
# - author: zhangxuetu
# - datetime: 2025-08-13 18:59:33
# - version: 4.4.1.stable
#============================================================
class_name BulletComponent
extends Area2D

signal collided(target: Role)

@export var move_speed: float = 0.0
@export var duration: float = 1.0

var _last_rotation: float 
@onready var _velocity: Vector2 = Vector2.RIGHT


func _ready():
	area_entered.connect(_take_damage)
	body_entered.connect(_take_damage)
	_last_rotation = self.rotation
	_velocity = Vector2.RIGHT.rotated(rotation)

func _physics_process(delta):
	if rotation != _last_rotation:
		_velocity = Vector2.RIGHT.rotated(rotation)
	
	global_position += _velocity * move_speed * delta
	
	duration -= delta
	if duration <= 0:
		queue_free()


func _take_damage(body):
	if body is CharacterBody2D:
		var target : Role = Role.find_role(body)
		if target:
			collided.emit(target)
