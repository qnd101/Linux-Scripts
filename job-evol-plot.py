#!/usr/bin/env python3
from asyncio.base_tasks import _task_print_stack
import sys
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
            subprocess.run([str(sync_script)])

    # 4. Process Job Data
    try:
        with open(job_data_path, 'r') as f:
            data = json.load(f)
            # Extract project names from the nested JSON structure
            projects = [job['projName'] for job in data.get('jobs', [])]
    except (json.JSONDecodeError, KeyError, FileNotFoundError):
        print("Error: Could not parse job JSON.")
        sys.exit(1)

    fzf_lines = []

    for proj in projects:
        base_path = calc_mu / proj
        evol_dir = base_path / "evol"
        results_dir = base_path / "results"
        jobinfo_dir = base_path / "jobinfo"

        if not evol_dir.is_dir():
            continue

        # Get 'evol' files: strip 'RhoV2_' and extension
        # Equivalent to: fdfind --base-directory ... --format '{/.}' | sed 's/^RhoV2_//'
        evol_items = {
            f.stem.replace("RhoV2_", "") 
            for f in evol_dir.glob("RhoV2_*.dat")
        }

        # Filter out finished jobs unless --all is set
        if not args.all and results_dir.is_dir():
            # Get 'results' files: strip 'result_' and extension
            finished_items = {
                f.stem.replace("result_", "") 
                for f in results_dir.glob("result_*.mat")
            }
            evol_items -= finished_items

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

            running_items = set();
            for job_id, task_ids in job_dict.items():
                # Load json for job
                jobinfo_path = jobinfo_dir / f'job_{job_id}.json'
                with open(jobinfo_path, 'r') as f:
                    jobinfo = json.load(f)
                    for task_id in task_ids:
                        running_items.update(jobinfo[int(task_id)-1]["targets"])
            evol_items = evol_items.intersection(running_items)

        # Format for FZF display
        for item in sorted(evol_items):
            # ANSI Green for project name, Reset/White for the job ID
            line = f"\033[32m{proj:<30}\033[37m {item}"
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
    # selection looks like: "project_name                job_id"
    parts = selection.split()
    if len(parts) < 2:
        sys.exit(0)
    
    selected_proj, selected_job = parts[0], parts[1]
    # Reconstruct the specific .dat file path
    sel_path = calc_mu / selected_proj / "evol" / f"RhoV2_{selected_job}.dat"
    
    print(f"Selected: {selection}")
    print(f"Path: {sel_path}")

    # Launch gnuplot in the background
    gnuplot_script = home / "scripts/ghost-plot.gnuplot"
    if gnuplot_script.exists():
        gnuplot_cmd = ["gnuplot", "-c", str(gnuplot_script), str(sel_path)] + unknown_args
        subprocess.Popen(gnuplot_cmd)

        # 7. Update window title (Sway specific)
        sway_cmd = f"sleep 1 && swaymsg '[app_id=\"gnuplot_qt\"] title_format \"gnuplot: {sel_path}\"'"
        subprocess.Popen(sway_cmd, shell=True)
    else:
        print(f"Gnuplot script not found at {gnuplot_script}")

if __name__ == "__main__":
    main()
