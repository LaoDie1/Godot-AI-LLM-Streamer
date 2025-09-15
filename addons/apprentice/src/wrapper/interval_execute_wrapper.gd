#============================================================
#    Interval Execute Wrapper
#============================================================
# - author: zhangxuetu
# - datetime: 2025-01-29 22:17:17
# - version: 4.4.0.beta1
#============================================================
## 间隔时间执行包装器
##
##防止执行过快，设置一个间隔时间，然后调用执行方法。注意执行的 Id 对应数据只会执行最后一次调用的数据，其他数据则不作效
##[codeblock]
##var executor := IntervalExecuteWrapper.new(
##    func(v):
##        # 执行的功能
##        print(v)
##        pass
##        ,
##    0.5
##)
##executor.execute([ "test" ])
##[/codeblock]
class_name IntervalExecuteWrapper


var interval: int = 0.2 ##间隔调用时间，执行时会在这个时间结束后，传入最后调用 [method execute] 时的参数到要执行的方法中

var _method: Callable
var _id_to_data_dict: Dictionary[Variant, Array] = {}


func _init(method:Callable, interval: float = 0.2):
	self.interval = interval
	self._method = method


func execute(data: Array = [], id = null) -> void:
	if _id_to_data_dict.has(id):
		_id_to_data_dict[id] = data
	else:
		_id_to_data_dict[id] = data
		await Engine.get_main_loop().create_timer(interval).timeout
		_method.callv(_id_to_data_dict[id])
		_id_to_data_dict.erase(id)
