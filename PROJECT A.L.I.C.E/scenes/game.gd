extends Node2D

var enemy_scenes = [
	preload("res://scenes/Roach.tscn"),
	preload("res://scenes/Butterfly.tscn")
]

onready var enemy_container = $EnemyContainer
onready var spawn_container = $SpawnContainer
onready var timer = $SpawnTimer

var click_sound = preload("res://sounds/click.ogg")
var miss_sound = preload("res://sounds/miss.wav")

onready var click_player = AudioStreamPlayer.new()
onready var miss_player = AudioStreamPlayer.new()

func _ready() -> void:
	randomize()

	click_player.stream = click_sound
	click_player.volume_db = linear2db(0.1)
	add_child(click_player)

	miss_player.stream = miss_sound
	miss_player.volume_db = linear2db(0.1)
	add_child(miss_player)

	timer.start()
	spawn()

var active_enemy = null
var current_letter_index: int = -1

func find_new_active_enemy(typed_character: String):
	for enemy in enemy_container.get_children():
		var prompt = enemy.get_prompt()
		var next_character = prompt.substr(0, 1)
		if next_character.to_lower() == typed_character.to_lower():
			print("new enemy %s" % next_character)
			active_enemy = enemy
			current_letter_index = 1
			active_enemy.next_character(current_letter_index)
			return

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var typed_event = event as InputEventKey
		var key_typed = char(typed_event.unicode)

		if active_enemy == null:
			find_new_active_enemy(key_typed)
		else:
			var prompt = active_enemy.get_prompt()
			var next_character = prompt.substr(current_letter_index, 1)
			if key_typed.to_lower() == next_character.to_lower():
				print("success %s" % key_typed)
				if not click_player.playing:
					click_player.play()
				current_letter_index += 1
				active_enemy.next_character(current_letter_index)
				if current_letter_index == prompt.length():
					print("finish")
					current_letter_index = -1
					active_enemy.queue_free()
					active_enemy = null
			else:
				print("wrong %s vs %s" % [key_typed, next_character])
				if not miss_player.playing:
					miss_player.play()


func _on_SpawnTimer_timeout():
	spawn()

func spawn():
	var enemy_scene = enemy_scenes[randi() % enemy_scenes.size()]
	var enemy_spawn = enemy_scene.instance()
	var spawn = spawn_container.get_children()
	var index = randi() % spawn.size()
	enemy_container.add_child(enemy_spawn)
	enemy_spawn.global_position = spawn[index].global_position
