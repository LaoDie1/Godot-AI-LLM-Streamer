#============================================================
#    Uncontrollable Controller
#============================================================
# - author: zhangxuetu
# - datetime: 2025-09-01 22:48:11
# - version: 4.4.1.stable
#============================================================
class_name UncontrollableController
extends Node

@export var role: Role

var _stopped : bool = true
var _timeleft : float = 0.0


func _ready():
	role.uncontrol_state.entered_state.connect(
		func():
			_stopped = false
			var data : Dictionary = role.uncontrol_state.get_last_data()
			_timeleft = data.get("stun_time", 0)
	)
	role.uncontrol_state.state_processed.connect(
		func():
			_timeleft -= get_physics_process_delta_time()
			if _timeleft <= 0:
				stop()
	)
	role.uncontrol_state.exited_state.connect(stop)


func start(data: Dictionary):
	assert(data.has("stun_time"), "必须设置硬直时间")
	if not role.uncontrol_state.is_running():
		role.uncontrol_state.trans_to_self(data)
	else:
		_timeleft = maxf(data["stun_time"], _timeleft)


func stop():
	if not _stopped:
		_stopped = true
		_timeleft = 0.0
		if role.uncontrol_state.is_running():
			role.normal_state.trans_to_self()
