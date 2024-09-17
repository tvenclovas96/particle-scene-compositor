import os
import sys

def the_script_extrapolatinator(source_file: str) -> None:
    if not os.path.exists(source_file) or not (source_file.endswith(".gd") or source_file.endswith(".cs")):
        print(f"Warning: The file '{source_file}' does not exist or is not a .gd or .cs file.")
        return

    with open(source_file, "r") as file:
        source_code = file.read()

    print(f"Extrapolating from script: {source_file}")

    # Generate the CpuParticles version of the script
    version_cpu: str = source_code.replace("Gpu", "Cpu").replace("GPU", "CPU")

    # Generate the 3D version of the script
    version_3d: str = source_code.replace("2d", "3d").replace("2D", "3D")

    # Generate the 3D+Cpu version of the script
    version_3d_cpu: str = version_3d.replace("Gpu", "Cpu").replace("GPU", "CPU")

    output_dir: str = os.path.dirname(source_file)
    final_folder: str = os.path.basename(output_dir)
    parent_dir: str = os.path.dirname(output_dir)
    
    if "2d" in final_folder:
        final_folder = final_folder.replace("2d", "3d")
    else:
        print(f"yeah directory name error. Doesn\'t have \"2d\" in name: {final_folder}")
    
    output_dir3d: str = os.path.join(parent_dir, final_folder)

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    if not os.path.exists(output_dir3d):
        os.makedirs(output_dir3d)
    
    script_name: str = os.path.basename(source_file)

    script_name_3d = script_name.replace("2d", "3d").replace("2D", "3D")
    script_name_cpu = script_name.replace("Gpu", "Cpu").replace("GPU", "CPU").replace("gpu", "cpu")
    script_name_3d_cpu = script_name_3d.replace("Gpu", "Cpu").replace("GPU", "CPU").replace("gpu", "cpu")

    versions = [
        (script_name_3d, version_3d),
        (script_name_cpu, version_cpu),
        (script_name_3d_cpu, version_3d_cpu)
    ]

    for new_script, new_code in versions:
        if new_script != script_name:
            dir = output_dir3d if "3d" in new_script else output_dir
            with open(os.path.join(dir, new_script), "w") as file:
                file.write(new_code)
            print(f"Script extrapolated: {new_script}")
        else:
            print(f"yeah guess what, couldn't make: {new_script}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python cpu_version_creator.py <source_file_to_extrapolate>")
    else:
        source_file = sys.argv[1]
        the_script_extrapolatinator(source_file)