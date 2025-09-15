#============================================================
#    Role Config Node
#============================================================
# - author: zhangxuetu
# - datetime: 2025-09-01 19:22:23
# - version: 4.4.1.stable
#============================================================
class_name RoleConfigNode 
extends Node

var role : Role


func _notification(what):
	if what == NOTIFICATION_ENTER_TREE:
		role = Role.find_role(self)

func get_state(state_name) -> StateNode:
	return role.states.get_state_or_add(state_name)
