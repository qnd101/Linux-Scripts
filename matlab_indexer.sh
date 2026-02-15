#!/bin/sh

index_path="$HOME/.config/nvim/data/matlab_functions.txt"

matlab_dir='/mnt/Data/Projects/MATLAB'
qspace_dir="$matlab_dir/QSpace_v4"
munrg_dir="$matlab_dir/MuNRG"

fdfind --max-depth 1 '.m$' --format '{/.}' \
    "$qspace_dir/Class/@QSpace" \
    "$qspace_dir/bin" \
    "$qspace_dir/setup" \
    "$munrg_dir/Util" \
    "$munrg_dir/NRG" \
    "$munrg_dir/DMFT" \
    > "$index_path"
