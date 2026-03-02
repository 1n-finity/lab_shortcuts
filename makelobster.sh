#!/bin/bash

echo "Scanning for completed VASP optimizations..."
echo "-----------------------------------"

# 1. Find all OUTCAR files recursively
find . -type f -name "OUTCAR" | sort | while read -r filepath; do
    
    # Get the directory path for the current OUTCAR
    dir_path=$(dirname "$filepath")
    
    # Safeguard 1.: Skip if this OUTCAR is already inside a "LOBSTER" folder
    if [[ "$dir_path" == *"/LOBSTER"* ]] || [[ "$dir_path" == *"LOBSTER" ]]; then
        continue
    fi

    # Safeguard 2.: Skip if this OUTCAR is already inside a "DOS" folder
    if [[ "$dir_path" == *"/DOS"* ]] || [[ "$dir_path" == *"DOS" ]]; then
        continue
    fi

    
    # 2. Check if the optimization completed successfully
    if grep -q "reached required accuracy" "$filepath"; then
        echo "Processing: $dir_path -> Optimization complete."
        
        # 3. Extract the original NBANDS from OUTCAR and calculate the new value
        nbands_orig=$(grep -m 1 "NBANDS" "$filepath" | awk '{print $NF}')

        if [ -z "$nbands_orig" ]; then
            echo "  [!] Error: Could not extract NBANDS from OUTCAR in $dir_path. Skipping."
            continue
        fi
        
        # Multiply by 2
        nbands_new=$((nbands_orig * 2))
        
        # 4. Create the LOBSTER directory
        mkdir -p "$dir_path/LOBSTER"
        
        # 5. Copy and rename required files
        if [ -s "$dir_path/CONTCAR" ]; then
            cp "$dir_path/CONTCAR" "$dir_path/LOBSTER/POSCAR"
        else
            echo "  [!] Error: CONTCAR missing or empty in $dir_path. Skipping."
            continue
        fi
        
        for file in POTCAR KPOINTS; do
            if [ -f "$dir_path/$file" ]; then
                cp "$dir_path/$file" "$dir_path/LOBSTER/"
            else
                echo "  [!] Warning: $file not found in $dir_path."
            fi
        done
        
        # 6. Generate the INCAR file inside the LOBSTER folder using the new template
        cat << EOF > "$dir_path/LOBSTER/INCAR"
ALGO = Normal
PREC   = Normal
ISPIN  = 2

NBANDS = $nbands_new

LREAL = Auto
NSW    = 0
NELMIN = 4

ISMEAR = 0
EDIFF = 1e-05
ISYM = -1
EOF
        echo "  [✓] LOBSTER setup finished for $dir_path (NBANDS set to $nbands_new)."
        
    else
        echo "Skipping: $dir_path -> Optimization not complete."
    fi

done

echo "-----------------------------------"
echo "Done!"
