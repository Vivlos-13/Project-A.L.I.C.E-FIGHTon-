extends Sprite

signal health_changed(new_health)
signal died

const MAX_HEALTH = 6  # 3 hearts x 2 halves each

# Extra reach (in pixels) around the hurtbox shape, so enemies stopping at the edge still count
export var hit_padding: float = 20.0

export var game_over_scene: String = "res://scenes/UI/GameOver.tscn"  # note: must match this exactly
export var fade_duration: float = 1.0

var health: int = MAX_HEALTH

var hearts = []
var hurtbox = null
var enemy_container = null

var heart_full_texture = null
var heart_half_texture = null
var heart_empty_texture = null


func _ready():
	heart_half_texture = load("res://sprites/Heart-half.png")
	heart_empty_texture = load("res://sprites/Heart-empty.png")

	hurtbox = find_node("hurtbox", true, false)
	enemy_container = get_tree().get_root().find_node("EnemyContainer", true, false)

	for heart_name in ["Heart1", "Heart2", "Heart3"]:
		var heart = find_node(heart_name, true, false)
		if heart == null:
			heart = get_tree().get_root().find_node(heart_name, true, false)
		hearts.append(heart)

	# Missing-node warnings so problems show up in the debugger instead of silent failure
	if hurtbox == null:
		push_error("Player: could not find a node named 'hurtbox'")
	if enemy_container == null:
		push_error("Player: could not find a node named 'EnemyContainer'")
	if heart_half_texture == null or heart_empty_texture == null:
		push_error("Player: could not load Heart-half.png / Heart-empty.png from res://sprites/")
	for heart in hearts:
		if heart == null:
			push_error("Player: a Heart node (Heart1/Heart2/Heart3) was not found")
			return

	# Whatever texture the hearts start with is treated as the full heart
	heart_full_texture = hearts[0].texture
	update_hearts()

	connect("died", self, "_on_died")


func _process(_delta):
	if health <= 0 or hurtbox == null or hurtbox.shape == null or enemy_container == null:
		return

	for enemy in enemy_container.get_children():
		if enemy.is_queued_for_deletion():
			continue
		if enemy_in_hurtbox(enemy):
			enemy.queue_free()
			take_damage(1)  # 1 point = half a heart


func enemy_in_hurtbox(enemy) -> bool:
	var shape = hurtbox.shape
	var local_pos = hurtbox.to_local(enemy.global_position)

	if shape is RectangleShape2D:
		return abs(local_pos.x) <= shape.extents.x + hit_padding \
			and abs(local_pos.y) <= shape.extents.y + hit_padding
	elif shape is CircleShape2D:
		return local_pos.length() <= shape.radius + hit_padding
	elif shape is CapsuleShape2D:
		return abs(local_pos.x) <= shape.radius + hit_padding \
			and abs(local_pos.y) <= shape.height / 2.0 + shape.radius + hit_padding
	return false


func take_damage(amount: int):
	health = int(max(health - amount, 0))
	update_hearts()
	emit_signal("health_changed", health)
	if health == 0:
		emit_signal("died")


func update_hearts():
	# Hearts deplete right-to-left: Heart3 first, Heart1 last
	for i in range(hearts.size()):
		var heart_health = int(clamp(health - i * 2, 0, 2))
		if heart_health == 2:
			hearts[i].texture = heart_full_texture
		elif heart_health == 1:
			hearts[i].texture = heart_half_texture
		else:
			hearts[i].texture = heart_empty_texture


func _on_died():
	set_process(false)  # stop taking further hits while the fade plays

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.rect_size = get_viewport_rect().size
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var layer = CanvasLayer.new()
	layer.layer = 100  # draw above everything else
	# Parent to the CURRENT scene, not the root viewport, so this overlay
	# is automatically freed when change_scene() discards the old scene.
	# Parenting to get_root() is what caused the screen to stay stuck black.
	get_tree().current_scene.add_child(layer)
	layer.add_child(overlay)

	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(
		overlay, "color:a",
		0.0, 1.0,
		fade_duration,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	tween.start()

	yield(tween, "tween_completed")

	var err = get_tree().change_scene(game_over_scene)
	if err != OK:
		push_error("Player: failed to load '%s' (error %s)" % [game_over_scene, err])
