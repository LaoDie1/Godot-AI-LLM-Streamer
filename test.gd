extends Node2D

@onready var conversation : Conversation = $Conversation
@onready var shower : TextEdit = $Shower
@onready var sender : TextEdit = $Sender


func _ready():
	assert(conversation.api_key != "", "必须设置 API 才能运行")


func send():
	if sender.text.strip_edges().is_empty():
		return
	conversation.send(sender.text.strip_edges())
	sender.text = ""


func _on_conversation_responded_stream_data(delta_data: Dictionary):
	shower.text = delta_data["content"]


func _on_conversation_responded_stream_end(message_data):
	shower.text = message_data["content"]
