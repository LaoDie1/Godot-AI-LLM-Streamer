#============================================================
#    Role Move Component
#============================================================
# - author: zhangxuetu
# - datetime: 2025-05-15 21:34:08
# - version: 4.4.1
#============================================================
## 角色移动控制的方式
class_name RoleMoveComponent
extends Node2D

signal direction_changed(direction: Vector2)
signal move_state_changed(status: bool)
signal moved(vector: Vector2)
signal jumped
signal fell

@export var role: CharacterBody2D
@export var enabled: bool = true

@export_group("Move", "move")
@export var move_enabled: bool = true
@export var move_speed: float = 0.0
@export_range(0, 1) var move_rate: float = 1.0
@export_range(0, 1) var move_friction: float = 1.0

@export_group("Jump", "jump")
@export var jump_enabled: bool = true
@export var jump_heigth: float = 0.0

@export_group("Gravity", "gravity")
@export var gravity_enabled: bool = true
@export var gravity_max: float = 0.0
@export_range(0, 1) var gravity_rate: float = 0.02

var velocity: Vector2 #当前控制的移动向量

var _last_direction: Vector2 = Vector2.ZERO
var _move_direction: Vector2 = Vector2.ZERO
var _last_move_direction: Vector2 = Vector2.ZERO
var _last_velocity: Vector2 = Vector2.ZERO
var _moving: bool = false:
	set(v):
		if _moving != v:
			_moving = v
			move_state_changed.emit(_moving)
var _jump_count: int = 0  #没有落地前调用 [method jump] 方法的次数
var _jump_last_time: float = 0.0  #已经在空中跳跃的时间

const COYOTE_TIME_MAX = 0.1
const JUMP_BUFFER_TIME_MAX = 0.1
var _coyote_time: float = 0.0  # 土狼时间。如果在这个时间内进行了跳跃，则无论是否在地面上，都可以进行跳跃
var _jump_buffer_time: float = 0.0 #跳跃缓冲时间。如果在落下之前的短时间内按下过跳跃
var on_floor : bool = false

## 这个值默认为 [code]Vector2(0, 0)[/code]，需要手动调用 [method update_direction] 进行更新
func get_last_direction() -> Vector2:
	return _last_direction

func is_moving() -> bool:
	return _moving

func get_jump_count() -> int:
	return _jump_count

func get_jump_last_time() -> float:
	return _jump_last_time

func is_on_floor() -> bool:
	return on_floor

func get_last_move_direction() -> Vector2:
	return _last_move_direction

func _physics_process(delta):
	if enabled:
		on_floor = role.is_on_floor()
		
		# 移动
		var direction = _move_direction
		if move_enabled:
			direction.x = sign(direction.x)
			if direction.x != 0:
				if on_floor or role.is_on_wall():
					# 在地面时的移动
					velocity.x = lerpf(velocity.x, direction.x * move_speed, move_rate)
				else:
					# 不在地面时的移动
					velocity.x += lerpf(velocity.x, direction.x * move_speed, move_rate*8) * delta
					velocity.x = clampf(velocity.x, -move_speed, move_speed)
				
				update_direction(direction)
			
		# 重力
		if gravity_enabled:
			velocity.y = lerpf(velocity.y, gravity_max, gravity_rate) 
			if _last_velocity.y < 0 and velocity.y > 0:
				fell.emit()
		
		# 跳跃
		if on_floor:
			_jump_last_time = 0.0
			_jump_count = 0
			_coyote_time = 0.0
		_jump_last_time += delta
		_coyote_time += delta
		_jump_buffer_time -= delta #开始倒计时跳跃缓冲
		if direction.y < 0:
			_jump_buffer_time = JUMP_BUFFER_TIME_MAX
		if _jump_buffer_time > 0:
			if on_floor or _coyote_time < COYOTE_TIME_MAX:
				if _jump_count == 0:
					jump(jump_heigth)
		
		# 实际移动
		role.velocity = velocity
		role.move_and_slide()
		on_floor = role.is_on_floor()
		
		# 更新状态和数据
		on_floor = role.is_on_floor()
		if on_floor or role.is_on_ceiling():
			velocity.y = 0
		_moving = direction.x != 0
		_last_move_direction = _move_direction
		_last_velocity = velocity
		
		moved.emit(velocity)
		
		# 摩擦力
		if direction.x == 0:
			if on_floor:
				# 在地面上时的摩擦力
				velocity.x = lerpf(velocity.x, 0, move_friction) 
			else:
				velocity.x = lerpf(velocity.x, 0, delta)
		
		_move_direction = Vector2.ZERO

func clear_jump_buffer() -> void:
	_jump_buffer_time = 0

func clear_jump_count() -> void:
	_jump_count = 0

func move_and_jump(direction: Vector2) -> void:
	update_direction(direction)
	_move_direction = direction
	_move_direction.x = sign(_move_direction.x)

func update_direction(direction: Vector2) -> void:
	if direction.x != 0 and _last_direction.x != sign(direction.x):
		_move_direction.x = 0
		_last_direction.x = sign(direction.x)
		direction_changed.emit(_last_direction)

func jump(height: float = 0) -> void:
	if jump_enabled:
		if height == 0:
			height = jump_heigth
		velocity.y = -height
		_jump_last_time = 0.0
		_jump_count += 1
		jumped.emit()

func stop():
	_move_direction = Vector2()
	_jump_buffer_time = 0
