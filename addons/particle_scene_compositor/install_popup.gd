@tool
extends Window

var to_keep: Dictionary = {}

@onready var gpu_2d_gd: CheckBox = %Gpu2dGd
@onready var gpu_2d_cs: CheckBox = %Gpu2dCs
@onready var cpu_2d_gd: CheckBox = %Cpu2dGd
@onready var cpu_2d_cs: CheckBox = %Cpu2dCs

@onready var gpu_3d_gd: CheckBox = %Gpu3dGd
@onready var gpu_3d_cs: CheckBox = %Gpu3dCs
@onready var cpu_3d_gd: CheckBox = %Cpu3dGd
@onready var cpu_3d_cs: CheckBox = %Cpu3dCs

const common_path := "res://addons/particle_scene_compositor/sync_node"

const two_dee_suffix := "_2d"
const three_dee_suffix := "_3d"

const gdscript_suffix := ""
const csharp_suffix := "_csharp"

const gpu_dir := "gpu_particles/"
const cpu_dir := "cpu_particles/"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



func _on_button_button_up() -> void:
	queue_free()
	for property: Dictionary in get_property_list():
		var prop := (property.name as String)
		if get(prop) is CheckBox:
			var keep: bool = get(prop).button_pressed
			var folder := get_folder("2d" in prop, "gd" in prop, "gpu" in prop)
			to_keep[folder] = keep

func get_folder(two_dee: bool, gdscript: bool, gpu: bool) -> String:
	var dee := two_dee_suffix if two_dee else three_dee_suffix
	var script := gdscript_suffix if gdscript else csharp_suffix
	var dir := gpu_dir if gpu else cpu_dir
	
	return (common_path + dee + script).path_join(dir)
