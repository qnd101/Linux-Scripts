# Assign the arguments to variable
datafile = ARG1
itstart = ARG2 # Start value of iter
itend = ARG3 # End value of iter

# Scan the file to find out how many iterations (blocks) it has
stats datafile u 1:3 nooutput
N = STATS_blocks

# Set negative values if itstart, itend as positive
if (itstart < 0) {
    itstart = N + itstart;
}
if (itend < 0) {
    itend = N + itend;
}

# 3. Setup the visual style
set terminal qt persist
set grid

set xrange [ARG4:ARG5]
set yrange [ARG6:ARG7]
set xlabel ARG8
set ylabel ARG9

if (itend-itstart>=1) {
    set cbrange [itstart:itend]
    set palette defined (itstart "grey", itend-1 "blue", itend "red")
}
else {
    set palette defined (itstart "red", itend "red")
}
unset colorbox

plot for [i=itstart:itend] datafile index i using 1:3 \
     with lines lc palette cb i \
     lw 0.5 \
     title ((i == itend) ? ("iter=" . i) : (i == itstart) ? ("iter=" . i) : "" )
