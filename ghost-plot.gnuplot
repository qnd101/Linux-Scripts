# Assign the arguments to variable
datafile = ARG1
itstart = ARG2 # Start value of iter
itend = ARG3 # End value of iter

# Scan the file to find out how many iterations (blocks) it has
stats datafile u 1:3 nooutput
N = STATS_blocks

# Set negative values if itstart, itend as positive
if (itstart < 0) {
    itstart = N + 1 + itstart;
}
if (itend < 0) {
    itend = N + 1 + itend;
}

# 3. Setup the visual style
set terminal qt persist font "Sans,14,Bold"
set border linewidth 1
set grid

Nshow = itend-itstart+1
if (Nshow>2) {
    set cbrange [itstart:itend]
    set palette defined (itstart "grey", itend-1 "blue", itend "red")
}
else if (Nshow == 2){
    set cbrange [itstart:itend]
    set palette defined (itstart "blue", itend "red")
}
else {
    set palette defined (0 "red", 1 "red")
}
unset colorbox

plot for [i=itstart:itend] datafile index i - 1 using 1:3 \
     with lines lc palette cb i \
     lw 0.5 \
     title ((i == itend) ? ("iter=" . i) : (i == itstart) ? ("iter=" . i) : "" )
