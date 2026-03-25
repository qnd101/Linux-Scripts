#!/usr/bin/env python3
from asyncio import Condition
from asyncio.base_tasks import _task_print_stack
import sys
import os
import json
import subprocess
import argparse
from pathlib import Path
from collections import defaultdict

def main():
    # 1. Setup Arguments
    parser = argparse.ArgumentParser(description="Shows info for (not finished) jobs")
    parser.add_argument("-r", "--renew", action="store_true", help="Renew/Sync job files")
    parser.add_argument("-a", "--all", action="store_true", help="Show all jobs")
    parser.add_argument("-c", "--cvg", action="store_true", help="Show convergence info")
    args, unknown_args = parser.parse_known_args()

    # 2. Paths
    home = Path.home()
    job_data_path = home / "remote-jobs.json"
    calc_mu = Path("/mnt/Data/CQM/Calc/MuNRG")

    if not job_data_path.exists():
        print(f"Error: {job_data_path} not found.")
        sys.exit(1)

    # 3. Sync if requested
    if args.renew:
        sync_script = home / "scripts/job-file-sync.sh"
        if sync_script.exists():
            subprocess.run([str(sync_script), '--nosend'])

    # 4. Process Job Data
    try:
        with open(job_data_path, 'r') as f:
            data = json.load(f)
            # Extract project names from the nested JSON structure
            projects = [job['projName'] for job in data.get('jobs', [])]
    except (json.JSONDecodeError, KeyError, FileNotFoundError):
        print("Error: Could not parse job JSON.")
        sys.exit(1)

    # Find running jobs
    if not args.all:
        cmd = f'ssh {data['remote']} "sacct --state=RUNNING --format=JobID -n"'
        output = subprocess.check_output(cmd, shell=True, text=True)
        job_dict = defaultdict(list)
        for line in output.strip().splitlines():
            entry = line.strip()
            if not entry.endswith(".b+"):
                job_id, task_id = entry.split(".")[0].split("_")
                job_dict[job_id].append(task_id)

    fzf_lines = []

    for proj in projects:
        base_path = calc_mu / proj
        evol_dir = base_path / "evol"
        results_dir = base_path / "results"
        jobinfo_dir = base_path / "jobinfo"

        if not evol_dir.is_dir():
            continue

        evol_items = defaultdict(list);
        for f in evol_dir.glob("*.dat"):
            functype, hashedName = tuple(f.stem.split('_', 1))
            evol_items[hashedName].append(functype)

        # Filter out finished jobs unless --all is set
        if not args.all and results_dir.is_dir():
            # Get 'results' files: strip 'result_' and extension
            for f in results_dir.glob("result_*.mat"):
                hashedName = f.stem.replace("result_", "") 
                if hashedName in evol_items:
                    del evol_items[hashedName]

        # Find running jobs
        if not args.all:
            targets = [];
            for job_id, task_ids in job_dict.items():
                # Load json for job
                jobinfo_path = jobinfo_dir / f'job_{job_id}.json'
                if not os.path.exists(jobinfo_path):
                    continue;
                with open(jobinfo_path, 'r') as f:
                    jobinfo = json.load(f)
                    if not isinstance(jobinfo, list):
                        jobinfo = [jobinfo]
                    for task_id in task_ids:
                        targets.extend(jobinfo[int(task_id)-1]["targets"])

            for key in list(evol_items.keys()):
                if key not in targets:
                    del evol_items[key] # Use the del keyword to remove the item

        # Format for FZF display
        for hashedName, functypes in evol_items.items():
            for functype in functypes:
            # ANSI Green for project name, Reset/White for the job ID
                header = f"\033[32m{proj} \033[33m{functype}\033[37m"
                line = f"{header:<50} {hashedName}"
                fzf_lines.append(line)

    if not fzf_lines:
        print("No pending jobs found.")
        sys.exit(0)

    # 5. Interactive Selection (FZF)
    try:
        fzf_proc = subprocess.run(
            ["fzf", "--ansi"],
            input="\n".join(fzf_lines),
            text=True,
            capture_output=True
        )
        selection = fzf_proc.stdout.strip()
    except FileNotFoundError:
        print("Error: fzf is not installed.")
        sys.exit(1)

    if not selection:
        sys.exit(0)

    # 6. Parse Selection and Execute Plot
    # selection looks like: "project_name function_type               job_id"
    parts = selection.split()
    if len(parts) < 3:
        sys.exit(0)
    
    selected_proj, selected_func, selected_job = parts[0], parts[1], parts[2]
    # Reconstruct the specific .dat file path
    sel_path = calc_mu / selected_proj / "evol" / f"{selected_func}_{selected_job}.dat"
    
    print(f"Selected: {selection}")
    print(f"Path: {sel_path}")

    # Launch gnuplot in the background
    if args.cvg:
        gnuplot_script = home / "scripts/cvg-plot.py"
    else:
        gnuplot_script = home / "scripts/ghost-plot.lua"
    if gnuplot_script.exists():
        gnuplot_cmd = [str(gnuplot_script), str(sel_path)] + unknown_args
        subprocess.Popen(gnuplot_cmd)

        # 7. Update window title (Sway specific)
        sway_cmd = f"sleep 1 && swaymsg '[app_id=\"gnuplot_qt\"] title_format \"gnuplot: {sel_path}\"'"
        subprocess.Popen(sway_cmd, shell=True)
    else:
        print(f"Gnuplot script not found at {gnuplot_script}")

if __name__ == "__main__":
    main()
