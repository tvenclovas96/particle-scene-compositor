@tool
extends VBoxContainer

enum type {NONE, AUTO_GPU_2D, AUTO_GPU_3D, AUTO_CPU_2D, AUTO_CPU_3D, GPU_2D, GPU_3D, CPU_2D, CPU_3D}

const GUI_DROPPED = preload("res://addons/particle_scene_compositor/editor/GuiDropdown.svg")
const GUI_RIGHT = preload("res://addons/particle_scene_compositor/editor/GuiDropdownRight.svg")

const BUILT_IN_TYPES: Dictionary = {
	type.GPU_2D: BUILT_IN[0],
	type.GPU_3D: BUILT_IN[1],
	type.CPU_2D: BUILT_IN[2],
	type.CPU_3D: BUILT_IN[3],
}
const CHILD_TYPES: Dictionary = {
	type.AUTO_GPU_2D: BUILT_IN[0],
	type.AUTO_GPU_3D: BUILT_IN[1],
	type.AUTO_CPU_2D: BUILT_IN[2],
	type.AUTO_CPU_3D: BUILT_IN[3],
}
const BUILT_IN: Array[String] = [
	"GPUParticles2D", "GPUParticles3D", "CPUParticles2D", "CPUParticles3D"]


@onready var main_grid: GridContainer = %MainGrid
@onready var advanced_grid: GridContainer = %AdvancedGrid

@onready var drop_down: Button = %DropDown
@onready var drop_down_2: Button = %DropDown2

@onready var add_particles: Label = %AddParticles
@onready var add_particles_button: Button = %AddParticlesButton

@onready var copy_particles: Label = $MainGrid/CopyParticles
@onready var copy_particles_button: Button = %CopyParticlesButton

@onready var play_once_this_button: Button = %PlayOnceThisButton

@onready var autoplay_check: CheckBox = %AutoplayCheck
@onready var autoplay_all_check: CheckBox = %AutoplayAllCheck

@onready var preprocess_num: SpinBox = %PreprocessNum
@onready var preprocess_slider: HSlider = %PreprocessSlider

@onready var cycle_freq_num: SpinBox = %CycleFreqNum
@onready var cycle_freq_slider: HSlider = %CycleFreqSlider

@onready var cycle_freq_label: Label = %CycleFreq
@onready var cycle_freq_container: VBoxContainer = %CycleFreqContainer

@onready var set_cycle_check: CheckBox = %SetCycleCheck

# shared scene settings
var _scene_emitting: bool:
	get():
		return _autoplay_enabled and not _this_node_only and not _manual_cycle
var _only_this_emitting: bool:
	get():
		return _autoplay_enabled and _this_node_only and not _manual_cycle
var _preprocess_time: float = 0.0

var _autoplay_enabled := false
var _this_node_only := false

var _panel_active := true
var _advanced_panel_active := false
var _manual_cycle := false
var cycle_freq: float = 2

var to_save_scene: Array[StringName] = [&"_panel_active", &"_manual_cycle", &"_advanced_panel_active",
	&"_preprocess_time", &"cycle_freq", &"_autoplay_enabled", &"_this_node_only"]

# "runtime" vars
var _is_built_in: bool:
	set(value):
		_is_built_in = value
		autoplay_check.visible = value
		play_once_this_button.visible = value

var _source: Node
var _scene_root: Node
var _curr_type: type

var _cycle_freq_being_edited := false
var _preprocess_being_edited := false

var _cycle_progress: float = 0.0
var _counter: int = 0
var _emitting := false


signal finished

func set_source_info(object: Node, root_node: Node, curr_type: type) -> void:
	_source = object
	_scene_root = root_node
	_curr_type = curr_type

func _get_state() -> Dictionary:
	var data: Dictionary = {}
	for property: StringName in to_save_scene:
		data[property] = get(property)
	return data

