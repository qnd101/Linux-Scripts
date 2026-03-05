# 1. Assign the argument to a variable
datafile = ARG1

# 2. Scan the file to find out how many iterations (blocks) it has
stats datafile u 1:3 nooutput
N = STATS_blocks
Nshow = (ARGC >= 2 && strlen(ARG2) > 0) ? ARG2 : N
if (Nshow > N) {
    Nshow = N
}

# 3. Setup the visual style
set terminal qt persist
set grid

set xlabel "ω"

limit = (ARGC >= 3 && strlen(ARG3) > 0) ? ARG3 : 5
set xrange [-limit:limit]
set ylabel "RhoV2"

set cbrange [0:Nshow-1]
if (Nshow>=2) {
    set palette defined (0 "grey", Nshow-2 "blue", Nshow-1 "red")
}
else {
    set palette defined (0 "red")
}
unset colorbox

plot for [i=N-Nshow:N-1] datafile index i using 1:3 \
     with lines lc palette cb (i - N + Nshow) \
     lw 1 \
     title ((i == N-1) ? ("iter=" . i) : (i == N-Nshow) ? ("iter=" . i) : "" )
