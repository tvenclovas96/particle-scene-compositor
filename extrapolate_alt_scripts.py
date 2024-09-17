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
    version_cpu: str = source_code.replace("Gpu", "Cpu").replace("GPU", "CPU").replace("gpu", "cpu")
    # Generate the 3D version of the script
    version_3d: str = source_code.replace("2d", "3d").replace("2D", "3D")
    # Generate the 3D+Cpu version of the script
    version_3d_cpu: str = version_3d.replace("Gpu", "Cpu").replace("GPU", "CPU").replace("gpu", "cpu")
    
    final_dir: str = os.path.dirname(source_file)
    pre_final_dir: str = os.path.dirname(final_dir)
    common_dir: str = os.path.dirname(pre_final_dir)

    folder_gpu_version: str = os.path.basename(final_dir)
    folder_2d_version: str = os.path.basename(pre_final_dir)

    folder_cpu_version: str = folder_gpu_version.replace("Gpu", "Cpu").replace("GPU", "CPU").replace("gpu", "cpu")
    folder_3d_version: str = folder_2d_version.replace("2d", "3d").replace("2D", "3D")

    if folder_cpu_version == folder_gpu_version:
        print(f"yeah directory name error. Doesn\'t have \"gpu\" in name: {folder_gpu_version}")
    if folder_3d_version == folder_2d_version:
        print(f"yeah directory name error. Doesn\'t have \"2d\" in name: {folder_2d_version}")
    
    output_dir3d: str = os.path.join(pre_final_dir, folder_gpu_version)

    if not os.path.exists(final_dir):
        os.makedirs(final_dir)
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
            three_dee: bool = "3d" in new_script or "3D" in new_script
            ceepeeyuu: bool = "cpu" in new_script or "CPU" in new_script or "Cpu" in new_script

            folder1 = folder_cpu_version if ceepeeyuu else folder_gpu_version
            folder2 = folder_3d_version if three_dee else folder_2d_version

            the_path = os.path.join(common_dir, folder2, folder1, new_script)
            with open(the_path, "w") as file:
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