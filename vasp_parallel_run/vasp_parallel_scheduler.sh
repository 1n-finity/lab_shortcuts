#!/bin/bash

RUNVASP_SCRIPT="$HOME/lab_shortcuts/runvasp.sh"

INPUT_LOG="$(pwd)/vasp_run_files.log"
OUTPUT_LOG="$(pwd)/vasp_run_results.log"

# --- CONFIGURATION ---
REQUIRED_MEM_MB=3500
ALLOCATION_DELAY=120
EARLY_FAIL_THRESHOLD=240 
# ---------------------

if [[ ! -f "$INPUT_LOG" ]]; then
    echo "Error: Cannot find input list at '$INPUT_LOG'"
    exit 1
fi

if [[ ! -x "$RUNVASP_SCRIPT" ]]; then
    echo "Error: Cannot find or execute the VASP script at '$RUNVASP_SCRIPT'."
    exit 1
fi

check_gpu_memory() {
    local max_free
    max_free=$(nvidia-smi --query-gpu=memory.free --format=csv,noheader,nounits | sort -nr | head -n 1)
    
    if [[ -n "$max_free" && "$max_free" -ge "$REQUIRED_MEM_MB" ]]; then
        return 0 
    else
        return 1 
    fi
}

run_and_log() {
    local target_dir="$1"
    cd "$target_dir" || exit
    
    local start_time=$(date +%s)
    
    "$RUNVASP_SCRIPT"
    local exit_code=$? 
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [[ $duration -lt $EARLY_FAIL_THRESHOLD ]]; then
        echo "[FAILED_EARLY] (${duration}s) | $target_dir" >> "$OUTPUT_LOG"
        echo "[!] Job stopped unusually fast (${duration}s): $target_dir"
    elif [[ $exit_code -ne 0 ]]; then
        echo "[ERROR_CRASH] (Code: $exit_code) | $target_dir" >> "$OUTPUT_LOG"
        echo "[!] Job crashed with exit code $exit_code: $target_dir"
    else
        echo "[SUCCESS] (${duration}s) | $target_dir" >> "$OUTPUT_LOG"
        echo "[DONE] Job completed successfully: $target_dir"
    fi
}

echo "Starting Parallel VASP GPU Scheduler..."
echo "Config: ${REQUIRED_MEM_MB}MB required, ${ALLOCATION_DELAY}s buffer, ${EARLY_FAIL_THRESHOLD}s early-fail threshold."

# FIX 1: Use file descriptor 3 (3<) instead of standard input (<)
while IFS= read -u 3 -r folder_path || [[ -n "$folder_path" ]]; do
    
    if [[ -z "$folder_path" || ! -d "$folder_path" ]]; then
        continue
    fi

    echo "------------------------------------------------"
    echo "Preparing to submit: $folder_path"
    
    while ! check_gpu_memory; do
        echo "Not enough GPU memory. Retrying in 30 seconds..."
        sleep 30
    done

    echo "Memory available! Submitting job to background..."
    
    # FIX 2: Block mpirun from eating inputs by redirecting from /dev/null
    run_and_log "$folder_path" < /dev/null &
    
    echo "Job submitted. Waiting ${ALLOCATION_DELAY} seconds for memory allocation to register..."
    sleep "$ALLOCATION_DELAY"

done 3< "$INPUT_LOG"

echo "------------------------------------------------"
echo "All jobs have been submitted to the queue."
echo "Waiting for all active background calculations to finish..."

wait 

echo "All batches are 100% complete."
