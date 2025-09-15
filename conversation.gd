#============================================================
#    Conversation
#============================================================
# - author: zhangxuetu
# - datetime: 2025-01-06 14:49:17
# - version: 4.3.0.stable
#============================================================
## Chat 聊天的对话
##
##处理对话内容，并处理数据
class_name Conversation
extends Node


signal requested(message_data: Dictionary) ##已发出请求
signal responded_message(message_data: Dictionary) ##已响应请求结果
signal responded_stream_data(delta_data: Dictionary) ##每帧的流数据
signal responded_stream_end(message_data: Dictionary) ##数据流结束
signal responded_error(error_data: Dictionary)
signal saved ##已保存


const Role = {
	SYSTEM = "system",
	ASSISTANT = "assistant",
	USER = "user",
}
const ResponseFormat = {
	TEXT = "text",
	JSON_OBJECT = "json_object",
}

@export var base_url : String = ""
@export var model: String = ""
@export var api_key: String = ""

@export var saved_propertys : PackedStringArray = []

@export var stream: bool = false ##是否开启流输出
@export var tool_mode : bool = false ## 如果为工具模式，则没有上下文，只有第一个消息和最后一个消息会被发送
@export_multiline var tool_message: String ##工具模式的提示词
@export var messages: Array[Dictionary] = []  ##所有消息
@export_global_dir var file_path: String

var _http_request: HTTPRequest
var _stream_request: StreamRequest
var _is_running: bool = false
var _delta_datas : Dictionary = {}


func _init() -> void:
	_http_request = HTTPRequest.new()
	_http_request.request_completed.connect(_request_completed)
	
	_stream_request = StreamRequest.new()
	_stream_request.responded.connect(_response_stream_data)
	_stream_request.connect_closed.connect(_response_stream_end)
	_stream_request.responded_error.connect(
		func(status):
			_response_stream_end()
			HTTPClient.STATUS_BODY
	)
	
	# 添加http请求节点
	var root: SceneTree = Engine.get_main_loop()
	if root.current_scene:
		root.current_scene.add_child.call_deferred(_http_request)
		root.current_scene.add_child.call_deferred(_stream_request)
	else:
		root.process_frame.connect(
			func(): 
				if is_instance_valid(self):
					root.current_scene.add_child(_http_request)
					root.current_scene.add_child(_stream_request)
				,
			Object.CONNECT_ONE_SHOT
		)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(_stream_request):
			_stream_request.queue_free()
			_http_request.queue_free()


## 发送请求
func send(message: String) -> void:
	if is_running():
		push_error("正在运行中，在此期间不能发送")
		return
	
	_delta_datas = {}
	message = message.strip_edges()
	assert(message != "", "消息数据不能为空")
	while not _http_request or not _http_request.is_inside_tree():
		await Engine.get_main_loop().process_frame
	
	# 当前数据
	var message_data : Dictionary = {
		"role": Role.USER,
		"content": message,
	}
	messages.push_back(message_data)
	
	# 数据列表
	var temp_message : Array = []
	if tool_mode:
		# 工具模式.无上下文
		temp_message.push_back({
			"role": Role.SYSTEM,
			"content": tool_message,
		})
		temp_message.push_back(message_data)
	else:
		# 带有上下文
		var last_role = ""
		for item in messages:
			if last_role != item["role"]:
				last_role = item["role"]
				temp_message.push_back({
					"role": item["role"],
					"content": item["content"],
				})
	
	# 发出时的数据
	var body : Dictionary = {
		"messages": temp_message,
		"model": model,
		"stream": stream,
	}
	requested.emit(message_data)
	
	# 开始正式请求数据
	var body_json : String = JSON.stringify(body)
	var headers : Array = [
		"Content-Type: application/json",
		"Authorization: Bearer " + api_key,
	]
	if stream:
		_stream_request.close()
		_stream_request.request(base_url, headers, HTTPClient.METHOD_POST, body_json)
	else:
		_http_request.request(base_url, headers, HTTPClient.METHOD_POST, body_json)


## 停止响应
func stop() -> void:
	if stream:
		if _stream_request.is_connected:
			_stream_request.close()
	else:
		if _http_request.get_http_client_status() == HTTPClient.STATUS_REQUESTING:
			_http_request.cancel_request()


## 是否正在运行
func is_running() -> bool:
	if stream:
		return _stream_request.is_connected
	else:
		return _http_request.get_http_client_status() == HTTPClient.STATUS_REQUESTING


