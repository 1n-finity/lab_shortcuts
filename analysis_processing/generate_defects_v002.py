import os
import random
import itertools
import argparse
import numpy as np
import time  
from pymatgen.core import Structure
from pymatgen.io.vasp import Poscar
from pymatgen.symmetry.analyzer import SpacegroupAnalyzer

def main():
    # --- START TIMER ---
    start_time = time.time()
    
    parser = argparse.ArgumentParser(description="Generate substituted structures for DFT using Symmetry Operations.")
    parser.add_argument("-f", "--file", required=True, help="Path to input CIF file")
    parser.add_argument("-t", "--target", required=True, help="Element to substitute (e.g., C)")
    parser.add_argument("-d", "--dopant", required=True, help="Element to insert (e.g., N)")
    parser.add_argument("-n", "--num", type=int, required=True, help="Number of atoms to replace")
    parser.add_argument("-m", "--mode", choices=['single', 'all'], default='all', help="Mode: 'single' (random) or 'all' (symmetry grouped)")
    
    args = parser.parse_args()

    if not os.path.exists(args.file):
        print(f"Error: File '{args.file}' not found.")
        return
    
    struct = Structure.from_file(args.file)
    target_indices = [i for i, site in enumerate(struct) if site.specie.symbol == args.target]
    
    if args.num > len(target_indices):
        print(f"Error: Requested {args.num} substitutions, but only {len(target_indices)} {args.target} atoms exist.")
        return

    os.makedirs("input_cif", exist_ok=True)
    os.makedirs("input_poscar", exist_ok=True)
    
    final_structures = []

    # --- Mode: Single Random ---
    if args.mode == "single":
        chosen_indices = random.sample(target_indices, args.num)
        new_struct = struct.copy()
        for idx in chosen_indices:
            new_struct[idx] = args.dopant
        final_structures.append(new_struct)
        print("Generated 1 random configuration.")

    # --- Mode: All Combinations (Spacegroup Symmetry) ---
    else:
        print("Analyzing parent lattice symmetry...")
        sga = SpacegroupAnalyzer(struct, symprec=0.01)
        symm_ops = sga.get_symmetry_operations()
        print(f"Found {len(symm_ops)} symmetry operations.")

        permutations = []
        frac_coords = struct.frac_coords
        
        for op in symm_ops:
            perm = {}
            for i in target_indices:
                new_coord = op.operate(frac_coords[i])
                for j in target_indices:
                    diff = new_coord - frac_coords[j]
                    diff -= np.round(diff)
                    diff_cart = struct.lattice.get_cartesian_coords(diff)
                    if np.linalg.norm(diff_cart) < 1e-3:
                        perm[i] = j
                        break
            if len(perm) == len(target_indices):
                permutations.append(perm)

        print("Generating and mathematically filtering combinations...")
        unique_combos = set()
        
        for combo in itertools.combinations(target_indices, args.num):
            canonical = tuple(sorted(combo))
            for p in permutations:
                mapped = tuple(sorted(p[idx] for idx in combo))
                if mapped < canonical:
                    canonical = mapped
            unique_combos.add(canonical)
            
        print(f"✅ Found {len(unique_combos)} unique isomers.")
        
        print("Building final 3D structures...")
        for combo in unique_combos:
            s_copy = struct.copy()
            for idx in combo:
                s_copy[idx] = args.dopant
            final_structures.append(s_copy)

    # --- Write Files ---
    print(f"Saving {len(final_structures)} structures...")
    for i, s in enumerate(final_structures):
        name = f"{args.num}{args.dopant}_config_{i+1}"
        s = s.get_sorted_structure()
        s.to(filename=os.path.join("input_cif", f"{name}.cif"))
        Poscar(s).write_file(os.path.join("input_poscar", f"POSCAR_{name}"))

    # --- STOP TIMER AND PRINT ---
    end_time = time.time()
    elapsed_seconds = end_time - start_time
    minutes, seconds = divmod(elapsed_seconds, 60)
    
    print("\n🚀 Success! Files saved.")
    print(f"⏱️  Total Python execution time: {int(minutes)}m {seconds:.2f}s")

if __name__ == "__main__":
    main()
