#============================================================
#    Dynamic Properties
#============================================================
# - author: zhangxuetu
# - datetime: 2025-06-08 16:57:23
# - version: 4.4.1
#============================================================
##动态属性
class_name DynamicProperties
extends Node

## 新添加属性
signal newly_added_property(item: PropertyItem)
## 移除了属性
signal removed_property(item: PropertyItem)

var _property_to_value_dict: Dictionary[Variant, PropertyItem] = {}


## 获取所有属性项
func get_item_dict() -> Dictionary[Variant, PropertyItem]:
	return _property_to_value_dict

##获取所有属性项的数据值
func get_value_dict() -> Dictionary:
	var data := {}
	for p in _property_to_value_dict:
		data[p] = _property_to_value_dict[p].get_value()
	return data

func get_value(property, default : Variant = null) -> Variant:
	var value : Variant = get_item(property).get_value()
	if typeof(value) == TYPE_NIL:
		return default
	return value

## 获取这个属性项。
func get_item(property) -> PropertyItem:
	return _property_to_value_dict.get(property)

## 获取这个属性项。如果没有则自动添加。
func get_item_or_add(property, default = null) -> PropertyItem:
	if not _property_to_value_dict.has(property):
		return add(property, default)
	return _property_to_value_dict[property]

## 是否有这个属性项
func has_item(property) -> bool:
	return _property_to_value_dict.has(property)

## 初始化这个属性。添加这个字典中的所有 key 为属性
func init(data: Dictionary, emit_signal: bool = true) -> void:
	for property in data:
		add(property, data[property], emit_signal)

## 新增属性
func add(property, default = null, emit_signal: bool = true) -> PropertyItem:
	if not _property_to_value_dict.has(property):
		var item = PropertyItem.new(property, default)
		_property_to_value_dict[property] = item
		newly_added_property.emit(item)
	if typeof(default) != TYPE_NIL:
		_property_to_value_dict[property].set_value(default, emit_signal)
	return _property_to_value_dict[property]

## 移除属性
func remove(property) -> void:
	if _property_to_value_dict.has(property):
		var item = _property_to_value_dict[property]
		_property_to_value_dict.erase(property)
		self.removed_property.emit(item)


## 连接多个属性的信号到这个方法
func connect_multiple(propertys: Array, signal_name: StringName, method: Callable, flags: int = 0) -> void:
	var item: PropertyItem
	for property in propertys:
		item = get_item(property)
		if not item.is_connected(signal_name, method):
			item.connect(signal_name, method, flags)


## 取消连接多个属性的信号到这个方法
func disconnect_multiple(propertys: Array, signal_name: StringName, method: Callable) -> void:
	var item: PropertyItem
	for property in propertys:
		if has_item(property):
			item = get_item(property)
			if item.is_connected(signal_name, method):
				item.disconnect(signal_name, method)
