extends CanvasLayer
# Scene transition (an autoload, so it is available everywhere as SceneTransition).
#
# The screen turns into flickering binary digits (0 and 1), the scene is swapped while
# the digits cover everything, and the new scene appears out of the digits again.
# The game also starts this way: the first screen is hidden behind digits and then appears.
#
# Use it instead of get_tree().change_scene():
#     SceneTransition.change_scene("res://scenes/UI/main_menu.tscn")
#     SceneTransition.change_scene_to(a_packed_scene)

const SHADER_PATH = "res://scenes/UI/binary_transition.shader"
const FULL = 1.1   # the shader's "progress" value at which every cell is a digit

export var out_time: float = 0.8      # the old scene turns into digits
export var hold_time: float = 0.2     # everything is digits; the scene changes now
export var in_time: float = 0.8       # the new scene appears out of the digits
export var start_delay: float = 0.4   # at game start: how long the digits stay before the first scene appears
export var cell_size: Vector2 = Vector2(16, 24)   # size of one digit in pixels

var _rect: ColorRect = null
var _material: ShaderMaterial = null
var _tween: Tween = null
var _busy: bool = false


func _ready() -> void:
	layer = 128   # above everything else

	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP   # no clicks get through while the digits are showing
	add_child(_rect)
	_rect.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_rect.visible = false

	_tween = Tween.new()
	add_child(_tween)

	var shader = load(SHADER_PATH)
	if shader == null:
		push_error("SceneTransition: could not load %s, scenes will change without the effect" % SHADER_PATH)
		return
	_material = ShaderMaterial.new()
	_material.shader = shader
	_rect.material = _material
	_update_cells()
	get_tree().get_root().connect("size_changed", self, "_update_cells")

	# game start: begin behind the digits, then let the first scene appear out of them
	_busy = true
	_set_progress(FULL)
	_rect.visible = true
	yield(get_tree().create_timer(start_delay), "timeout")
	_animate(FULL, 0.0, in_time)
	yield(_tween, "tween_all_completed")
	_finish()


func change_scene(path: String) -> void:
	_start(path, null)


func change_scene_to(scene: PackedScene) -> void:
	_start("", scene)


func is_busy() -> bool:
	return _busy


# ---------------------------------------------------------------------

func _start(path: String, scene: PackedScene) -> void:
	if _material == null:
		_swap(path, scene)   # no shader: change the scene without the effect
		return
	if _busy:
		return   # a transition is already running (e.g. a button pressed twice)
	_busy = true
	_rect.visible = true

	_animate(0.0, FULL, out_time)          # the old scene turns into digits
	yield(_tween, "tween_all_completed")
	yield(get_tree().create_timer(hold_time), "timeout")

	_swap(path, scene)                      # the screen is all digits: swap the scene
	yield(get_tree(), "idle_frame")         # the new scene is put in place at the end of the frame
	yield(get_tree(), "idle_frame")

	_animate(FULL, 0.0, in_time)           # the new scene appears out of the digits
	yield(_tween, "tween_all_completed")
	_finish()


func _swap(path: String, scene: PackedScene) -> void:
	var err = OK
	if scene != null:
		err = get_tree().change_scene_to(scene)
	else:
		err = get_tree().change_scene(path)
	if err != OK:
		push_error("SceneTransition: could not open '%s' (error %s)" % [path, err])


func _animate(from_value: float, to_value: float, duration: float) -> void:
	_tween.stop_all()
	_tween.remove_all()
	_tween.interpolate_method(self, "_set_progress", from_value, to_value, max(duration, 0.01), Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	_tween.start()


func _set_progress(value: float) -> void:
	if _material != null:
		_material.set_shader_param("progress", value)


func _finish() -> void:
	_set_progress(0.0)
	_rect.visible = false
	_busy = false


# keeps the digits the same size when the window size changes
func _update_cells() -> void:
	if _material == null:
		return
	var size = get_viewport().get_visible_rect().size
	_material.set_shader_param("cells", Vector2(ceil(size.x / cell_size.x), ceil(size.y / cell_size.y)))
