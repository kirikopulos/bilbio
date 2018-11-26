# looktex.awk 
#
# Goes with bin/looktex - look for a keyword in the references in a BiBTeX file
#
# David Kotz (dfk@cs.dartmouth.edu)
#
# This takes a list of line numbers that had the keyword. Some of the
# line numbers will be followed by "entry" or "entry key"; "entry"
# means that the line number is the start of a new bibtex entry, not a
# line containing the keyword. "entry key" means that it is a line
# starting an entry AND containing the keyword.
#
# On stdout, we produce a sed script for printing entries that had a
# match in them somewhere. This is a list of lines like "A,Bp" where A
# and B are line numbers.

BEGIN {found=0; last=1}

# defines the start of a new entry WITH a keyword match
NF==3 {
    if (found) { print last "," $1-1 "p" }
    found=1
    last=$1 
}

# defines the start of a new entry
NF==2 {
    if (found) { print last "," $1-1 "p" }
    found=0
    last=$1
}

# marks a place where the keyword was found
NF==1 {found=1}

END {
    if (found)
        print last ",$p";
}
