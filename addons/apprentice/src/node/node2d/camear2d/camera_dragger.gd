#============================================================
#    Camera Dragger
#============================================================
# - author: zhangxuetu
# - datetime: 2023-07-04 23:55:04
# - version: 4.0
#============================================================
## 相机拖拽器
class_name CameraDragger
extends BaseCameraDecorator


enum UpdateProperty{
	OFFSET,
	POSITION,
}

## 当前缩放
@export var current_zoom_scale : float = 0:
	set(v):
		current_zoom_scale = v
		if not is_inside_tree():
			await ready
		current_zoom_scale = clampf(current_zoom_scale, min_zoom_scale, max_zoom_scale)
		var zoom = pow(2, current_zoom_scale)
		if camera:
			camera.zoom = Vector2(zoom, zoom)
## 最小缩放值
@export var min_zoom_scale : float = -5
## 最大缩放值
@export var max_zoom_scale : float = 5.0
## 更新的属性值
@export var update_property: UpdateProperty:
	set(v):
		update_property = v
		match update_property:
			UpdateProperty.OFFSET: _update_property = "offset"
			UpdateProperty.POSITION: _update_property = "position"

var dragging : bool = false
var last_mouse_pos : Vector2
var last_camera_pos : Vector2
var _update_property: String = "offset"

func _ready():
	self.current_zoom_scale = current_zoom_scale


func _input(event):
	if event is InputEventMouseMotion:
		if dragging:
			camera[_update_property] = last_camera_pos + -(camera.get_global_mouse_position() - last_mouse_pos)
			last_mouse_pos = camera.get_global_mouse_position()
			last_camera_pos = camera[_update_property]
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
			last_mouse_pos = camera.get_global_mouse_position()
			last_camera_pos = camera[_update_property]
	
	var down_or_up = InputUtil.get_mouse_wheel(event)
	if down_or_up != 0:
		current_zoom_scale -= 0.5 * down_or_up
	
