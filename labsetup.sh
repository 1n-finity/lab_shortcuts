#!/bin/bash

# Define directories
SHORTCUTS_DIR="$HOME/lab_shortcuts"
BASHRC_FILE="$HOME/.bashrc"

echo "Setting up shortcuts from $SHORTCUTS_DIR..."
echo "-----------------------------------"

# 1. Check if the lab_shortcuts directory exists
if [ ! -d "$SHORTCUTS_DIR" ]; then
    echo "Error: Directory '$SHORTCUTS_DIR' does not exist."
    echo "Please create it and move your scripts there first."
    exit 1
fi

# 2. Loop through all files in the directory
for filepath in "$SHORTCUTS_DIR"/*; do
    
    # Skip if it's a directory or not a regular file
    [ -f "$filepath" ] || continue
    
    # 3. Make the file executable
    chmod +x "$filepath"
    
    # Get the raw filename (e.g., "makedos.sh")
    filename=$(basename "$filepath")
    
    # Strip the extension to create a clean alias name (e.g., "makedos")
    alias_name="${filename%.*}"
    
    # Formulate the alias string
    alias_line="alias $alias_name='$filepath'"
    
    # 4. Check if the alias already exists in .bashrc
    # Using regex ^alias name= to ensure we match the exact alias definition
    if grep -q "^alias ${alias_name}=" "$BASHRC_FILE"; then
        echo "  [-] Alias '$alias_name' already exists in .bashrc. Skipping."
    else
        # Append the new alias to .bashrc
        echo "$alias_line" >> "$BASHRC_FILE"
        echo "  [✓] Added alias '$alias_name' -> $filepath"
    fi

done

echo "-----------------------------------"
echo "Setup complete!"
echo ""
echo "IMPORTANT: To activate your new shortcuts right now, run the following command in your terminal:"
echo "source ~/.bashrc"
