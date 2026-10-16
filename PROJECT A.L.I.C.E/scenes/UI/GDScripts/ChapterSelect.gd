extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Return_pressed():
	get_tree().change_scene("res://scenes/UI/main_menu.tscn")

func _on_Ch1_pressed():
	get_tree().change_scene("res://scenes/UI/Chapter1.tscn")


func _on_Ch2_pressed():
	get_tree().change_scene("res://scenes/UI/Chapter2.tscn")


func _on_Ch3_pressed():
	get_tree().change_scene("res://scenes/UI/Chapter3.tscn")


func _on_Ch4_pressed():
	get_tree().change_scene("res://scenes/UI/Chapter4.tscn")


func _on_Ch5_pressed():
	get_tree().change_scene("res://scenes/UI/Chapter5.tscn")
