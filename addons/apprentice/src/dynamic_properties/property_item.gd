#============================================================
#    Property Item
#============================================================
# - author: zhangxuetu
# - datetime: 2024-06-12 13:24:41
# - version: 4.3.0.beta1
#============================================================
##属性项。监听属性的值发生的变化。
class_name PropertyItem
extends RefCounted

##  数据发生改变
##[br]- [param previous]  改变前的数据值
##[br]- [param current]  改变后的当前的数据值
signal property_changed(previous, current)

var _property
var _value: Variant = null

func _init(property, default = null):
	_property = property
	_value = default

func _to_string():
	var s_name = get_script().get_global_name()
	var id = get_instance_id()
	return "<%s#%d>" % [s_name, id]

## 设置值。如果参数 [param emit_signal] 值为 [code]true[/code] 则会发出属性改变信号。
func set_value(value, emit_signal: bool = true) -> void:
	if typeof(_value) != typeof(value) or _value != value:
		if emit_signal:
			var previous = _value
			_value = value
			property_changed.emit(previous, _value)
		else:
			_value = value

## 添加值。[kbd]+[/kbd] 运算
func add_value(value) -> void:
	if typeof(_value) != TYPE_NIL:
		set_value(_value + value)
	else:
		set_value(value)

## 减去值。[kbd]-[/kbd] 运算
func sub_value(value) -> void:
	add_value(-value)

## 乘以值。[kbd]*[/kbd] 运算
func mul_value(value) -> void:
	set_value(_value * value)

## 除以值。 [kbd]/[/kbd] 运算
func div_value(value) -> void:
	set_value(_value / value)

## 与运算。传入的值需要是 [int] / [bool] 值
func and_value(value) -> void:
	if value is int:
		set_value(get_int() & value)
	elif value is bool:
		set_value(get_bool() and value)
	else:
		set_value(value)

## 或运算。传入的值需要是 [int] / [bool] 值
func or_value(value) -> void:
	if value is int:
		set_value(int(_value) | value)
	elif value is bool:
		set_value(bool(_value) or value)
	else:
		set_value(value)

## 拿取值，如果拿取的值超出原来的值，则返回剩余的值
func take_value(value: float) -> float:
	if not is_zero_approx(value):
		if _value >= value:
			set_value(_value - value)
		else:
			value = _value
			set_value(0)
		return value
	return _value

## 值是否相同。只对值进行比较。引用数据根据 [method @GlobalScope.hash] 值进行断
func equals(value) -> bool:
	return typeof(value) == typeof(_value) and hash(value) == hash(_value)

## 值是否是 [code]null[/code]
func is_null() -> bool:
	return typeof(_value) == TYPE_NIL

## 是否为空的数据
func is_empty() -> bool:
	var type := typeof(_value)
	return (
		type == TYPE_NIL 
		or (
			type in [
				TYPE_ARRAY,
				TYPE_DICTIONARY,
				TYPE_STRING,
				TYPE_STRING_NAME,
				TYPE_NODE_PATH,
				TYPE_PACKED_BYTE_ARRAY,
				TYPE_PACKED_INT32_ARRAY,
				TYPE_PACKED_INT64_ARRAY,
				TYPE_PACKED_FLOAT32_ARRAY,
				TYPE_PACKED_FLOAT64_ARRAY,
				TYPE_PACKED_STRING_ARRAY,
				TYPE_PACKED_VECTOR2_ARRAY,
				TYPE_PACKED_VECTOR3_ARRAY,
				TYPE_PACKED_COLOR_ARRAY,
				TYPE_PACKED_VECTOR4_ARRAY,
			] and _value.is_empty()
		)
		or (type in [TYPE_FLOAT, TYPE_INT] and is_zero_approx(_value))
	)

## 值为零
func is_zero() -> bool:
	return (_value is float or _value is int) and is_zero_approx(_value)

## 自动增加
func incr(value: int = 1) -> int:
	if typeof(_value) not in [TYPE_INT, TYPE_FLOAT]:
		_value = 0
	set_value(_value + value, true)
	return _value

