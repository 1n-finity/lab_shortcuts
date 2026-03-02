#!/bin/bash

echo "Scanning for completed VASP optimizations..."
echo "-----------------------------------"

# 1. Find all OUTCAR files recursively
find . -type f -name "OUTCAR" | sort | while read -r filepath; do
    
    # Get the directory path for the current OUTCAR
    dir_path=$(dirname "$filepath")
    
    # Safeguard 1.: Skip if this OUTCAR is already inside a "DOS" folder
    if [[ "$dir_path" == *"/DOS"* ]] || [[ "$dir_path" == *"DOS" ]]; then
        continue
    fi

    # Safeguard 2.: Skip if this OUTCAR is already inside a "LOBSTER" folder
    if [[ "$dir_path" == *"/LOBSTER"* ]] || [[ "$dir_path" == *"LOBSTER" ]]; then
        continue
    fi
    
    # 2. Check if the optimization completed successfully
    if grep -q "reached required accuracy" "$filepath"; then
        echo "Processing: $dir_path -> Optimization complete."
        
        # 3. Create the DOS directory
        mkdir -p "$dir_path/DOS"
        
        # 4. Copy and rename required files
        # Check if CONTCAR exists and is not empty
        if [ -s "$dir_path/CONTCAR" ]; then
            cp "$dir_path/CONTCAR" "$dir_path/DOS/POSCAR"
        else
            echo "  [!] Error: CONTCAR missing or empty in $dir_path. Skipping."
            continue
        fi
        
        # Copy POTCAR and KPOINTS if they exist
        for file in POTCAR KPOINTS; do
            if [ -f "$dir_path/$file" ]; then
                cp "$dir_path/$file" "$dir_path/DOS/"
            else
                echo "  [!] Warning: $file not found in $dir_path."
            fi
        done
        
        # 5. Generate the INCAR file inside the DOS folder
        cat << 'EOF' > "$dir_path/DOS/INCAR"
# SCF input for VASP
# Note that VASP uses the FIRST occurence of a keyword
SYSTEM = MoSSe
SYSTEM = 2N-doped Graphene
ENCUT = 450
EDIFF = 1E-5
IBRION = -1
NSW = 0
ISMEAR = -5
SIGMA = 0.2
ISPIN = 2
LWAVE = .FALSE.
LCHARG = .TRUE.
PREC = normal
ALGO = FAST
EDIFFG = -0.01
NELM = 60
NELMIN = 4
ISTART = 0
ICHARG = 2
LORBIT = 11
EOF
        echo "  [✓] DOS setup finished for $dir_path."
        
    else
        # Optimization not complete or still running
        echo "Skipping: $dir_path -> Optimization not complete."
    fi

done

echo "-----------------------------------"
echo "Done!"
