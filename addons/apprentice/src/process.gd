#============================================================
#    Process
#============================================================
# - author: zhangxuetu
# - datetime: 2025-05-29 19:06:11
# - version: 4.2.1
#============================================================

### 格式：
##[codeblock]
##var process = Process.create_physics_frame(func(): pass) \ # 基本配置方法
##    .one_shot() # 执行方法(具体)
##process.stop()
##
### 执行一次结束
##Process.create_physics_frame(func(): pass).one_shot(false) 
### 每帧都执行，持续 / 秒后束
##Process.create_physics_frame(func(): pass).frame(1.0)
### 在 / 秒后执行一次结束
##Process.create_physics_frame(func(): pass).timout(1.0)
### 每 / 秒执行一次，共执行2次后结束，消耗时间 2.0 秒
##Process.create_physics_frame(func(): pass).interval(1.0, 2, 2.0)
##[/codeblock]
class_name Process
extends Node


var _process_method: Callable
var _items: Array[__Item_Base__] = []

var _timer_process_callback: Timer.TimerProcessCallback

func _init(timer_process_callback: Timer.TimerProcessCallback):
	self._timer_process_callback = timer_process_callback
	Engine.get_main_loop().root.add_child.call_deferred(self)

func _ready():
	match _timer_process_callback:
		Timer.TIMER_PROCESS_PHYSICS:
			set_physics_process(true)
			set_process(false)
			self.name = "PhysicsProcess"
		
		Timer.TIMER_PROCESS_IDLE:
			set_physics_process(false)
			set_process(true)
			self.name = "IdleProcess"

func _physics_process(delta):
	for item in _items:
		item._execute(delta)

func _process(delta):
	for item in _items:
		item._execute(delta)

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		stop()

func stop() -> void:
	set_physics_process(false)
	set_process(false)
	for item in _items:
		item.stop()
	_items.clear()
	if not is_queued_for_deletion():
		self.queue_free()


#============================================================
#  功能执行类
#============================================================
class __Item_Base__ extends ProcessItem:
	pass


class __Item_OneShot__ extends __Item_Base__:
	var _deferred: bool = false
	
	func _execute(delta):
		if _deferred:
			_method.call_deferred()
		else:
			_method.call()
		finished.emit()
		stop()


class __Item_Frame__ extends __Item_Base__:
	func _execute(delta):
		_method.call()
		_timeleft -= delta
		if _timeleft <= 0:
			finished.emit()
			stop()


class __Item_Timeout__ extends __Item_Base__:
	func _execute(delta):
		_timeleft -= delta
		if _timeleft <= 0:
			_method.call()
			finished.emit()
			stop()


class __Item_Fragment__ extends __Item_Base__:
	var _max_count: int = 0
	var _interval: float = 0.0
	var _duration: float = INF
	
	func _execute(delta):
		_timeleft -= delta
		if _timeleft <= 0:
			_method.call()
			finished.emit()
			_max_count -= 1
			if _max_count == 0:
				stop()
				return
			_timeleft += _interval
		
		_duration -= delta
		if _duration <= 0:
			stop()
			return


#============================================================
#  创建方法
#============================================================
var _method: Callable

func _bind_erase(item: __Item_Base__) -> void:
	_items.erase(item)

static func create_process_type(method: Callable = Callable()) -> Process:
	var process := Process.new(Timer.TIMER_PROCESS_IDLE) as Process
	process._method = method
	return process

## 创建一个物理线程节点，这个方法没有参数。
static func create_physics_type(method: Callable = Callable()) -> Process:
	var process = Process.new(Timer.TIMER_PROCESS_PHYSICS)
	process._method = method
	return process

func one_shot(deferred: bool = false) -> ProcessItem:
	var item := __Item_OneShot__.new()
	item._deferred = deferred
	item._method = _method
	item.ended.connect(_bind_erase.bind(item))
	_items.append(item)
	return item

func frame(time: float) -> ProcessItem:
	var item := __Item_Frame__.new()
	item._timeleft = time
	item._method = _method
	item.ended.connect(_bind_erase.bind(item))
	_items.append(item)
	return item

func timout(time: float) -> ProcessItem:
	var item := __Item_Timeout__.new()
	item._timeleft = time
	item._method = _method
	item.ended.connect(_bind_erase.bind(item))
	_items.append(item)
	return item

func fragment(interval: float, max_count: int = -1, time: float = INF) -> ProcessItem:
	var item := __Item_Fragment__.new()
	item._method = _method
	item._timeleft = interval
	item._interval = interval
	item._max_count = max_count
	item._duration = time
	item.ended.connect(_bind_erase.bind(item))
	_items.append(item)
	return item
