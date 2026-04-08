import json
import os
import subprocess
import traceback
from datetime import datetime

# Use StateDirectory managed by systemd
LOG_DIR = os.getenv('STATE_DIRECTORY', '/var/lib/power-logger')
LOG_FILE = os.path.join(LOG_DIR, "power-logger.jsonl")

def get_cpu_count():
    try:
        return os.cpu_count() or 1
    except Exception:
        return 1

def get_battery():
    try:
        # Assuming BAT0, which is common for ThinkPads
        with open("/sys/class/power_supply/BAT0/capacity", "r") as f:
            capacity = int(f.read().strip())
        with open("/sys/class/power_supply/BAT0/power_now", "r") as f:
            power_nw = int(f.read().strip())
        status = None
        if os.path.exists("/sys/class/power_supply/BAT0/status"):
            with open("/sys/class/power_supply/BAT0/status", "r") as f:
                status = f.read().strip()
        return capacity, power_nw / 1_000_000.0, status
    except Exception:
        # traceback.print_exc() # Too noisy if on AC
        return None, None, None

def get_cpu_governor():
    try:
        # Check cpu0 as a representative
        with open("/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor", "r") as f:
            return f.read().strip()
    except Exception:
        traceback.print_exc()
        return None

def get_cpu_idle_states_per_cpu():
    # Reading /sys/devices/system/cpu/cpu*/cpuidle/state*/time
    all_states = {}
    try:
        # Get all CPU directories and sort them numerically
        cpu_dirs = [d for d in os.listdir("/sys/devices/system/cpu") if d.startswith("cpu") and d[3:].isdigit()]
        cpu_dirs.sort(key=lambda x: int(x[3:]))
        for cpu_dir in cpu_dirs:
            cpu_path = os.path.join("/sys/devices/system/cpu", cpu_dir, "cpuidle")
            if not os.path.exists(cpu_path):
                continue
            
            states = {}
            for state_dir in sorted(os.listdir(cpu_path)):
                state_path = os.path.join(cpu_path, state_dir)
                if not os.path.isdir(state_path):
                    continue
                
                try:
                    with open(os.path.join(state_path, "name"), "r") as f:
                        name = f.read().strip()
                    with open(os.path.join(state_path, "time"), "r") as f:
                        time_us = int(f.read().strip())
                    states[name] = time_us
                except Exception:
                    continue
            all_states[cpu_dir] = states
        return all_states
    except Exception:
        traceback.print_exc()
        return {}

def get_gpu_freq():
    try:
        res = subprocess.run(["intel_gpu_frequency", "--get"], capture_output=True, text=True)
        for line in res.stdout.splitlines():
            if "cur:" in line:
                return line.split(":")[1].strip()
    except Exception:
        pass

    for card in ["card0", "card1"]:
        path = f"/sys/class/drm/{card}/gt_cur_freq_mhz"
        if os.path.exists(path):
            try:
                with open(path, "r") as f:
                    return f.read().strip() + " MHz"
            except Exception:
                continue
    return None

def get_last_log():
    if not os.path.exists(LOG_FILE):
        return None
    try:
        with open(LOG_FILE, "rb") as f:
            f.seek(0, os.SEEK_END)
            size = f.tell()
            if size == 0: return None
            
            # Read last few lines to find last valid entry
            seek_pos = max(0, size - 32768) # Even larger buffer for safety
            f.seek(seek_pos)
            lines = f.readlines()
            
            # Iterate backwards to find the last non-empty line
            for line in reversed(lines):
                line_str = line.decode().strip()
                if not line_str:
                    continue
                try:
                    return json.loads(line_str)
                except json.JSONDecodeError:
                    # If the very last line is partially written, skip it and try the previous one
                    continue
    except Exception:
        traceback.print_exc()
    return None

def main():
    now = datetime.now()
    cpu_count = get_cpu_count()
    battery_percent, wattage, battery_status = get_battery()
    current_idle_states_per_cpu = get_cpu_idle_states_per_cpu()
    last_log = get_last_log()

    cpu_idle_percentages_per_cpu = None
    if last_log and "cpu_idle_states_us" in last_log and "timestamp" in last_log:
        try:
            last_ts = datetime.fromisoformat(last_log["timestamp"])
            last_states_per_cpu = last_log["cpu_idle_states_us"]
            elapsed_us = (now - last_ts).total_seconds() * 1_000_000
            
            if elapsed_us > 0:
                cpu_idle_percentages_per_cpu = {}
                for cpu, current_states in current_idle_states_per_cpu.items():
                    if cpu in last_states_per_cpu:
                        last_states = last_states_per_cpu[cpu]
                        cpu_pcts = {}
                        total_idle_delta = 0
                        for state, curr_val in current_states.items():
                            if state in last_states:
                                delta = curr_val - last_states[state]
                                if delta < 0: delta = 0 
                                cpu_pcts[state] = round((delta / elapsed_us) * 100, 2)
                                total_idle_delta += delta
                        
                        active_pct = 100 - (total_idle_delta / elapsed_us) * 100
                        cpu_pcts["C0_active"] = round(max(0, active_pct), 2)
                        cpu_idle_percentages_per_cpu[cpu] = cpu_pcts
        except Exception:
            traceback.print_exc()

    data = {
        "timestamp": now.isoformat(),
        "battery_percent": battery_percent,
        "battery_status": battery_status,
        "wattage": wattage,
        "cpu_governor": get_cpu_governor(),
        "cpu_idle_states_us": current_idle_states_per_cpu,
        "cpu_idle_percentages": cpu_idle_percentages_per_cpu,
        "gpu_freq": get_gpu_freq(),
        "cpu_count": cpu_count
    }

    with open(LOG_FILE, "a") as f:
        f.write(json.dumps(data, separators=(',', ':')) + "\n")

if __name__ == "__main__":
    main()
