#============================================================
#    Role
#============================================================
# - author: zhangxuetu
# - datetime: 2025-05-11 16:04:24
# - version: 4.2.1
#============================================================
## 继承这个脚本和场景
class_name Role
extends Node2D


## 角色存在的状态类型
enum States {
	NORMAL, ##正常状态
	SKILL, ##施放技能状态
	UNCONTROL,  ##不可控制状态
	DEAD,  ##死亡状态
}

# < 标准属性 >

@export var body: CharacterBody2D
@export var canvas: Node2D

@export var properties : DynamicProperties
@export var states : StateNode
@export var inventory: DataManagement
@export var skill_actuator : SkillActuator
@export var move_component: RoleMoveComponent
@export var damage_component: DamageComponent

@export var uncontrollable_controller: UncontrollableController

var normal_state: StateNode
var skill_state: StateNode
var uncontrol_state: StateNode
var dead_state: StateNode


func _to_string():
	var script := get_script() as GDScript 
	var g_name : StringName = script.resource_path.get_basename().get_file().to_pascal_case()
	return "<%s#%d>" % [g_name, get_instance_id()]


func _notification(what):
	if what == NOTIFICATION_ENTER_TREE:
		# 添加以 p_ 头的属性为角色的 properties 的属性和默认值
		for p_data in (get_script() as Script).get_script_property_list():
			if p_data["usage"] & (PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT) == (PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT):
				if p_data["name"].begins_with("p_"):
					var p_name : String = str(p_data["name"]).trim_prefix("p_")
					properties.add(p_name, get(p_data["name"]))
		
		# 添加状态
		normal_state = states.add_state(Role.States.NORMAL)
		skill_state = states.add_state(Role.States.SKILL)
		uncontrol_state = states.add_state(Role.States.UNCONTROL)
		dead_state = states.add_state(Role.States.DEAD)


## 获取面向的方向
##[br]
##[br]- [param offset_distance]  以这个方向进行偏移的值
func get_face_direction(offset_distance: float = 1.0) -> Vector2:
	var direction = move_component.get_last_direction().sign()
	if direction == Vector2.ZERO:
		direction = [Vector2.LEFT, Vector2.RIGHT].pick_random()
	return direction * offset_distance

## 获取面向方向的一段距离的位置
func get_forward_position(distance: float = 0) -> Vector2:
	return (body.global_position + get_face_direction() * distance).round()

## 获取当前位置的偏移之后的位置
func get_body_position(offset: Vector2 = Vector2()) -> Vector2:
	return (body.global_position + offset).round()

func distance_to(target: Role) -> float:
	return body.global_position.distance_to(target.body.global_position)

func distance_squared_to(target: Role) -> float:
	return body.global_position.distance_squared_to(target.body.global_position)

func update_direction(direction) -> void:
	move_component.update_direction(direction)


func get_bodys(radius: float) -> Array[CollisionObject2D]:
	return Array(detect_circle_range(
		get_body_position(), 
		radius, 
		false, true, 1, 
		[ body.get_rid() ]
	).map(func(data):
		return data["collider"]
	).filter(func(body: Node2D):
		return body is CollisionObject2D and body.owner != self
	), TYPE_OBJECT, "CollisionObject2D", null)


## 角色漂浮文字
func float_text(
	text: String, 
	duration : float = 0.8,
):
	var label := ObjectUtil.get_pool_object(Label) as Label
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = text
	label.scale = Vector2(1, 1)
	label.global_position = canvas.global_position
	Engine.get_main_loop().current_scene.add_child(label)
	label.pivot_offset = label.get_rect().size / 2
	label.position.y -= 128
	
	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 100, duration)
	tween.parallel().tween_property(label, "modulate:a", 0, duration)
	var over_scale : Vector2 = label.scale * 0.3
	create_tween().tween_property(label, "scale", label.scale * 1.5, duration * 0.3).finished.connect(
		func():
			create_tween().tween_property(label, "scale", over_scale, duration * 0.6)
	)
	tween.finished.connect(
		func():
			ObjectUtil.retrieve_pool_object(label)
	)
	return label


## 检测圆形范围内的物理单位。数据结果格式详见 [method PhysicsDirectSpaceState2D.intersect_shape]
static func detect_circle_range(
	position: Vector2,
	radius : float,
	collide_with_areas: bool = true,
	collide_with_bodies: bool = true,
	collision_mask: int = 0xFFFFFFFF, 
	exclude: Array[RID] = [],
) -> Array[Dictionary]:
	var params := PhysicsShapeQueryParameters2D.new()
	params.collide_with_areas = collide_with_areas
	params.collide_with_bodies = collide_with_bodies
	params.collision_mask = collision_mask
	params.transform = Transform2D(0, position)
	params.exclude = exclude
	
	var circle := CircleShape2D.new()
	circle.radius = radius
	params.shape = circle
	var world := Engine.get_main_loop().current_scene.get_world_2d() as World2D
	var states := world.direct_space_state as PhysicsDirectSpaceState2D
	return states.intersect_shape(params)


## 获取这个节点所属的 [Role] 对象
static func find_role(node: Node) -> Role:
	if node:
		if node.owner is Role:
			return node.owner as Role
		elif node is Role:
			return node
		node = node.get_parent()
		while node and node.owner:
			node = node.get_parent()
		return node as Role
	return null
