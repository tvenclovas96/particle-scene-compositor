@tool
extends EditorPlugin

const Editor = preload("res://addons/particle_scene_compositor/editor/editor.gd")
var inspector_plugin: EditorInspectorPlugin = Editor.new()

const ADDON_PATH := "res://addons/particle_scene_compositor/"
const POPUP_SCENE_PATH := "res://addons/particle_scene_compositor/install_popup.tscn"
const POPUP_SCRIPT_PATH := "res://addons/particle_scene_compositor/install_popup.gd"

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	add_inspector_plugin(inspector_plugin)
	_check_is_just_installed()

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_inspector_plugin(inspector_plugin)


func _get_plugin_name() -> String:
	return "ParticleCompositor"

func _get_state() -> Dictionary:
	return inspector_plugin._get_state()

func _set_state(state: Dictionary) -> void:
	inspector_plugin._set_state(state)

func _check_is_just_installed() -> void:
	if not FileAccess.file_exists(POPUP_SCENE_PATH):
		return
	
	var pop_up = (load(POPUP_SCENE_PATH) as PackedScene).instantiate()
	add_child(pop_up)
	var to_keep: Dictionary = pop_up.to_keep
	
	await pop_up.tree_exited

	for key: String in to_keep.keys():
		if to_keep[key] == false:
			_remove_dir_recursive(key)
	for dir: String in DirAccess.get_directories_at(ADDON_PATH):
		DirAccess.remove_absolute(ADDON_PATH.path_join(dir)) # deletes empty dirs only
	_delete_popup()
	EditorInterface.get_resource_filesystem().scan()

func _delete_popup() -> void:
	DirAccess.remove_absolute(POPUP_SCENE_PATH)
	DirAccess.remove_absolute(POPUP_SCRIPT_PATH)

# Scary!
func _remove_dir_recursive(path: String) -> void:
	for file: String in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	for dir: String in DirAccess.get_directories_at(path):
		_remove_dir_recursive(path)
	DirAccess.remove_absolute(path)
