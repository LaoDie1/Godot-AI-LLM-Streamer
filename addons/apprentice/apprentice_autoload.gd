#============================================================
#    Apprentice Autoload
#============================================================
# - author: zhangxuetu
# - datetime: 2025-05-26 22:28:26
# - version: 4.2.1
#============================================================
extends Node


func _init():
	# 设置所有继承 Autowired 类的脚本，初始化静态属性变量
	var dict = ScriptUtil.get_script_child_class_dict()
	for child_class in dict.get("Autowired", []):
		var script := ScriptUtil.get_script_by_class(child_class) as Script
		ScriptUtil.init_static_var(script, script._get_value)
	
	# 自动加载节点。自动添加到场景中
	for child_class in dict.get("AutoloadNode", []):
		var script := ScriptUtil.get_script_by_class(child_class) as Script
		if script and script.resource_path.is_empty() or ResourceLoader.exists(script.resource_path):
			var node := script.new() as AutoloadNode
			if script.get_global_name():
				node.name = script.get_global_name()
			Engine.get_main_loop().root.add_child(node, true)
	
