#============================================================
#    Map Room Generator
#============================================================
# - author: zhangxuetu
# - datetime: 2025-06-02 20:57:27
# - version: 4.4.1.stable
#============================================================
## 生成的房间信息和基本的砖块瓦片。只要设置 [member group] 属性选择一个父节点，在其下边
##添加 [enum Type] 枚举里相同名称的节点，在其下边添加相同地图房间大小的预设房间地图即可
class_name MapRoomGenerator
extends Node2D

enum Type {
	LEFT_RIGHT, ## 左右有通路的房间
	AROUND, ## 四周都有通路
	DOWN_LEFT_RIGHT, ## 顶部的房间
	TOP_LEFT_RIGHT, ## 底部的房间
}

## 地图大小
@export var map_size: Vector2i = Vector2i(3, 3)
## 生成地图种子数
@export var seed_number : int = 0
## 地图瓦片的 ID
@export var wall_id : int = 1
## 基础模板节点，用于获取整个房间大小。可以在地图的四个角落设置一个瓦片即可
@export var base_template_map: TileMapLayer
## 地图类型分类的父节点。子节点的名字需要和上面 Type 枚举的名字保持一致
@export var group: Node
## 输出显示到的地图节点
@export var display_map: TileMapLayer
## 显示网格线
@export var show_grid_line: bool = false:
	set(v):
		show_grid_line = v
		queue_redraw()
## 显示房间信息
@export var show_room_info: bool = false:
	set(v):
		show_room_info = v
		if not map_room_dict.is_empty():
			for coord in map_room_dict:
				var label := map_room_dict[coord].get("label") as Label
				if label == null:
					label = Label.new()
					add_child(label)
					map_room_dict[coord]["label"] = label
				label.text = JSON.stringify(map_room_dict[coord], "\t")
				label.position = coord * base_template_map.get_used_rect().size * base_template_map.tile_set.tile_size + Vector2i(64, 64)
				label.visible = show_room_info

var random_number_generator := StableRandomGenerator.new()

var type_to_rooms_dict := {} #房间类型对应的地图节点列表
var map_room_dict := {} #地图里的房间的信息

var passway_tile := {} #能够移动到达的瓦片
var floor_tile := {} #地面瓦片
var ceil_tile := {} #天花板上的瓦片
var noway_tile := {} #无法到达的瓦片

func _ready() -> void:
	# 房间节点类型表
	for type in group.get_children():
		var key = str(type.name).to_upper()
		if Type.has(key):
			type_to_rooms_dict[Type[key]] = type.get_children()
	
	# 随机种子
	if seed_number == 0:
		seed_number = randi_range(0, 99999)
	random_number_generator.seed = seed_number
	print_debug("随机种子数：%d" % seed_number)
	
	# 开始生成
	generate(map_size)
	
	# 瓦片添加到场景中
	display_map.clear()
	display_map.show()
	var room_rect := base_template_map.get_used_rect()
	for coords in map_room_dict:
		var map = map_room_dict[coords]["map"]
		var to_room_rect = room_rect
		to_room_rect.position = coords * room_rect.size + Vector2i.ONE
		TileMapUtil.copy_cell_to(map, room_rect, display_map, to_room_rect)
	
	# 设置生成地图围绕一圈无法出去的墙
	room_rect.size *= map_size
	room_rect.size += Vector2i(1, 0)
	FuncUtil.for_rect_around(room_rect, display_map.set_cell.bind(wall_id, Vector2i()))


func _draw():
	if show_grid_line:
		var room_size = base_template_map.get_used_rect().size
		var tile_size = base_template_map.tile_set.tile_size
		var room_grid_size = room_size * tile_size
		var offset = Vector2(64, 64) #网格偏移
		
		# 房间网格
		for x in map_size.x + 1:
			draw_line(Vector2(x * room_grid_size.x, 0) + offset, Vector2(x * room_grid_size.x, room_grid_size.y * map_size.y) + offset, Color.WHITE)
		for y in map_size.y + 1:
			draw_line(Vector2(0, y * room_grid_size.y) + offset, Vector2(room_grid_size.x * map_size.x, y * room_grid_size.y) + offset, Color.WHITE)
		
		# 瓦片网格
		for x in room_size.x * map_size.x + 1:
			draw_line(Vector2(x * tile_size.x, 0) + offset, Vector2(x * tile_size.x, room_grid_size.y * map_size.y) + offset, Color(1,1,1,0.2))
		for y in room_size.y * map_size.y + 1:
			draw_line(Vector2(0, y * tile_size.y) + offset, Vector2(room_grid_size.x * map_size.x, y * tile_size.y) + offset, Color(1,1,1,0.2))


## 开始生成地图
func generate(size: Vector2i):
	map_room_dict = {}
	var room_id = 0
	for y in range(size.y):
		for x in range(size.x):
			map_room_dict[Vector2i(x, y)] = {
				"id": room_id,
				"coord": Vector2i(x, y),
			}
			room_id += 1
	
	# 生成房间和其房间类型
	generate_room_type(map_room_dict, size)
	
	# 设置随机对应类型的房间的地图
	var type
	var map : TileMapLayer
	for coords in map_room_dict:
		type = map_room_dict[coords]["type"]
		map = random_number_generator.pick_random(type_to_rooms_dict[type])
		map_room_dict[coords]["map"] = map
		map_room_dict[coords]["type_string"] = Type.keys()[type]
	
	if show_grid_line:
		queue_redraw()
	self.show_room_info = show_room_info


## 生成整个地图的每个位置房间的类型
func generate_room_type(data: Dictionary, size: Vector2i):
	# 每行的房间随机设置几个带有向下移动通道的房间
	var room_columns := range(size.x)
	var coords := Vector2i()
	for line in range(0, size.y):
		#重新打乱这行的房间顺序
		var tmp_idx : int = -1
		var tmp_value = null
		for i in ceili(room_columns.size()/2):
			tmp_value = room_columns[i]
			tmp_idx = random_number_generator.randi() % room_columns.size()
			room_columns[i] = room_columns[tmp_idx]
			room_columns[tmp_idx] = tmp_value
		
		# 设置当前行的随机几个可以上下有通过的路口的房间
		var number : int = max(1, random_number_generator.randi_range(1, int(size.x * 0.3)))
		for i in number:
			coords = Vector2i(room_columns[i], line)
			if line == 0: # 第一行时
				data[coords]["type"] = Type.DOWN_LEFT_RIGHT
			elif line == size.y - 1: # 最后一行时
				data[coords]["type"] = Type.TOP_LEFT_RIGHT
			else: # 其他房间
				data[coords]["type"] = Type.AROUND
	
	var down_coords := Vector2i()
	var up_coords := Vector2i()
	for y in range(size.y):
		for x in range(size.x):
			coords = Vector2i(x, y)
			if not data[coords].has("type"):
				# 底部的房间
				down_coords = coords + Vector2i.DOWN
				if data.has(down_coords) and data[down_coords].has("type"):
					if data[down_coords]["type"] in [Type.AROUND, Type.TOP_LEFT_RIGHT]:
						data[coords]["type"] = Type.DOWN_LEFT_RIGHT
				
				# 顶部的房间
				up_coords = coords + Vector2i.UP
				if data.has(up_coords) and data[up_coords].has("type"):
					if data[up_coords]["type"] in [Type.AROUND, Type.DOWN_LEFT_RIGHT]:
						data[coords]["type"] = Type.TOP_LEFT_RIGHT
				
				# 其他类型则为左右普通房间
				if not data[coords].has("type"):
					data[coords]["type"] = Type.LEFT_RIGHT
	
