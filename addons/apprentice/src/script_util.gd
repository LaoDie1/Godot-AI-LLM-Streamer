#============================================================
#    Scirpt Util
#============================================================
# - author: zhangxuetu
# - datetime: 2022-07-17 17:25:00
#============================================================
## 处理脚本的工具
class_name ScriptUtil


const NAME_TO_DATA_TYPE = {
	&"null": TYPE_NIL,
	&"bool": TYPE_BOOL,
	&"int": TYPE_INT,
	&"float": TYPE_FLOAT,
	&"String": TYPE_STRING,
	&"Rect2": TYPE_RECT2,
	&"Vector2": TYPE_VECTOR2,
	&"Vector2i": TYPE_VECTOR2I,
	&"Vector3": TYPE_VECTOR3,
	&"Vector3i": TYPE_VECTOR3I,
	&"Transform2D": TYPE_TRANSFORM2D,
	&"Vector4": TYPE_VECTOR4,
	&"Vector4i": TYPE_VECTOR4I,
	&"Plane": TYPE_PLANE,
	&"Quaternion": TYPE_QUATERNION,
	&"AABB": TYPE_AABB,
	&"Basis": TYPE_BASIS,
	&"Transform3D": TYPE_TRANSFORM3D,
	&"Projection": TYPE_PROJECTION,
	&"Color": TYPE_COLOR,
	&"StringName": TYPE_STRING_NAME,
	&"NodePath": TYPE_NODE_PATH,
	&"RID": TYPE_RID,
	&"Object": TYPE_OBJECT,
	&"Callable": TYPE_CALLABLE,
	&"Signal": TYPE_SIGNAL,
	&"Dictionary": TYPE_DICTIONARY,
	&"Array": TYPE_ARRAY,
	&"PackedByteArray": TYPE_PACKED_BYTE_ARRAY,
	&"PackedInt32Array": TYPE_PACKED_INT32_ARRAY,
	&"PackedInt64Array": TYPE_PACKED_INT64_ARRAY,
	&"PackedStringArray": TYPE_PACKED_STRING_ARRAY,
	&"PackedVector2Array": TYPE_PACKED_VECTOR2_ARRAY,
	&"PackedVector3Array": TYPE_PACKED_VECTOR3_ARRAY,
	&"PackedFloat32Array": TYPE_PACKED_FLOAT32_ARRAY,
	&"PackedFloat64Array": TYPE_PACKED_FLOAT64_ARRAY,
	&"PackedColorArray": TYPE_PACKED_COLOR_ARRAY,
}


static var _global_data : Dictionary = {}
##  获取 Dictionary 数据
static func _singleton_dict(meta_key: StringName, default: Dictionary = {}) -> Dictionary:
	if _global_data.has(meta_key):
		return _global_data.get(meta_key)
	else:
		_global_data[meta_key] = default
		return default


static func _get_script_data_cache(script: Script) -> Dictionary:
	return _singleton_dict("ScriptUtil__get_script_data_cache")


## 获取字典的值，如果没有，则获取并设置默认值
##[br]
##[br][code]dict[/code]  获取的字典
##[br][code]key[/code]  key 键
##[br][code]not_exists_set[/code]  没有则返回值设置这个值。这个回调方法返回要设置的数据
static func _get_value_or_set(dict: Dictionary, key, not_exists_set: Callable = Callable()):
	if dict.has(key) and not typeof(dict[key]) == TYPE_NIL:
		return dict[key]
	else:
		if not_exists_set.is_valid():
			dict[key] = not_exists_set.call()
			return dict[key]

## 获取这个类名的类型
static func get_type_of(_class_name: StringName) -> int:
	return NAME_TO_DATA_TYPE.get(_class_name, -1)

## 是否是基础数据类型
static func is_base_data_type(_class_name: StringName) -> bool:
	return NAME_TO_DATA_TYPE.has(_class_name)


##  获取属性列表
##[br]
##[br]返回类似如下格式的数据
##[codeblock]
##{ 
##    "name": "RefCounted", 
##    "class_name": &"", 
##    "type": 0, 
##    "hint": 0, 
##    "hint_string": "", 
##    "usage": 128 
##}
##[/codeblock]
static func get_property_data_list(script: Script) -> Array[Dictionary]:
	if is_instance_valid(script):
		return script.get_script_property_list()
	return Array([], TYPE_DICTIONARY, "Dictionary", null)


