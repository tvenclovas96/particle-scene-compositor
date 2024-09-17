@icon("res://addons/particle_scene_compositor/sync_node_2d/Cpu2d.svg")
## Synchronization hub node that starts and tracks all child [CPUParticles2D].
## By default, automatically starts on [method _ready], and frees itself when finished.
class_name CPUSyncNode2D extends Node2D

## If true, will automatically start all child [CPUParticles2D] on [method _ready]
@export var autostart: bool = true
## If true, all child [CPUParticles2D] nodes will only emit once. Otherise, they will loop
## and restart once all [CPUParticles2D] have finished or [member time_to_finish] is reached.
@export var one_shot: bool = true
## If true, the node will free itself once it has finished.
@export var free_on_finish: bool = true
## if greater than 0, the node will finish once the elapsed emission time is equal
## to this value or higher. Otherwise, it will finish once all child [CPUParticles2D]
## emit their [signal CPUParticles2D.finished] signals. Finishing will stop any ongoing child [CPUParticles2D]
## emissions.
## [br][br]
## Useful when subemitters are used, since their [signal CPUParticles2D.finished] signal is
## fired before all of their particles are cleared.
@export_range(0, 10, 0.1, "or_greater") var time_to_finish: float = 0.0:
	get():
		return _time_to_finish if _time_to_finish != _max_float else 0.0
	set(value):
		_time_to_finish = value if value > 0 else _max_float
var _time_to_finish: float = _max_float

## is [code]true[/code] if any [CPUParticles2D] node is currently emitting
var emitting: bool = false
## Total elapsed time since child nodes started emitting
var time_elapsed: float

# internal counter to track child particle progress
var _counter: int = 0

## Emitted if [member one_shot] is [code]true[/code] and all child [CPUParticles2D] nodes
## have finished or [member time_to_finish] is reached. This is emitted right after
## [signal loop_finished]. [br][br] If [member free_on_finish] is [code]true[/code], the node will
## free itself after emitting this signal.
signal finished
## Emitted after all child [CPUParticles2D] nodes emit their [signal CPUParticles2D.finished] signal
## if [member time_to_finish] is set than 0. Otherwise, it is emitted when the elapsed emission time
## reaches [member time_to_finish]. [member one_shot] does not affect this signal.
signal loop_finished

const _max_float = 1.79769e308
## Starts all child [CPUParticles2D] emissions. Automatically called on [method Node._ready] if autostart is true.
## Returns if already emitting.
## [br][br]
## Optional [param preprocess] time can be passed to advance all effects from the start,
## such as when loading a saved game state
func start(preprocess: float = 0.0) -> void:
	if emitting: return

	time_elapsed = preprocess
	for child in get_children():
		_recursive_activate(child, preprocess)
	emitting = true

## Restarts all child [CPUParticles2D], interrupting any in-progress emissions.
## Any newly-added [CPUParticles2D] nodes will be automatically included.
## [br][br]
## Optional [param preprocess] time can be passed to advance all effects from the start,
## such as when loading a saved game state
func restart(preprocess: float = 0.0) -> void:
	_counter = 0
	time_elapsed = preprocess
	for child in get_children():
		_recursive_restart(child, preprocess)
	emitting = true

## Stops all [CPUParticles2D] emissions, interrupting any in-progress emissions.
## Does not cause the [signal finished] or [signal loop_finished] signals to be emitted.
func stop() -> void:
	_counter = 0
	for child in get_children():
		_recursive_stop(child)
	emitting = false


func _ready() -> void:
	if autostart: start()


func _process(delta: float) -> void:
	if not emitting: return
	
	time_elapsed += delta
	if time_elapsed >= _time_to_finish:
		stop()
		_complete()


static func _activate(node: CPUParticles2D) -> void:
	node.one_shot = true
	node.emitting = true
	node.restart()

static func _recursive_stop(node: Node) -> void:
	if node is CPUParticles2D:
		(node as CPUParticles2D).emitting = false
	for child in node.get_children():
		_recursive_stop(child)


func _recursive_activate(node: Node, preprocess: float = 0.0) -> void:
	if node is CPUParticles2D:
		var particle = node as CPUParticles2D
		particle.preprocess = preprocess
		_activate(particle)
	
		_counter += 1
		particle.finished.connect(_decrement)
	
	for child in node.get_children():
		_recursive_activate(child, preprocess)


func _recursive_restart(node: Node, preprocess: float = 0.0) -> void:
	if node is CPUParticles2D:
		var particle = node as CPUParticles2D
		particle.preprocess = preprocess
		_activate(particle)
		
		_counter += 1
		if not particle.is_connected(&"finished", _decrement):
			particle.finished.connect(_decrement)
	
	for child in node.get_children():
		_recursive_restart(child, preprocess)


func _decrement() -> void:
	_counter -= 1
	if _counter <= 0 and _time_to_finish == _max_float:
		_complete()


func _complete() -> void:
	emitting = false

	loop_finished.emit()
	if not one_shot:
		restart()
	else:
		finished.emit()
		if free_on_finish:
			queue_free()
