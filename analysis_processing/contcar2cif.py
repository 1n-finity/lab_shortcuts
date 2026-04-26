import os
import subprocess
from pathlib import Path
import warnings

# Suppress pymatgen warnings for cleaner terminal output
warnings.filterwarnings("ignore")

try:
    from pymatgen.core import Structure
except ImportError:
    print("Error: pymatgen is not installed. Please install it using 'pip install pymatgen'.")
    exit(1)

def main():
    # Define the full absolute path to the vaspeng script.
    vaspeng_path = os.path.expanduser("~/lab_shortcuts/vaspeng.sh")

    if not os.path.exists(vaspeng_path):
        print(f"Error: Could not find the vaspeng script at '{vaspeng_path}'.")
        print("Please update the 'vaspeng_path' variable in this Python script.")
        return

    # 1. Run the vaspeng script
    print(f"Running '{vaspeng_path}' to identify completed VASP calculations...")
    try:
        subprocess.run(
            ["bash", vaspeng_path], 
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
    except subprocess.CalledProcessError:
        print("Warning: The 'vaspeng' script encountered an error or no completed jobs were found.")

    # 2. Verify energies.csv
    if not os.path.exists("energies.csv"):
        print("Error: 'energies.csv' was not found. Ensure calculations are complete.")
        return

    # 3. Create the output directory
    output_dir = Path("output_result_cif")
    output_dir.mkdir(parents=True, exist_ok=True)
    print(f"Output directory created/verified: {output_dir}")
    print("-" * 50)

    # 4. Parse energies.csv and convert
    success_count = 0
    with open("energies.csv", "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            if "," in line:
                folder_str = line.split(",")[0]
            else:
                folder_str = line.split()[0]
                
            folder_path = Path(folder_str)
            contcar_path = folder_path / "CONTCAR"
            
            # --- THE FIX IS HERE ---
            # Extract the top-level parent folder name from the path.
            # Example: Path('MoO3_5_side/update/opt').parts -> ('MoO3_5_side', 'update', 'opt')
            # We filter out '.' just in case the path starts with './'
            folder_parts = [p for p in folder_path.parts if p not in ('', '.')]
            
            if folder_parts:
                base_folder_name = folder_parts[0]  # Always grab the first part (e.g., 'MoO3_5_side')
            else:
                base_folder_name = "unknown_structure"
            # -----------------------

            if contcar_path.exists():
                if contcar_path.stat().st_size == 0:
                    print(f"[-] Skipped: {contcar_path} is empty.")
                    continue

                cif_filename = f"{base_folder_name}.cif"
                cif_output_path = output_dir / cif_filename
                
                try:
                    structure = Structure.from_file(contcar_path)
                    structure.to(fmt="cif", filename=str(cif_output_path))
                    print(f"[\u2713] Converted: {contcar_path}  ->  {cif_output_path}")
                    success_count += 1
                except Exception as e:
                    print(f"[X] Failed to convert {contcar_path}. Error: {e}")
            else:
                print(f"[-] CONTCAR not found in completed directory: {folder_path}")

    print("-" * 50)
    print(f"Finished! Successfully converted {success_count} CONTCAR files.")

if __name__ == "__main__":
    main()