func _set_state(state: Dictionary) -> void:
	for key: StringName in state:
		set(key, state[key])

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_grid.visible = _panel_active
	drop_down_2.visible = _panel_active
	advanced_grid.visible = _panel_active and _advanced_panel_active
	
	set_cycle_check.set_pressed_no_signal(_manual_cycle)
	_set_autoplay_checks()
	
	preprocess_slider.set_value_no_signal(_preprocess_time)
	preprocess_num.set_value_no_signal(_preprocess_time)
	
	cycle_freq_num.set_value_no_signal(cycle_freq)
	cycle_freq_slider.set_value_no_signal(cycle_freq)
	
	drop_down.icon = GUI_DROPPED if _panel_active else GUI_RIGHT
	drop_down_2.icon = GUI_DROPPED if _advanced_panel_active else GUI_RIGHT
	
	_is_built_in = not (BUILT_IN_TYPES.get(_curr_type, "") as String).is_empty()
	_toggle_add_or_copy_section( not _is_built_in or _source == _scene_root)
	
	if _scene_emitting:
		_recursive_autoplay(_scene_root)
	if _only_this_emitting and _is_built_in:
		_autoplay(_source)

#region Particle control
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _manual_cycle and _autoplay_enabled:
		_cycle_progress += delta
		if _cycle_progress >= cycle_freq:
			_cycle_progress = 0
			if _this_node_only: _manual_play(_source)
			else: _recursive_manual_play(_scene_root)

func _manual_play(node: Node) -> void:
	_emitting = true
	if is_emitter_class(node):
		_activate(node)
		node.preprocess = _preprocess_time

func _autoplay(node: Node) -> void:
	_emitting = true
	_autoplay_enabled = true
	if is_emitter_class(node):
		_counter += 1
		_activate(node)
		node.preprocess = _preprocess_time
		if not node.is_connected(&"finished", _decrement):
			node.finished.connect(_decrement)

func _reconnect(node: Node) -> void:
	if is_emitter_class(node):
		_counter += 1 if node.emitting else 0
		if not node.is_connected(&"finished", _decrement):
			node.finished.connect(_decrement)

func _stop(node: Node) -> void:
	_emitting = false
	_autoplay_enabled = false
	if is_emitter_class(node):
		node.emitting = false
		if node.is_connected(&"finished", _decrement):
			node.finished.disconnect(_decrement)


func _recursive_manual_play(node: Node) -> void:
	_manual_play(node)
	for child in node.get_children():
		_recursive_manual_play(child)

func _recursive_autoplay(node: Node) -> void:
	_autoplay(node)
	for child in node.get_children():
		_recursive_autoplay(child)

func _recursive_reconnect(node: Node) -> void:
	_reconnect(node)
	for child in node.get_children():
		_recursive_reconnect(child)

func _recursive_stop(node: Node) -> void:
	_stop(node)
	for child in node.get_children():
		_recursive_stop(child)

func _decrement() -> void:
	_counter -= 1
	if _counter <= 0:
		_complete()

func _activate(node: Node) -> void:
	node.one_shot = true
	node.emitting = true
	node.restart()

func _complete() -> void:
	_emitting = false
	await get_tree().create_timer(0.2, true).timeout
	finished.emit()
	_on_finish()

func _on_finish() -> void:
	if _manual_cycle: return
	if _autoplay_enabled:
		if _this_node_only: _autoplay(_source)
		else: 
			_counter = 0
			_recursive_autoplay(_scene_root)
		
static func is_emitter_class(node: Node) -> bool:
	return node.get_class() in BUILT_IN

static func get_enum_from_built_in_class(class_type: String) -> type:
	for key: type in BUILT_IN_TYPES:
		if BUILT_IN_TYPES[key] == class_type:
			return key
	return type.NONE

#endregion

#region Panel control

func _on_drop_down_button_up() -> void:
	_panel_active = not _panel_active
	drop_down.icon = GUI_DROPPED if _panel_active else GUI_RIGHT
	main_grid.visible = _panel_active
	drop_down_2.visible = _panel_active
	advanced_grid.visible = _panel_active and _advanced_panel_active

func _on_drop_down_2_button_up() -> void:
	_advanced_panel_active = not _advanced_panel_active
	drop_down_2.icon = GUI_DROPPED if _advanced_panel_active else GUI_RIGHT
	advanced_grid.visible = _advanced_panel_active

func _on_cycle_freq_slider_value_changed(value: float) -> void:
	cycle_freq = value
	cycle_freq_num.set_value_no_signal(value)
	
func _on_cycle_freq_num_value_changed(value: float) -> void:
	cycle_freq = value
	cycle_freq_slider.set_value_no_signal(value)

func _on_preprocess_slider_value_changed(value: float) -> void:
	if _preprocess_being_edited: return
	
	_preprocess_being_edited = true
	_preprocess_time = value
	preprocess_num.value = value
	_preprocess_being_edited = false

