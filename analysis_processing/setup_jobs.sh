#!/bin/bash

# Define directories and files
INPUT_DIR="input_poscar"
OUTPUT_DIR="vasp_jobs"
PATHS_FILE="file_paths.txt"

# Check if the input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Directory '$INPUT_DIR' does not exist."
    exit 1
fi

# Create the main output directory for all jobs
mkdir -p "$OUTPUT_DIR"
echo "Setting up VASP job directories in '$OUTPUT_DIR/'..."

# Initialize/clear the text file to prevent duplicate appending from previous runs
> "$PATHS_FILE"
echo "Tracking absolute paths in '$PATHS_FILE'..."

# Loop through all POSCAR files in the input directory
for filepath in "$INPUT_DIR"/POSCAR_*; do
    
    # Check if files actually exist to avoid loop errors
    if [ ! -e "$filepath" ]; then
        echo "No POSCAR files found in '$INPUT_DIR'."
        exit 0
    fi

    # Extract the filename from the path (e.g., "POSCAR_3N_config_1")
    filename=$(basename "$filepath")
    
    # Remove the "POSCAR_" prefix to get the pure configuration name
    config_name="${filename#POSCAR_}"
    
    # Define the new job folder path
    job_folder="$OUTPUT_DIR/$config_name"
    
    # Create the specific job folder
    mkdir -p "$job_folder"
    
    # COPY the file into the folder and rename it exactly to "POSCAR" (Changed from 'mv' to 'cp')
    cp "$filepath" "$job_folder/POSCAR"
    
    # Get the absolute path of the directory and write it to the file
    abs_path=$(realpath "$job_folder")
    echo "$abs_path" >> "$PATHS_FILE"
    
    echo "Copied to: $job_folder/POSCAR"

done

echo "✅ All POSCAR files have been successfully copied!"
echo "✅ Directory paths have been saved to $PATHS_FILE"
