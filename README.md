# Particle Scene Compositor (Godot 4)

<p align="center"><img src="icon.png" alt="Particle compositor logo"/></p>

This plugin adds new nodes and associated editor tools to help create and use particle scenes.

???|Much Better!
--|--
![bruh_version](https://github.com/user-attachments/assets/f2e557a3-aea7-4dbc-b34b-5dc17a0313af)|![ohyea_version](https://github.com/user-attachments/assets/06361b61-d504-41d9-baab-be67f0f5e167)

## Reason:
Creating and using particles in Godot 4, including self-freeing "one-shot" particles is very simple and straightforward. However, attempting to create more complex particle scenes composed of multiple particle nodes quickly becomes a major hassle.
Like in the preview above, there is no real built-in way to preview composed effects in the editor if they are comprised of multiple nodes. The only option is to use tool scripts, but these can be *very* buggy when attached to particle nodes.

## Features
* Particle control panel that provides QoL features and synchronized autoplay of all particle nodes in the editor
* `SyncNode` runtime node that can play and restart all child particle nodes in a synchronized manner. By default offers "one-shot" behavior, by autoplaying on ready and self-freeing once all child particles have finished.
* Stand-alone components, meaning each component of the plugin is optional.
* `SyncNode` versions available for both Gpu and Cpu particles, as well as 2D and 3D
* Both GDScript and C# compatible, with all `SyncNode` variants available in both languages.

## Installation
Each component of the plugin works fully stand-alone. On installation a popup will ask which components to keep and which to omit, so there's no need to add the 3d nodes in a 2d project, or GDScript nodes in a C# project. The editor panel can't be skipped this way, but can be removed manually.

To install:
* (Recommended) Download directly from the Godot asset library https://godotengine.org/asset-library/asset/3352;
* Or download the repository, and copy the `addons` folder into your Godot project.

## Usage
### Editor:

With the editor panel installed and the plugin active, the particle control panel will appear whenever a compatible node type is selected in the editor – all built in particle nodes, and any `SyncNodes`, if installed. By default, it will not appear for a built-in particle node if it is a scene root due to limited features. This can be changed in project settings.
<p align="center">
<img alt="Particle editor panel" src="https://github.com/user-attachments/assets/93a3e54c-16fb-4054-8779-1201357960ea"></p>
</p>

* **Copy Particle**: Copies the selected particle node, and if it has `process_material`, will make it unique. Making the process material unique allows edits to be made on the copied node without them affecting the original, and vice versa. On `SyncNodes` and scene roots this is replaced with the option to add a new child node of the relevant type.
* **Play Once**: Immediately (re)start particle emission of either all or only the selected particle node in the scene.
* **Autoplay**: Continuously replay particle emissions of either all or only the selected particle node in the scene. By default, this will start particle emissions once it has received the `finished` signal from all of the emitting nodes.
* **Preprocess**: Will set the `preprocess` value of any particle nodes to be played to the set value.
* **Time-base autoplay**: If active, `Autoplay` will replay all/this node based on time, rather than the `finished` signals. This is useful to speed up the replay, or for subemitters, as their `finished` signal occurs when their parent emitter emits its signal, not when all of their particles are cleared.
* **Autoplay timer**: The amount of time before restarting emission when autoplaying with time-based autoplay active.

### SyncNodes:

`SyncNodes` are lightweight runtime nodes designed to be the parent node of a particle scene. They start emissions of all child particle nodes (can be nested) and can either restart them in unison, or await when all child particles have finished and free itself for simple "one-shot" behavior. Non-compatible nodes are ignored.

**Note!** For type-safety and performance, `SyncNodes` only detect particle nodes of their corresponding type, e.g. `GPUSyncNode2D` will only work with `GPUParticles2D` and not `CPUParticles2D`. The C# and GDScript versions are interchangeable.

Exported members for easy usage|SyncNodes available for each particle type in GDScript and C#
--|--
<img width="340" alt="Syncnode properties" src="https://github.com/user-attachments/assets/08991626-6964-48fb-8939-aa1927fae606">|<img width="551" alt="Syncnode selection" src="https://github.com/user-attachments/assets/8dbf0d44-fd85-496d-83f3-fbc7eabf74f0">

Besides the exported properties, for usage in code `SyncNodes` provides methods `start()`, `stop()` and `restart()`; signals `loop_finished` and `finished`; as well as properties `emitting` and `time_elapsed` to track particle progress.


Documentation for `SyncNodes` is accessible in Godot's built-in documentation system, accessed by the `F1` key.


