#============================================================
#    Nircmd Util
#============================================================
# - author: zhangxuetu
# - datetime: 2025-01-09 19:51:28
# - version: 4.3.0.stable
#============================================================
## 文档：https://www.nirsoft.net/utils/nircmd.html
class_name NircmdUtil

static var execute_path : String = ""


## 隐藏任务栏
static func win_hide_ititle(title: String):
	var params : PackedStringArray = ["win", "hide", "ititle", '"%s"' % title]
	var error : Dictionary = OS.execute_with_pipe(execute_path, params)
	#prints(error, " ".join(params))

## 显示任务栏
static func win_show_ititle(title: String):
	var params : PackedStringArray = ["win", "show", "ititle", '"%s"' % title]
	var error : Dictionary = OS.execute_with_pipe(execute_path, params)
	#prints(error, " ".join(params))
