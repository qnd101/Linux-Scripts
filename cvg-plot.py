#!/usr/bin/env python3
import sys
import subprocess
import numpy as np

if len(sys.argv) > 1:
    filename = sys.argv[1]
else:
    print("Provide .dat file!")
    exit(1)

def load_gnuplot_matrix(filename):
    """
    Loads a gnuplot 3D data file into a 3D NumPy array.
    Assumes blocks are separated by single blank lines.
    """
    # Load all numeric data, ignoring blank lines for a moment
    raw_data = np.loadtxt(filename)
    
    # To find the dimensions, we count the number of lines 
    # before the first blank line.
    with open(filename, 'r') as f:
        first_block_size = 0
        for line in f:
            if line.strip() == "":
                if first_block_size > 0:
                    break
            else:
                first_block_size += 1
    # Calculate dimensions
    # num_blocks = total_rows / rows_per_block
    num_blocks = raw_data.shape[0] // first_block_size
    
    # Reshape to (Blocks, Rows_per_block, Columns)
    return raw_data.reshape((num_blocks, first_block_size, -1))

arr = load_gnuplot_matrix(filename)
ocont = arr[0,:,0]
func = arr[:,:,2]
diff = np.abs(func[1:,:] - func[:-1,:])
diffmax = np.max(diff, 1)
diffarea = np.trapezoid(diff, ocont)
plotdata = np.stack([diffmax, diffarea]).transpose()

# Open gnuplot process
gp = subprocess.Popen(['gnuplot', '-p'], stdin=subprocess.PIPE, text=True)
assert(gp.stdin)
# Send commands and data
gp.stdin.write('set terminal qt persist font "Sans,14,Bold"\n')
gp.stdin.write("set grid\n")
gp.stdin.write("set logscale y\n")
gp.stdin.write('set format y "%.1e"\n')
gp.stdin.write('set xlabel "Iteration"\n')
gp.stdin.write('set ylabel "Change"\n')
gp.stdin.write("set title 'Convergence'\n")

gp.stdin.write("plot '-' using ($0+1):1 with lines title 'L^∞', '-' using ($0+1):1 with lines title 'L^1'\n")
# Write the matrix data
gp.stdin.write("\n".join(map(str, diffmax)))
gp.stdin.write("\ne\n") # 'e' tells gnuplot the data stream has ended

gp.stdin.write("\n".join(map(str, diffarea)))
gp.stdin.write("\ne\n") # 'e' tells gnuplot the data stream has ended
gp.stdin.flush()
