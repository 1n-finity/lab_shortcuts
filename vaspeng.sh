#!/bin/bash

# 1. Define the output CSV file name
OUTPUT_FILE="energies.csv"

# 2. Write the CSV Header
echo "Name,Energy" > "$OUTPUT_FILE"

echo "Scanning for completed VASP optimizations..."
echo "-----------------------------------"

# 3. Find all OUTCAR files recursively and loop through them
find . -type f -name "OUTCAR" | sort | while read -r filepath; do
    
    # Get the directory path and create a clean name
    dir_path=$(dirname "$filepath")
    safe_name="${dir_path#./}"
    
    if [ "$safe_name" == "." ]; then
        safe_name="current_folder"
    fi
    
    # 4. Check if the optimization completed successfully
    if grep -q "reached required accuracy" "$filepath"; then
        
        # Extract the energy using tail to get the final step
        energy=$(grep "energy(sigma->0)" "$filepath" | tail -n 1 | awk '{print $NF}')
        
        # Check if energy was actually found
        if [ ! -z "$energy" ]; then
            # Write to CSV: Safe Folder Name, Energy Value
            echo "${safe_name},${energy}" >> "$OUTPUT_FILE"
            echo "  [✓] Extracted: $safe_name -> $energy"
        else
            echo "  [!] Warning: No energy found in completed $filepath"
        fi
        
    else
        # Optimization not complete or still running
        echo "  [-] Skipping: $safe_name -> Optimization not complete."
    fi

done

echo "-----------------------------------"
echo "Done! Converged energies saved to $OUTPUT_FILE"