func _on_preprocess_num_value_changed(value: float) -> void:
	if _preprocess_being_edited: return
	
	_preprocess_being_edited = true
	_preprocess_time = value
	preprocess_slider.value = value
	_preprocess_being_edited = false

func _on_set_cycle_check_pressed() -> void:
	_manual_cycle = not _manual_cycle
	if not _autoplay_enabled: return
	if not _emitting and _manual_cycle:
		_cycle_progress = cycle_freq
	if not _manual_cycle:
		if _emitting:
			if _this_node_only: _reconnect(_source)
			else: _recursive_reconnect(_scene_root)
		else:
			_counter = 0
			if _this_node_only: _autoplay(_source)
			else: _recursive_autoplay(_scene_root)

func _toggle_add_or_copy_section(add_not_copy: bool) -> void:
	add_particles.visible = add_not_copy
	add_particles_button.visible = add_not_copy
	copy_particles.visible = not add_not_copy
	copy_particles_button.visible = not add_not_copy

func _on_add_particles_button_pressed() -> void:
	var child_type: String = CHILD_TYPES.get(_curr_type, "")
	if child_type.is_empty():
		if _source == _scene_root:
			child_type = _source.get_class()
		else:
			printerr("Could not determine particle type to add")
			return
	
	if not ClassDB.class_exists(child_type):
		printerr("Could not find class type in current build for: ", child_type)
		return
	var child: Node = ClassDB.instantiate(child_type)
	_source.add_child(child, true)
	child.owner = _scene_root
	_connect_to_new_particles()

#func _on_add_particles_button_pressed_sibling() -> void:
	#var built_in_type: String = BUILT_IN_TYPES.get(_curr_type, "")
	#if built_in_type.is_empty():
		#built_in_type = _source.get_class()
	#if not ClassDB.class_exists(built_in_type):
		#printerr("Could not find class type in current build for: ", built_in_type)
		#return
	#var child: Node = ClassDB.instantiate(built_in_type)
	#if _source.owner: _source.add_sibling(child, true)
	#else:
		#printerr("Cannot add sibling to scene root")
		#return
	#child.owner = _scene_root

func _on_copy_particles_button_pressed() -> void:
	if _source == _scene_root:
		printerr("Cannot duplicate scene root")
		return
	var child := _source.duplicate()
	_source.add_sibling(child, true)
	child.owner = _scene_root
	
	var mat := child.get(&"process_material") as Material
	if mat:
		mat = mat.duplicate(true)
		child.set(&"process_material", mat)
	_connect_to_new_particles()

# doesn't work, idk
func _connect_to_new_particles() -> void:
	await get_tree().create_timer(0.1, true).timeout
	if _scene_emitting:
		_recursive_stop(_scene_root)
		_autoplay_enabled = true
		_recursive_autoplay(_scene_root)
	elif _only_this_emitting:
		_recursive_stop(_scene_root)
		_autoplay_enabled = true
		_autoplay(_source)

func _on_play_once_all_button_pressed() -> void:
	_this_node_only = false
	
	set_cycle_check.set_pressed_no_signal(_manual_cycle)
	_set_autoplay_checks()
	
	_recursive_stop(_scene_root)
	_recursive_manual_play(_scene_root)

func _on_play_once_this_button_pressed() -> void:
	_this_node_only = true
	
	set_cycle_check.set_pressed_no_signal(_manual_cycle)
	_set_autoplay_checks()
	
	_recursive_stop(_scene_root)
	_manual_play(_source)

func _set_autoplay_checks():
	autoplay_all_check.set_pressed_no_signal(_autoplay_enabled and not _this_node_only)
	autoplay_check.set_pressed_no_signal(_autoplay_enabled and _this_node_only)
	
func _on_autoplay_check_toggled(toggled_on: bool) -> void:
	_this_node_only = toggled_on
	if toggled_on:
		_counter = 0
		autoplay_all_check.set_pressed_no_signal(false)
		_autoplay_enabled = true
		if not _manual_cycle:
			_recursive_stop(_scene_root)
			_autoplay(_source)
	
	else: _autoplay_enabled = false

func _on_autoplay_all_check_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_counter = 0
		_this_node_only = false
		autoplay_check.set_pressed_no_signal(false)
		_autoplay_enabled = true
		if not _manual_cycle:
			_recursive_stop(_scene_root)
			_recursive_autoplay(_scene_root)
	
	else: _autoplay_enabled = false


#endregion
