@tool
extends EditorPlugin

const Editor = preload("res://addons/particle_scene_compositor/editor/editor.gd")
var inspector_plugin: EditorInspectorPlugin = Editor.new()

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	add_inspector_plugin(inspector_plugin)

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_inspector_plugin(inspector_plugin)


func _get_plugin_name() -> String:
	return "ParticleCompositor"

func _get_state() -> Dictionary:
	return inspector_plugin._get_state()

func _set_state(state: Dictionary) -> void:
	inspector_plugin._set_state(state)
