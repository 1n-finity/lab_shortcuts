#!/bin/bash

# 1. Print overall GPU Memory Summary (Once per GPU)
echo "=== GPU Memory Status ==="
printf "%-6s %-12s %-12s\n" "GPU" "TOTAL" "FREE"
printf "%-6s %-12s %-12s\n" "---" "-----" "----"

nvidia-smi --query-gpu=index,memory.total,memory.free --format=csv,noheader,nounits | while IFS=',' read -r idx total free; do
    # Remove any stray spaces
    idx="${idx// /}"
    total="${total// /}"
    free="${free// /}"
    
    # Print GPU stats
    printf "%-6s %-12s %-12s\n" "$idx" "${total}MiB" "${free}MiB"
done
echo ""

# 2. Print Active Processes
echo "=== Active Processes ==="
printf "%-10s %-15s %-12s %-20s\n" "PID" "USER" "USED_MEM" "COMMAND"
printf "%-10s %-15s %-12s %-20s\n" "---" "----" "--------" "-------"

# Get app data from nvidia-smi
nvidia-smi --query-compute-apps=pid,used_gpu_memory --format=csv,noheader,nounits | while IFS=',' read -r pid mem; do
    
    # Remove any stray spaces
    pid="${pid// /}"
    mem="${mem// /}"
    
    if [ -n "$pid" ]; then
        # Get user and command using ps
        user=$(ps -o user= -p "$pid" 2>/dev/null || echo "N/A")
        comm=$(ps -o args= -p "$pid" 2>/dev/null | cut -d' ' -f1 || echo "N/A")
        
        # Print formatted output
        printf "%-10s %-15s %-12s %-20s\n" "$pid" "$user" "${mem}MiB" "$comm"
    fi
done