## 自动减少
func decr(value: int = 1) -> int:
	if typeof(_value) not in [TYPE_INT, TYPE_FLOAT]:
		_value = 0
	set_value(_value - value, true)
	return _value

## 值为 [/code]true[/code]
func is_true() -> bool:
	return _value is bool and _value

## 获取当前对象的属性
func get_property_name():
	return _property

##获取这个属性当前的值
func get_value() -> Variant:
	return _value

## 获取数据。如果数据为 [code]null[/code]，则自动添加默认值并返回
func get_or_add(default = null) -> Variant:
	if typeof(_value) != TYPE_NIL:
		_value = default
	return _value

## 以 [bool] 类型返回这个值
func get_bool() -> bool:
	return bool(_value) if _value else false

## 以 [float] 类型返回这个值
func get_float() -> float:
	return float(_value) if _value else 0.0

## 以 [int] 类型返回这个值
func get_int() -> int:
	return int(_value) if _value else 0

## 以 [String] 类型返回这个值
func get_string() -> String:
	return str(_value) if _value else ""

# 类型化数组和字典中的对应类名的脚本信息
static var __class_to_script_path_dict__ : Dictionary = {}
static func __find_script_path__(_class_name: String) -> String:
	if not __class_to_script_path_dict__.has(_class_name):
		for d in ProjectSettings.get_global_class_list():
			if d["class"] == _class_name:
				__class_to_script_path_dict__[_class_name] = d["path"]
				return d["path"]
	return __class_to_script_path_dict__.get(_class_name, "")

## 以 [Array] 类型返回这个值。如果传入的参数不为 [code]null[/code]，则返回类型化数组。
##[br] - [param type] 的值可以是 [enum Variant.Type]、类名或者脚本类
func get_array(type = null) -> Array:
	if typeof(_value) == TYPE_NIL:
		# 如果当前的值为 null 则设置默认值空数组
		_value = []
	
	if typeof(type) == TYPE_NIL:
		# 获取的数组没有类型，则直接返回这个值
		return _value
	
	if type is int:
		_value = Array(_value, type, &"", null)
	elif type is String or type is StringName:
		if ClassDB.class_exists(type):
			_value = Array(_value, TYPE_OBJECT, type, null)
		else:
			var path : String = __find_script_path__(type)
			if path:
				var script : Script = load(path)
				_value = Array(_value, TYPE_OBJECT, script.get_instance_base_type(), script)
			else:
				push_error("不存在的类 %s" % type)
	elif type is Script:
		_value = Array(_value, TYPE_OBJECT, type.get_instance_base_type(), type)
	
	return _value

## 以 [Dictionary] 类型返回这个值。如果传入的参数不为 [code]null[/code]，则返回类型化数组
func get_dictionary(key_type = null, value_type = null) -> Dictionary:
	if key_type == null and value_type == null:
		return Dictionary(_value)
	else:
		var _key_type: int = TYPE_NIL
		var _key_class_name: StringName = &""
		var _key_script: Script = null
		if key_type is String or key_type is StringName:
			_key_type = TYPE_OBJECT
			_key_class_name = key_type
			if not ClassDB.class_exists(_key_class_name):
				var script_path : String = __find_script_path__(_key_class_name)
				if script_path:
					_key_script = load(script_path)
		if key_type is Script:
			_key_type = TYPE_OBJECT
			_key_class_name = key_type.get_instance_base_type()
			_key_script = key_type
		
		var _value_type: int = TYPE_NIL
		var _value_class_name: StringName = &""
		var _value_script: Script = null
		if value_type is String or value_type is StringName:
			_value_type = TYPE_OBJECT
			_value_class_name = value_type
			if not ClassDB.class_exists(_value_class_name):
				var script_path : String = __find_script_path__(_value_class_name)
				if script_path:
					_value_script = load(script_path)
		if value_type is Script:
			_value_type = TYPE_OBJECT
			_value_class_name = value_type.get_instance_base_type()
			_value_script = value_type
		
		_value = Dictionary(_value, _key_type, _key_class_name, _key_script, _value_type, _value_class_name, _value_script)
	return _value