## 获取属性名称列表
static func get_property_name_list(script: Script) -> Array[String]:
	var list : Array[String] = []
	if script != null:
		for data in get_property_data_list(script):
			if data["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE == PROPERTY_USAGE_SCRIPT_VARIABLE:
				list.append(data["name"])
	return list


##  获取方法列表
static func get_method_data_list(script: Script) -> Array[Dictionary]:
	if is_instance_valid(script):
		return script.get_script_method_list()
	return Array([], TYPE_DICTIONARY, "Dictionary", null)


## 获取方法的参数列表数据
static func get_method_arguments_list(script: Script, method_name: StringName) -> Array[Dictionary]:
	var data = get_method_data(script, method_name)
	if data:
		return data.get("args", Array([], TYPE_DICTIONARY, "Dictionary", null))
	return Array([], TYPE_DICTIONARY, "Dictionary", null)


##  获取信号列表
static func get_signal_data_list(script: Script) -> Array[Dictionary]:
	if is_instance_valid(script):
		return script.get_script_signal_list()
	return Array([], TYPE_DICTIONARY, "Dictionary", null)


## 获取这个属性名称数据
static func get_property_data(script: Script, property: StringName) -> Dictionary:
	var data = _get_script_data_cache(script)
	var p_cache_data : Dictionary = _get_value_or_set(data, "propery_data_cache", func():
		var property_data : Dictionary = {}
		for i in script.get_script_property_list():
			property_data[i['name']] = i
		return property_data
	)
	return p_cache_data.get(property, {})


## 获取这个名称的方法的数据
static func get_method_data(script: Script, method_name: StringName) -> Dictionary:
	var data = _get_script_data_cache(script)
	var m_cache_data : Dictionary = _get_value_or_set(data, "method_data_cache", func():
		var method_data : Dictionary = {}
		for i in script.get_script_method_list():
			method_data[i['name']]=i
		return method_data
	)
	return m_cache_data.get(method_name, {})


## 获取这个名称的信号的数据
static func get_signal_data(script: Script, signal_name: StringName):
	var data = _get_script_data_cache(script)
	var s_cache_data : Dictionary = _get_value_or_set(data, "script_data_cache", func():
		var signal_data : Dictionary = {}
		for i in script.get_script_signal_list():
			signal_data[i['name']]=i
		return signal_data
	)
	return s_cache_data.get(signal_name, {})


##  获取方法数据
## [br]
## [br]- [code]script[/code]  脚本
## [br]- [code]method[/code]  要获取的方法数据的方法名
## [br]- [code]return[/code]  返回脚本的数据信息.
##  包括的 key 有 [code]name[/code], [code]args[/code], [code]default_args[/code]
## , [code]flags[/code], [code]return[/code], [code]id[/code]
func find_method_data(script: Script, method: String) -> Dictionary:
	var method_data = script.get_script_method_list()
	for m in method_data:
		if m['name'] == method:
			return m
	return {}


##  获取扩展脚本链（扩展的所有脚本）
##[br]
##[br][code]script[/code]  Object 对象或脚本
##[br][code]return[/code]  返回继承的脚本路径列表
static func get_extends_link(script: Script) -> PackedStringArray:
	var list := PackedStringArray()
	while script:
		if FileUtil.file_exists(script.resource_path):
			list.push_back(script.resource_path)
		script = script.get_base_script()
	return list


##  获取基础类型继承链类列表
##[br]
##[br]- [code]_class[/code]  基础类型类名
##[br]- [code]return[/code]  返回基础的类名列表
static func get_extends_link_base(_class) -> PackedStringArray:
	if _class is Script:
		_class = _class.get_instance_base_type()
	elif _class is Object:
		_class = _class.get_class()
	
	var c = _class
	var list = []
	while c != "":
		list.append(c)
		c = ClassDB.get_parent_class(c)
	return PackedStringArray(list)


##  生成方法代码
##[br]
##[br]- [code]method_data[/code]  方法数据
##[br]- [code]return[/code]  返回生成的代码
static func generate_method_code(method_data: Dictionary) -> String:
	var temp := method_data.duplicate(true)
	var args := ""
	for i in temp['args']:
		var arg_name = i['name']
		var arg_type = ( type_string(i['type']) if i['type'] != TYPE_NIL else "")
		if arg_type.strip_edges() == "":
			arg_type = str(i['class_name'])
		if arg_type.strip_edges() != "":
			arg_type = ": " + arg_type
		args += "%s%s, " % [arg_name, arg_type]
	temp['args'] = args.trim_suffix(", ")
	if temp['return']['type'] != TYPE_NIL:
		temp['return_type'] = type_string(temp['return']['type'])
	
	if temp.has('return_type') and temp['return_type'] != "":
		temp['return_type'] = " -> " + str(temp['return_type'])
		temp['return_sentence'] = "pass\n\treturn super." + temp['name'] + "()"
	else:
		temp['return_type'] = ""
		temp['return_sentence'] = "pass"
	
	return "func {name}({args}){return_type}:\n\t{return_sentence}\n".format(temp)


##  获取对象的脚本
static func get_object_script(object: Object) -> Script:
	if object == null:
		return null
	if object is Script:
		return object
	return object.get_script() as Script


##  对象是否是 tool 状态
##[br]
##[br]- [code]object[/code]  返回这个对象的脚本是否是开启 tool 的状态
static func is_tool(object: Object) -> bool:
	var script = get_object_script(object)
	return script.is_tool() if script else false


## 获取对象的脚本路径，如果不存在脚本，则返回空的字符串
static func get_object_script_path(object: Object) -> String:
	var script = get_object_script(object)
	return script.resource_path if script else ""


##  获取这个对象的这个方法的信息
##[br]
##[br]- [code]object[/code]  对象
##[br]- [code]method_name[/code]  方法名
##[br]- [code]return[/code]  返回方法的信息
static func get_object_method_data(object: Object, method_name: StringName) -> Dictionary:
	if not is_instance_valid(object):
		return {}
	var script = get_object_script(object)
	if script:
		return get_method_data(script, method_name)
	return {}


## 获取这个信号的数据
static func get_object_signal_data(object: Object, signal_name: StringName) -> Dictionary:
	if not is_instance_valid(object):
		return {}
	var script = get_object_script(object)
	if script:
		return get_signal_data(script, signal_name)
	return {}


## 获取对象的属性数据
static func get_object_property_data(object: Object, proprety_name: StringName) -> Dictionary:
	if not is_instance_valid(object):
		return {}
	var script = get_object_script(object)
	if script:
		return get_property_data(script, proprety_name)
	return {}


##  获取内置类名称转为对象。比如将 [code]"Node"[/code] 字符串转为 [Node] 这种 [kbd]GDScriptNativeClass[/kbd] 类型数据
##[br]
##[br]- [param _class] 类名称
static func get_built_in_class(_class: StringName):
	if not ClassDB.class_exists(_class):
		return null
	var _class_db = _singleton_dict("ScriptUtil_get_built_in_class")
	return _get_value_or_set(_class_db, _class, func():
		var script = GDScript.new()
		script.source_code = "var type = " + _class
		if script.reload() == OK:
			var obj = script.new()
			_class_db[_class] = obj.type
			return _class_db[_class]
		else:
			push_error("错误的类名：", _class)
		return null
	)


## 根据类名返回类对象，比如
##[codeblock]
##var _class = ScriptUtil.get_script_class("Player") # 类对象
##var player = _class.new()
##[/codeblock]
static func get_script_class(_class: StringName):
	if ClassDB.class_exists(_class):
		return null
	var _class_db = _singleton_dict("ScriptUtil_get_script_class")
	return _get_value_or_set(_class_db, _class, func():
		var script = GDScript.new()
		script.source_code = "var type = " + _class
		if script.reload() == OK:
			var obj = script.new()
			_class_db[_class] = obj.type
			return _class_db[_class]
		else:
			push_error("错误的类名：", _class)
		return null
	)


## 字符串转为类对象
static func str_to_class(_class: StringName):
	if ClassDB.class_exists(_class):
		return get_built_in_class(_class)
	else:
		return get_script_class(_class)


##  获取对象的 Class 对象。如果是自定义类返回 [Script] 类；如果是内置类，则返回内置
##[kbd]GDScriptNativeClass[/kbd] 类
static func get_class_object(value) -> Variant:
	if value is Script:
		return value
	
	elif value is String or value is StringName:
		return str_to_class(value)
	
	elif value is Object:
		if not "script" in value:
			return value
		elif value["script"] != null:
			return value.get_script()
		else:
			var type := str(value)
			if type.begins_with("<GDScriptNativeClass#"):
				# 内部类 GDScriptNativeClass 对象
				return value
			return get_built_in_class(value.get_class())
	return null


## 是否有这个类
static func has_class(_class: StringName) -> bool:
	if ClassDB.class_exists(_class):
		return true
	else:
		var script = GDScript.new()
		script.source_code = "var type = " + _class
		return script.reload() == OK


## 获取对象类名 
static func get_class_name(value, cache: bool = true) -> StringName:
	if value is Object:
		if not value is Script:
			if value.get_script():
				value = value.get_script()
			else:
				return value.get_class()
		if value is Script:
			var script := value as Script
			while script and script.get_global_name() == &"":
				if script.get_base_script() == null:
					return script.get_class()
				script = script.get_base_script()
			return script.get_global_name()
		return &""
	else:
		return type_string(typeof(value))


## 获取这个类名称的实例对象
static func get_instance(_class_name: StringName) -> Object:
	var _class = str_to_class(_class_name)
	if _class:
		return _class.new()
	else:
		push_error("没有这个名称的类")
		return null

static func get_base_path(script:Script) -> String:
	return script.resource_path.get_base_dir()


##  属性是否存在 Setter 或 Getter 方法
##[br]
##[br]- [code]script[/code]  脚本
##[br]- [code]propertys[/code]  属性列表
##[br]- [code]return[/code]  返回结果会是以
##[codeblock]
##{
##    "property": {
##        "setter": true,
##        "getter": false,
##    }
##}
##[/codeblock]
##的结构返回
static func has_getter_or_setter(script: Script, propertys: PackedStringArray) -> Dictionary:
	var tmp_script = GDScript.new()
	tmp_script.source_code = script.source_code
	var map : Dictionary = {}
	for data in get_method_data_list(tmp_script):
		map[data["name"]] = null
	
	var result : Dictionary = {}
	for property in propertys:
		result[property] = {
			"setter": map.has("@%s_setter" % property) or map.has("set_%s" % property),
			"getter": map.has("@%s_getter" % property) or map.has("get_%s" % property),
		}
	return result


#============================================================
#  初始化类静态变量数据
#============================================================

##初始化类的静态变量值为自身的名称。用于方便添加静态属性，作为配置 key 使用。导出时需要设置脚本为“文本”的格式
##[br]
##[br]- [code]script[/code]  注入的脚本或脚本类 
##[br]- [code]handle_method[/code]  处理注入的方式。不传入这个参数默认设置值为对应的属性名字符串。
##这个方法需要接收 3 个参数:
##[br]      - [code]script[/code] : 接收对应类的脚本
##[br]      - [code]class_path[/code] : 类的路径
##[br]      - [code]property[/code] : 属性名
##[br]- [code]return[/code]  返回注入的属性名路径
##[br]
##[br]比如添加一个 [code]ConfigKey[/code] 类里面添加静态变量作为配置属性
##[codeblock]
##class_name ConfigKey
##
##class Path:
##    static var current_dir
##    static var opened_files
##[/codeblock]
##可以方便的通过传入 [code]ConfigKey.Path.current_dir[/code] 作为 key 获取配置属性值
static func init_static_var(script: Script, handle_method: Callable) -> void:
	if _inited_scripts.has(script):
		return
	
	_inited_scripts[script] = null
	# 获取数据并初始化
	var dict : Dictionary = parse_script_var(script)
	__init_static_var__(dict, handle_method, "/")

static var _inited_scripts : Dictionary = {}

static func __init_static_var__(dict: Dictionary, handle_method: Callable, path:String):
	var script := dict["script"] as Script
	
	# 初始化静态变量
	var v: Variant
	for item in dict["var"]:
		if item["static"]:
			v = handle_method.call(script, path, item["name"])
			# 如果方法返回的值为 null，则不注入
			if typeof(v) != TYPE_NIL:
				script.set(item["name"], v)
	
	# 子类
	for sub_class_item in dict["sub_class"]:
		var sub_path := path.path_join(sub_class_item["class"])
		__init_static_var__(sub_class_item, handle_method, sub_path)


## 解析脚本中的变量数据
static func parse_script_var(script: Script) -> Dictionary:
	var dict := {}
	__parse_script_var__(script, dict)
	return dict

static func __parse_script_var__(script: Script, dict: Dictionary, c_name: String = ""):
	dict["script"] = script
	dict["class"] = (script.get_global_name() if c_name == "" else c_name)
	dict["sub_class"] = []
	dict["const"] = []
	dict["var"] = []
	
	# 变量
	var list := []
	list.append_array(script.get_script_property_list())
	list.append_array(script.get_property_list())
	var obj = script.new()  # 会自动调用 _init 需要注意 
	for data in list:
		if data["name"] in obj and data["name"] != "script":
			data["static"] = (data["name"] in script) # 静态变量
			data["export"] = (data["usage"] & (PROPERTY_USAGE_SCRIPT_VARIABLE|PROPERTY_USAGE_DEFAULT) == (PROPERTY_USAGE_SCRIPT_VARIABLE|PROPERTY_USAGE_DEFAULT))
			dict["var"].append(data)
	
	# 常量
	var m := script.get_script_constant_map()
	var v
	for k in m:
		v = m[k]
		if v is Script:
			var d := {}
			dict["sub_class"].append(d)
			__parse_script_var__(v, d, k)
		else:
			dict["const"].append({
				"name": k,
				"type": typeof(v),
				"value": v,
			})

static var __global_class_update_time__ : int = -100
static var __global_child_class_dict__ : Dictionary = {} #所有子级
static var __global_class_struct__: Dictionary = {} #所有类型的子级及嵌套结构
static var __global_class_name_to_script_path__: Dictionary = {} #类名对应的脚本文件路径

static func __init_script_class_structure__() -> void:
	if OS.has_feature("editor"):
		if Time.get_ticks_usec() - __global_class_update_time__ >= 100:
			__global_child_class_dict__.clear()
			__global_class_struct__.clear()
			__global_class_name_to_script_path__.clear()
	
	if __global_child_class_dict__.is_empty():
		for item in ProjectSettings.get_global_class_list():
			__global_child_class_dict__[item["base"]] = {}
		for item in ProjectSettings.get_global_class_list():
			__global_child_class_dict__[item["base"]][item["class"]] = {}
		
		# 获取所有继承类
		var parent_class
		var current_class
		for item in ProjectSettings.get_global_class_list():
			parent_class = item["base"]
			current_class = item["class"]
			if __global_child_class_dict__.has(current_class):
				__global_child_class_dict__[parent_class][current_class] = __global_child_class_dict__[current_class]
			else:
				__global_child_class_dict__[parent_class][current_class] = {}
			__global_class_name_to_script_path__[current_class] = item["path"]
	
	if __global_class_struct__.is_empty():
		# 梳理继承关系
		for k in __global_child_class_dict__:
			if not __global_child_class_dict__[k].is_empty():
				__global_class_struct__[k] = __global_child_class_dict__[k]
		for k in __global_child_class_dict__:
			__global_child_class_dict__[k] = __global_child_class_dict__[k].keys()
		__global_class_update_time__ = Time.get_ticks_usec()

## 获取类继承的整个字典结构
static func get_script_class_structure() -> Dictionary:
	__init_script_class_structure__()
	return __global_class_struct__

## 获取脚本子类的字典
static func get_script_child_class_dict() -> Dictionary:
	__init_script_class_structure__()
	return __global_child_class_dict__

## 获取类名的脚本对象
static func get_script_by_class(class_name_: String) -> Script:
	__init_script_class_structure__()
	var path : String = __global_class_name_to_script_path__.get(class_name_, "")
	if path:
		return load(path)
	return null
