# bibkey.sed
#
# Goes with bin/bibkey - look for a word in the keyword entry 
#
# David Kotz (dfk@cs.dartmouth.edu)
#
# On stdin, we get a lowercased bibtex file with comments stripped.
#
# On stdout, we produce a list of line numbers that are the starting
# line number of each reference, and the text of all "keyword"
# entries on separate lines.

# the idea is to get @ line numbers and all keywords
# @ entry
/^[ 	]*@.*/=
# one-line keyword entry
s/[ 	]*keyword[ 	]*=[ 	]*"\(.*\)".*/\1/p
t 
# start of multi-line keyword entry
s/[ 	]*keyword[ 	]*=[ 	]*"\(.*\)/\1/
t partial
b
# Handle multi-line keyword entry: save this line, repeatedly add
# lines until close quote forces output
:partial
N
s/\(.*\n.*\)".*/\1/
t done
b partial
:done
s/\n/ /g
p
