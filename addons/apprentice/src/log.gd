#============================================================
#    Log
#============================================================
# - author: zhangxuetu
# - datetime: 2023-10-04 00:25:06
# - version: 4.1.1.stable
#============================================================
class_name Log


static func info(desc: String, data = "", format: String = ""):
	if format:
		if data is Dictionary:
			print(Time.get_datetime_string_from_system(), " ", desc, " ", JSON.stringify(data, format))
		elif data is Array:
			print(Time.get_datetime_string_from_system(), " ", desc, " ", format % data)
		else:
			print(Time.get_datetime_string_from_system(), " ", desc, " ", data)
			
	else:
		print(Time.get_datetime_string_from_system(), " ", desc, " ", data)


static func stringify(desc: String, data):
	info(desc, data, "  ")


static func debug(desc: String, data = "", indent: String = ""):
	info(desc, data, indent)
	print("  | {line}: {function}: {source} ".format( get_stack()[1] ))


static func error(desc: String, data = "", indent: String = ""):
	if indent:
		printerr(Time.get_datetime_string_from_system(), " ", desc, " ", JSON.stringify(data, indent))
	else:
		printerr(Time.get_datetime_string_from_system(), " ", desc, " ", data)

## 格式化输出内容。例：
##[codeblock]
##Log.format(["%-10s"], ["hello world", 1, 2, 3, ])
##[/codeblock]
static func format(format_str: Array, items: Array, indent: String = " "):
	if format_str.size() <= items.size():
		var item = format_str.back()
		for i in items.size() - format_str.size():
			format_str.push_back(item)
	print(indent.join(format_str) % items)

## 打印时间
static func print_time() -> void:
	print( Time.get_datetime_string_from_system(false, true))

## 打印结果
static func print_error(head: String, err: int):
	if err == OK:
		print("<", head, "> 成功：", ": ", err, "  ", error_string(err))
	else:
		printerr("<", head, "> 失败：", ": ", err, "  ", error_string(err))

static func json(data, indent: String = "\t"):
	print(JSON.stringify(data, indent))
