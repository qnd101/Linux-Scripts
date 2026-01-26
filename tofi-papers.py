#!/bin/env python3
import csv
import subprocess
import sys

PAPER_DIR = '/mnt/Data/CQM/Resources/Papers'
CSV_PATH = "/mnt/Data/CQM/Resources/papers_cache.csv"

def get_formatted_refs(file_path, column_width=30):
    """Parses CSV and returns the entire formatted string."""
    lines = []
    try:
        with open(file_path, mode='r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                # Combine Author and Year
                author_year = f"{row['Author']}{row['Year']}"
                # Format with alignment
                line = f"{author_year:<{column_width}} {row['Title']} {row['DOI']}"
                lines.append(line)
    except Exception as e:
        return f"Error reading file: {e}"

    return "\n".join(lines)

# 1. Generate the formatted string
formatted_output = get_formatted_refs(CSV_PATH, column_width=20)

# 2. Spawn another process and pipe the output into it
# Change 'cat' to 'less', 'fzf', 'sort', or your specific script
result = subprocess.run(
        ['tofi', '--width', '1000', '--height', '250', '--prompt-text', 'Papers: '],
        input=formatted_output,
        capture_output=True,
        text=True,
        ).stdout.strip('\n')

if result == "":
    exit(1)
doi = result.split(' ')[-1].replace('/', '_')
file = f'{PAPER_DIR}/{doi}.pdf'
print(file)

choices = ["Open", "Copy Path", "Copy URL"]
choice = subprocess.run(
        ['tofi', '--prompt-text', 'Action: '],
        input='\n'.join(choices),
        capture_output=True,
        text=True,
        ).stdout.strip('\n')
if choice == choices[0]:
    subprocess.Popen(
        ['xdg-open', file],
        stdout=subprocess.DEVNULL, # Redirect stdout to /dev/null
        stderr=subprocess.DEVNULL, # Redirect stderr to /dev/null
        stdin=subprocess.DEVNULL,  # Redirect stdin to /dev/null
        start_new_session=True     # Detach the process from the current session
    )
elif choice == choices[1]:
    subprocess.run('wl-copy', input=file, text=True)
elif choice == choices[2]:
    subprocess.run(['wl-copy', '-t', 'text/uri-list'], input='file://'+file, text=True)

