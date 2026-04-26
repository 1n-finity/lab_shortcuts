import argparse
import os
from pathlib import Path
import warnings

# Suppress pymatgen warnings for cleaner terminal output
warnings.filterwarnings("ignore")

try:
    from pymatgen.core import Structure
except ImportError:
    print("Error: pymatgen is not installed. Please install it using 'pip install pymatgen'.")
    exit(1)

def convert_cif_to_poscar(cif_path, output_path):
    """Reads a CIF file and writes it to a POSCAR format."""
    try:
        # Read the structure
        structure = Structure.from_file(cif_path)
        
        # Sort the structure to group identical elements together.
        # This prevents fragmented lists (e.g., "Mo O S O S") and groups them (e.g., "Mo O S")
        structure.sort() 
        
        # Write the sorted structure to POSCAR
        structure.to(fmt="poscar", filename=str(output_path))
        print(f"[\u2713] Converted: {cif_path.name} -> {output_path.name}")
    except Exception as e:
        print(f"[X] Failed to convert {cif_path.name}. Error: {e}")

def process_path(target_path):
    path = Path(target_path)

    if not path.exists():
        print(f"Error: The path '{target_path}' does not exist.")
        return

    # --- CASE 1: Single File ---
    if path.is_file():
        if path.suffix.lower() == '.cif':
            file_name = path.stem # gets filename without .cif extension
            output_name = f"POSCAR_{file_name}"
            output_path = path.parent / output_name
            
            print(f"Processing single file: {path.name}")
            convert_cif_to_poscar(path, output_path)
        else:
            print(f"Error: '{target_path}' is not a .cif file.")

    # --- CASE 2: Directory ---
    elif path.is_dir():
        # Handle cases where path might be '.' or '..'
        dir_name = path.resolve().name 
        output_dir = path.parent / f"{dir_name}_POSCAR"

        # Create the new folder for POSCARs
        output_dir.mkdir(parents=True, exist_ok=True)
        print(f"Processing directory: {path.name}")
        print(f"Output folder created: {output_dir}\n" + "-"*30)

        # Find all .cif files in the directory
        cif_files = list(path.glob("*.cif"))
        
        if not cif_files:
            print(f"No .cif files found in directory: {path}")
            # Clean up the empty folder we just made
            output_dir.rmdir() 
            return

        for cif_file in cif_files:
            output_name = f"POSCAR_{cif_file.stem}"
            output_path = output_dir / output_name
            convert_cif_to_poscar(cif_file, output_path)
            
        print("-" * 30)
        print(f"Finished! Converted {len(cif_files)} files.")

if __name__ == "__main__":
    # Setup command-line arguments
    parser = argparse.ArgumentParser(description="Convert .cif files to VASP POSCAR format.")
    parser.add_argument(
        "target", 
        help="Path to a single .cif file OR a folder containing .cif files."
    )

    args = parser.parse_args()
    process_path(args.target)
