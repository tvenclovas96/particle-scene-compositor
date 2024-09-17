import subprocess
import os

def run_extrapolate_script(default_file_path):
    try:
        result = subprocess.run(
            ["python", "extrapolate_alt_scripts.py", default_file_path],
            check=True,
            capture_output=True,
            text=True
        )
        print(result.stdout)
        if result.stderr:
            print(result.stderr)
    except subprocess.CalledProcessError as e:
        print(f"Error in subprocess: {e.stderr}")
    except FileNotFoundError as e:
        print(f"File not found: {e}")

if __name__ == "__main__":
    default_file_path = "addons\particle_scene_compositor\sync_node_2d\gpu_particles\gpu_sync_node_2d.gd"
    default_file_path_cs = "addons\particle_scene_compositor\sync_node_2d_csharp\gpu_particles\GpuSyncNode2dCs.cs"
    
    # Check if the files exist before running the script
    if not os.path.exists(default_file_path):
        print(f"File does not exist: {default_file_path}")
    else:
        run_extrapolate_script(default_file_path)
    
    if not os.path.exists(default_file_path_cs):
        print(f"File does not exist: {default_file_path_cs}")
    else:
        run_extrapolate_script(default_file_path_cs)