## 保存会话资源。不传入 path 参数，则默认按照当前 file_path 的路径进行保存 
func save(path: String = "") -> String:
	assert(path != "" or file_path != "", "文件名不能为空")
	if path != "":
		self.file_path = path
	
	# 导出的数据
	if saved_propertys.is_empty():
		const EXPORT_USAGE = PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT
		var property : String
		for item in get_script().get_script_property_list():
			if item['usage'] & EXPORT_USAGE == EXPORT_USAGE:
				property = item["name"]
				saved_propertys.push_back(property)
	
	# 属性数据
	var data : Dictionary = {}
	for property in saved_propertys:
		data[property] = get(property)
	
	# 保存
	FileUtil.write_as_var(file_path, data)
	saved.emit()
	return file_path


## 加载会话文件
static func load(path: String) -> Conversation:
	var res: Conversation
	res = Conversation.new()
	res.file_path = path
	if FileUtil.file_exists(path):
		# 设置属性数据
		var data : Dictionary = FileUtil.read_as_var(path)
		for property in data:
			res.set(property, data[property])
	return res


func _handle_data(data: Dictionary) -> Dictionary:
	if data:
		var choices : Dictionary = data["choices"][0]
		if choices.has("message"):
			return choices["message"]
		elif choices.has("delta"):
			return choices["delta"]
	return {}


# #响应结果结构：https://api-docs.deepseek.com/zh-cn/api/create-chat-completion
#{
#  "id": "30230b91-db94-4e74-bd24-8ca4ab13b4fa",
#  "object": "chat.completion",
#  "created": 1736317458,
#  "model": "deepseek-chat",
#  "choices": [
#    {
#      "index": 0,
#      "message": {
#        "role": "assistant",
#        "content": "Hello! How can I assist you today? 😊"
#      },
#      "logprobs": null,
#      "finish_reason": "stop"
#    }
#  ],
#  "usage": {
#    "prompt_tokens": 9,
#    "completion_tokens": 11,
#    "total_tokens": 20,
#    "prompt_cache_hit_tokens": 0,
#    "prompt_cache_miss_tokens": 9
#  },
#  "system_fingerprint": "fp_3a5770e1b4"
#}
func _request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var v : String = body.get_string_from_utf8()
	var json : JSON = JSON.new()
	if json.parse(v) == OK:
		var data = json.data
		if data.has("error"):
			responded_error.emit(data["error"])
		else:
			var message : Dictionary = _handle_data(data)
			messages.push_back(message)
			responded_message.emit(message)


#{
#	"choices": [
#		{
#			"delta": {
#				"content": "",
#				"reasoning_content": "",
#				"role": "assistant"
#			},
#			"finish_reason": null,
#			"index": 0.0,
#			"logprobs": null
#		}
#	],
#	"created": 1736317939.0,
#	"id": "3e454c66-8805-4563-a807-e7e2aebfdece",
#	"model": "deepseek-chat",
#	"object": "chat.completion.chunk",
#	"system_fingerprint": "fp_3a5770e1b4"
#}
func _response_stream_data(body_chunk: PackedByteArray):
	var text : String = body_chunk.get_string_from_utf8().strip_edges()
	var items : Array = text.split("data: ")
	#for i in items:
		#print(i)
	#print_debug()
	#print()
	var json : JSON = JSON.new()
	for item in items:
		if item != "" and not text.ends_with("[DONE]"):
			if json.parse(item) == OK:
				var data : Dictionary = json.data
				if data.has("choices"):
					var delta = _handle_data(data)
					if _delta_datas.is_empty():
						_delta_datas["id"] = data["id"]
						_delta_datas["role"] = delta["role"]
						_delta_datas["content"] = ""
						_delta_datas["reasoning_content"] = ""
					if delta.has("content") and typeof(delta["content"]) != TYPE_NIL and delta["content"] != "":
						_delta_datas["content"] += delta["content"]
					elif delta.has("reasoning_content") and typeof(delta["reasoning_content"]) != TYPE_NIL and delta["reasoning_content"] != "":
						_delta_datas["reasoning_content"] += delta["reasoning_content"]
					#else:
						#continue
					responded_stream_data.emit(_delta_datas)
				else:
					responded_error.emit(data["error"])
			else:
				if str(item).contains(": keep-alive"):
					print_debug("保持监听中，请等待...")


func _response_stream_end():
	if not _delta_datas.is_empty():
		var message_data = {
			"role": _delta_datas["role"],
			"content": _delta_datas["content"],
		}
		if _delta_datas.has("reasoning_content") and _delta_datas["reasoning_content"]:
			message_data["reasoning_content"] = _delta_datas["reasoning_content"]
		messages.push_back(message_data)
	else:
		_delta_datas["role"] = ""
		_delta_datas["content"] = ""
		_delta_datas["reasoning_content"] = ""
	responded_stream_end.emit(_delta_datas)
	_delta_datas = {}
