import subprocess
import time
import requests
import os
from dotenv import load_dotenv

# --- CONFIGURATION ---
load_dotenv()
WEBHOOK_URL = os.getenv("discord_url")
POLL_INTERVAL = 30     # How often to check the cluster (seconds)
MATURITY_DELAY = 45    # How long a job must survive before alerting (seconds)

# Safety check
if not WEBHOOK_URL:
    raise ValueError("Error: 'discord_url' not found. Please check your .env file.")

def send_discord_alert(message):
    """Sends the formatted message to Discord."""
    data = {"content": message}
    try:
        response = requests.post(WEBHOOK_URL, json=data)
        if response.status_code == 429:
            print("Rate limited by Discord. Waiting before retry...")
            time.sleep(2)
            requests.post(WEBHOOK_URL, json=data)
    except Exception as e:
        print(f"Webhook failed: {e}")

def get_nvuse_data():
    """Executes the nvuse.sh script and captures the output."""
    script_path = os.path.expanduser("~/lab_shortcuts/nvuse.sh")
    try:
        result = subprocess.run(["bash", script_path], capture_output=True, text=True)
        return result.stdout
    except Exception as e:
        print(f"Failed to run nvuse.sh: {e}")
        return ""

def parse_nvuse_output(output):
    """Parses memory availability and active jobs from nvuse output."""
    available_mem = "Memory info not found"
    current_jobs = {}
    
    lines = output.strip().split('\n')
    parsing_processes = False
    
    for line in lines:
        line = line.strip()
        if not line:
            continue
            
        if "=== Active Processes ===" in line:
            parsing_processes = True
            continue
            
        if not parsing_processes:
            parts = line.split()
            if len(parts) >= 3 and parts[0].isdigit():
                gpu_id = parts[0]
                total_mem = parts[1]
                free_mem = parts[2]
                mem_str = f"GPU {gpu_id}: **{free_mem} Free** / {total_mem} Total"
                
                if available_mem == "Memory info not found":
                    available_mem = mem_str
                else:
                    available_mem += f"\n> {mem_str}"
        else:
            if line.startswith("PID") or line.startswith("---"):
                continue
                
            parts = line.split()
            if len(parts) >= 4 and parts[0].isdigit():
                pid = parts[0]
                user = parts[1]
                used_mem = parts[2]
                command = " ".join(parts[3:])
                
                current_jobs[pid] = {
                    "user": user,
                    "details": f"Mem: {used_mem} | Cmd: {command}"
                }
                
    return available_mem, current_jobs

def monitor():
    print(f"Initializing GPU monitor... (Poll: {POLL_INTERVAL}s, Delay: {MATURITY_DELAY}s)")
    
    # Get baseline state and mark them all as "already alerted"
    _, initial_jobs = parse_nvuse_output(get_nvuse_data())
    current_time = time.time()
    
    # known_jobs now stores: user, details, alerted status, AND the timestamp it was first seen
    known_jobs = {
        pid: {**info, 'alerted': True, 'first_seen': current_time} 
        for pid, info in initial_jobs.items()
    }
    
    while True:
        time.sleep(POLL_INTERVAL)
        output = get_nvuse_data()
        
        if not output:
            continue
            
        available_mem, current_jobs = parse_nvuse_output(output)
        current_time = time.time()
        
        new_jobs_list = []
        completed_jobs_list = []
        next_known_jobs = {}
        
        # 1. Process Active Jobs
        for pid, job_info in current_jobs.items():
            if pid in known_jobs:
                # Job exists. Check its age.
                has_been_alerted = known_jobs[pid]['alerted']
                first_seen = known_jobs[pid]['first_seen']
                job_age = current_time - first_seen
                
                if not has_been_alerted and job_age >= MATURITY_DELAY:
                    # Job has survived past the delay threshold!
                    new_jobs_list.append(f"**PID:** `{pid}` | **User:** `{job_info['user']}`\n> `{job_info['details']}`")
                    has_been_alerted = True
                    
                # Carry it forward
                next_known_jobs[pid] = {**job_info, 'alerted': has_been_alerted, 'first_seen': first_seen}
            else:
                # Brand new job! Record the current time as its 'first_seen' timestamp.
                next_known_jobs[pid] = {**job_info, 'alerted': False, 'first_seen': current_time}
                
        # 2. Process Completed Jobs
        for pid, job_data in known_jobs.items():
            if pid not in current_jobs:
                # Only announce completion if we actually announced it starting
                if job_data['alerted']:
                    completed_jobs_list.append(f"**PID:** `{pid}` | **User:** `{job_data['user']}`")
                    
        # 3. Build and send the Discord message
        if new_jobs_list or completed_jobs_list:
            final_message = ""
            
            if new_jobs_list:
                final_message += "🚀 **New GPU Jobs Running!** *(Stabilized)*\n"
                for job in new_jobs_list:
                    final_message += f"> {job}\n"
                final_message += "\n"
                
            if completed_jobs_list:
                final_message += "✅ **GPU Jobs Completed!**\n"
                for job in completed_jobs_list:
                    final_message += f"> {job}\n"
                final_message += "\n"
                
            final_message += f"📊 **Current Status:**\n> {available_mem}"
            
            send_discord_alert(final_message.strip())
                
        # Update the state tracker for the next loop
        known_jobs = next_known_jobs

if __name__ == "__main__":
    monitor()
