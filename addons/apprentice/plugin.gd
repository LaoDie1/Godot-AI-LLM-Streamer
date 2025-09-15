#============================================================
#    Plugin
#============================================================
# - datetime: 2022-08-28 23:28:30
#============================================================
@tool
class_name ApprenticePlugin
extends EditorPlugin


static var instance: ApprenticePlugin

var SyncFile = preload("res://addons/apprentice/@plugin_func/sync_file.gd").new()
var CustomMenu = preload("res://addons/apprentice/@plugin_func/custom_menu.gd").new()

var auto_upload_timer: Timer
var resource_queue: Dictionary = {}


func _enter_tree() -> void:
	instance = self
	SyncFile.plugin = self
	CustomMenu.enter()
	
	# 自动同步功能
	self.resource_saved.connect(resource_changed, Object.CONNECT_DEFERRED)
	auto_upload_timer = Timer.new()
	auto_upload_timer.wait_time = 2
	auto_upload_timer.one_shot = true
	auto_upload_timer.timeout.connect(
		func():
			if not resource_queue.is_empty():
				#print("[同步文件到根目录] ")
				for resource:Resource in resource_queue:
					SyncFile.upload_to_root(resource.resource_path)
				resource_queue.clear()
	)
	add_child.call_deferred(auto_upload_timer)
	
	var autoload_script = get_script().resource_path.get_base_dir().path_join("apprentice_autoload.gd")
	add_autoload_singleton("ApprenticeAutoload", autoload_script)


func _exit_tree() -> void:
	SyncFile.exit()
	CustomMenu.exit()
	if auto_upload_timer:
		auto_upload_timer.queue_free()
	remove_autoload_singleton("ApprenticeAutoload")


func resource_changed(resource: Resource):
	if resource:
		resource_queue[resource] = null
		auto_upload_timer.stop()
		auto_upload_timer.start.call_deferred()
