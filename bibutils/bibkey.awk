# bibkey.awk 
#
# Goes with bin/bibkey - look for a word in the keyword entry 
#
# David Kotz (dfk@cs.dartmouth.edu)
#
# On stdin, we get a list of line numbers of the beginning of entries
# (in the concatenated bibtex input) and the text of lines from keyword
# entries  that have the keyword in them.
#
# On stdout, we produce a sed script for printing entries that had a
# match in them somewhere. This is a list of lines like "A,Bp" where A
# and B are line numbers.

BEGIN {found=0; last=1}

{
# test: is line a number?
    if ($1+0 > 0) {
	       if (found) {
	              print last "," $1-1 "p";
	              found=0
	       }
	       last=$1
    } else {
	   found = 1
    }
}

END {
    if (found)
        print last ",$p";
}
