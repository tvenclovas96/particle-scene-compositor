extends EditorInspectorPlugin

const ParticleControl = preload("res://addons/particle_scene_compositor/editor/particle_control.gd")
const PARTICLE_CONTROL = preload("res://addons/particle_scene_compositor/editor/particle_control.tscn")


const PATH_GPU_2D := "res://addons/particle_scene_compositor/sync_node_2d/gpu_particles/gpu_sync_node_2d.gd"
const PATH_CPU_2D := "res://addons/particle_scene_compositor/sync_node_2d/cpu_particles/cpu_sync_node_2d.gd"
const PATH_GPU_3D := "res://addons/particle_scene_compositor/sync_node_3d/gpu_particles/gpu_sync_node_3d.gd"
const PATH_CPU_3D := "res://addons/particle_scene_compositor/sync_node_3d/cpu_particles/cpu_sync_node_3d.gd"

const PATH_GPU_2D_CS := "res://addons/particle_scene_compositor/sync_node_2d_csharp/gpu_particles/GpuSyncNode2dCs.cs"
const PATH_CPU_2D_CS := "res://addons/particle_scene_compositor/sync_node_2d_csharp/cpu_particles/CpuSyncNode2dCs.cs"
const PATH_GPU_3D_CS := "res://addons/particle_scene_compositor/sync_node_3d_csharp/gpu_particles/GpuSyncNode3dCs.cs"
const PATH_CPU_3D_CS := "res://addons/particle_scene_compositor/sync_node_3d_csharp/cpu_particles/CpuSyncNode3dCs.cs"
const EMPTY := &""

const SHOW_IF_BUILTIN_ROOT := "editor/particle_scene_compositor/show_panel_on_particle_nodes_if_scene_root"

var class_statuses: Dictionary = {}
var built_in_class_statuses: Dictionary = {}

var scene_data_dict: Dictionary = {}

var current_panel: ParticleControl
var current_node: Node:
	set(value):
		current_node = value
		if not current_node: return
		if current_node.owner != null: root_node = current_node.owner
		else: root_node = current_node
var root_node: Node

#region Initialziation
func _init() -> void:
	parse_installed_paths()
	set_project_settings()
	#var feature_profile := get_editor_feature_profile()
	#for built_in_class: StringName in ParticleControl.BUILT_IN:
		#set_built_in_class_status(built_in_class, feature_profile)

func parse_installed_paths():
	var types1: Array[ParticleControl.type] = [ParticleControl.type.AUTO_CPU_2D, ParticleControl.type.AUTO_CPU_3D]
	var types2: Array[ParticleControl.type] = [ParticleControl.type.AUTO_GPU_2D, ParticleControl.type.AUTO_GPU_3D]
	for path: String in [
		PATH_GPU_2D, PATH_CPU_2D, PATH_GPU_3D, PATH_CPU_3D,
		PATH_GPU_2D_CS, PATH_CPU_2D_CS, PATH_GPU_3D_CS, PATH_CPU_3D_CS]:
		var cpu := path.containsn("cpu")
		var extra_d := path.contains("3d")

		var types := types1 if cpu else types2
		var type := types[1] if extra_d else types[0]
		set_plugin_class_status(path, type)

func set_plugin_class_status(path: String, type: ParticleControl.type) -> void:
	var exists := FileAccess.file_exists(path)
	if exists:
		var my_object: Script = load(path)
		var name := my_object.get_global_name()
		class_statuses[name] = type

func get_editor_feature_profile() -> EditorFeatureProfile:
	const DIR := "feature_profiles"
	const SUFFIX := ".profile"
	var config_location := EditorInterface.get_editor_paths().get_config_dir()
	var profile := EditorInterface.get_current_feature_profile() + SUFFIX
	var profile_file := config_location.path_join(DIR).path_join(profile)
	if FileAccess.file_exists(profile_file):
		var feature_obj := EditorFeatureProfile.new()
		var err := feature_obj.load_from_file(profile_file)
		if not err:
			return feature_obj
	return null

#func set_built_in_class_status(built_in_class: StringName, feature_profile: EditorFeatureProfile) -> void:
	#var active: bool = ClassDB.is_class_enabled(built_in_class) and \
	#(feature_profile == null or not feature_profile.is_class_disabled(built_in_class))
	#
	#built_in_class_statuses[built_in_class] = active

func set_project_settings() -> void:
	if not ProjectSettings.has_setting(SHOW_IF_BUILTIN_ROOT):
		ProjectSettings.set_setting(SHOW_IF_BUILTIN_ROOT, false)
	ProjectSettings.add_property_info({
		"name": SHOW_IF_BUILTIN_ROOT,
		"type": TYPE_BOOL
	})
	ProjectSettings.set_initial_value(SHOW_IF_BUILTIN_ROOT, false)
	ProjectSettings.set_as_basic(SHOW_IF_BUILTIN_ROOT, true)

#endregion

#region Panel Mangement

func _can_handle(obj: Object) -> bool:
	if obj is not Node: return false
	
	current_panel = null
	current_node = null
	var node := obj as Node
	if ParticleControl.is_emitter_class(node) and can_show_if_built_in(node):
		current_node = node
		return true
	if is_plugin_class(obj):
		current_node = node
		return true
	return false

func can_show_if_built_in(node: Node) -> bool:
	return node.owner != null or ProjectSettings.get_setting(SHOW_IF_BUILTIN_ROOT)

func is_plugin_class(obj: Object) -> bool:
	return get_plugin_class_type(obj) != ParticleControl.type.NONE

func get_plugin_class_type(obj: Object) -> ParticleControl.type:
	if obj.get_script() == null: return ParticleControl.type.NONE
	return class_statuses.get((obj.get_script() as Script).get_global_name(), ParticleControl.type.NONE)


func _parse_begin(object: Object) -> void:
	current_panel = PARTICLE_CONTROL.instantiate()
	var type: ParticleControl.type = get_plugin_class_type(object)
	if type == ParticleControl.type.NONE:
		type = ParticleControl.get_enum_from_built_in_class(object.get_class())
	
	current_panel.set_source_info(object, root_node, type)
	#current_panel.built_in_class_statuses = built_in_class_statuses
	load_panel_state()
	current_panel.tree_exiting.connect(save_panel_state)
	
	add_custom_control(current_panel)

func save_panel_state() -> void:
	if is_instance_valid(current_panel):
		scene_data_dict = current_panel._get_state()

func load_panel_state() -> void:
	current_panel._set_state(scene_data_dict)

#endregion

func _get_state() -> Dictionary:
	save_panel_state()
		
	return scene_data_dict

func _set_state(data: Dictionary) -> void:
	scene_data_dict = data
