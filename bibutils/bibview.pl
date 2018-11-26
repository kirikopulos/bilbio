#!/usr/local/bin/perl
#
# bibview : view a BibTeX database and interactively search through it
# Copyright 1992, Dana Jacobsen (jacobsd@cs.orst.edu)
#
#version = "0.1.0"; # 25 Aug 92  jacobsd  Wrote original version
#version = "0.2.0"; # 25 Aug 92  jacobsd  added options
#version = "0.2.1"; # 26 Aug 92  jacobsd  added options
$version = "0.2.2"; # 26 Aug 92  jacobsd  fast status, command changes
#
# todo: 
#       things in help that are not yet implemented
#       understand multiple bibliographies
#       allow "show 1-10 15"
#       support for AND and OR
#
# All bug-fixes, suggestions, flames, and compliments gladly accepted.
#

$ignorewords = "of and the in a on to for from an with by at as its";
$displaymode = 'brief';
$autoshow = 0;
$sortoutput = 0;

while (@ARGV) {
  $_ = shift @ARGV;
  /^--$/  && do { push(@files, @ARGV); undef @ARGV; next; };
  /^-deb/ && do { $debugging = 1; next; };
  /^-wor/ && do { $worddebug = 1; next; };
  push (@files, $_);
}

# globals:
#
#   $records{$citekey} : the full entry, verbatim
#   $authors{$citekey}   : the author field
#   $titles{$citekey}    : the title field
#   $inauthors{$name}    : a $; seperated list of citekeys
#   $intitles{$word}     : a $; seperated list of citekeys
#
#   @result   : a numbered array with citekeys of last result

print "bibview $version     by Dana Jacobsen, 1992\n";

foreach $infile (@files) {
  &readbibfile($infile);
}

$timetoquit = 0;

until ($timetoquit) {
  print "> ";
  chop($command = <STDIN>);
  $_ = $command;

  if (/^load /i) {
    ($dummy, $infile) = split;
    &readbibfile($infile);
  } elsif (/^write /i) {
    
  } elsif (/^\w+\s*=/i) {
    &handlesearch($command);
    print " -- ", ($#result == 0) ? "1 entry" : 
          ($#result == -1 ? "no" : $#result+1, " entries"), " found.\n";
    $autoshow && &printrecs(0, @result);
  } elsif (s/^and\s+(\w+\s*=)/$1/i) {
    local(%dummyaar);
    local(@dresult) = @result;
    &handlesearch($_);
    grep($dummyaar{$_}++, @dresult);
    @result = grep($dummyaar{$_}, @result);
    print " -- ", ($#result == 0) ? "1 entry" : 
          ($#result == -1 ? "no" : $#result+1, " entries"), " found.\n";
    $autoshow && &printrecs(0, @result);
  } elsif (s/^or\s+(\w+\s*=)/$1/i) {
    local(@iresult, %dummyaar);
    local(@dresult) = @result;
    &handlesearch($_);
    grep($dummyaar{$_}++, @dresult);
    @iresult = grep(!$dummyaar{$_}, @result);
    @result = (@dresult, @iresult);
    print " -- ", ($#result == 0) ? "1 entry" : 
          ($#result == -1 ? "no" : $#result+1, " entries"), " found.\n";
    $autoshow && &printrecs(0, @result);
  } elsif (/^set\s+display\s+brief/i) {
    $displaymode = 'brief';
    print "display mode set to $displaymode.\n";
  } elsif (/^set\s+display\s+(full|bibtex)/i) {
    $displaymode = 'full';
    print "display mode set to $displaymode.\n";
  } elsif (/^set\s+autoshow\s+true/i) {
    $autoshow = 1;
    print "autoshow set to true.\n";
  } elsif (/^set\s+autoshow\s+false/i) {
    $autoshow = 0;
    print "autoshow set to false.\n";
  } elsif (/^set\s+sort\s+true/i) {
    $sortoutput = 1;
    print "output sorting set to true.\n";
  } elsif (/^set\s+sort\s+false/i) {
    $sortoutput = 0;
    print "output sorting set to false.\n";
  } elsif (/^sort/i) {
    @result = &titlesort(@result);
  } elsif (/^status/i) {
    print $#result+1, " records in last search result.\n";
    if ($] > 4.019) {
      print scalar(keys(%records)), " records loaded.\n";
      print scalar(keys(%inauthors)), " unique author last names.\n";
      print scalar(keys(%intitles)), " unique words in titles.\n";
    } else {
      $count = 0; $count++ while each %records;
      print $count, " records loaded.\n";
      $count = 0; $count++ while each %inauthors;
      print $count, " unique author last names.\n";
      $count = 0; $count++ while each %intitles;
      print $count, " unique words in titles.\n";
    }
    print "display mode is $displaymode.\n";
    print "autoshow is ", $autoshow ? "true" : "false", ".\n";
    print "automatic output sorting is ", $sortoutput ? "true" : "false", ".\n";
  } elsif (/^select\s+all/i) {
    @result = sort keys(%records);
  } elsif (/^display\s+authors/i) {
    local(@dresult) = sort keys(%inauthors);
    print join("\n", @dresult), "\n";
  } elsif (/^display\s+titles/i) {
    local(@dresult) = sort keys(%intitles);
    print join("\n", @dresult), "\n";
  } elsif (/^find\s+duplicates/i) {
    &finddups();
  } elsif (/^debug\s+on/i) {
    $debugging = 1;
  } elsif (/^debug\s+off/i) {
    $debugging = 0;
  } elsif (/^(detail|brief|show)/i) {
    $oldmode = $displaymode;
    if (s/^detail\s*//) {
      $displaymode = 'full';
    } elsif (s/^brief\s*//) {
      $displaymode = 'brief';
    } elsif (s/^show\s*//) {
      # nothing
    }
    /^$/ && ($_ = "all");
    foreach $num (split) {
      $debugging && print "$num\n";
      if ($num eq all) {
        &printrecs(0, @result);
      } else {
        &printrecs($num-1, $result[$num-1]);
      }
    }
    $displaymode = $oldmode;
  } elsif (/^quit/i) {
    $timetoquit = 1;
  } elsif (/^(\?|help)/i) {
    print "load <file>          -- load <file>\n";
    print "a=<name>             -- find author exactly matching <name>\n";
    print "a=/<name>            -- find author matching the regex <name>\n";
    print "t=<word>             -- find title containing the word <word>\n";
    print "t=/<word>            -- find title containing the regex <word>\n";
    print "<field> = /<text>    -- find field containing the regex <text>\n";
    print "and <search>         -- logical and the results with <search>\n";
    print "or <search>          -- logical or the results with <search>\n";
    print "set display brief    -- use one line per record when displaying\n";
    print "set display full     -- use BibTeX record when displaying\n";
    print "set autoshow true    -- display results after search\n";
    print "set autoshow false   -- don't display results after search\n";
    print "select all           -- select all records loaded\n";
    print "show   [all | <n>..] -- show <n>th result(s) or all\n";
    print "brief  [all | <n>..] -- display result(s) <n> in brief format\n";
    print "detail [all | <n>..] -- display result <n> in BibTeX format\n";
    print "status               -- show status of bibview\n";
    print "quit                 -- quit bibview\n";
    print "!<command>           -- execute <command> via the shell\n";
    print "-----------------------\n";
    print "not implemented yet:\n";
    print "write <file>         -- write search results to <file>\n";
    print "load all in <subj>   -- load all files in <subj> biblio directory\n";
    print "unload <file>        -- remove entries from <file>\n";
    print "unload all in <subj> -- remove entries from biblios in <subj>\n";
    print "display mode lib     -- display records in tagged field format\n";
    print "delete [all | <n>..] -- delete results from memory\n";
    print "find duplicates      -- selects duplicate entries\n";
  } elsif (/^\s*$/) {
    # nothing
  } elsif (s/^!//) {
     system($_);
  } else {
    print "Unrecognized command.  Use ? for help.\n";
  }
}


########################################
########################################
########################################

sub readbibfile {
  local ($file) = @_;
  local ($num) = 0;
  local ($dups) = 0;
  local ($oldpipe) = $|;

  # this little gem is from Larry Wall -- expand ~user.
  $file =~ s#^(~([a-z0-9]+))(/.*)?$#((getpwnam($2))[7]||$1).$3#e;
  # this is mine -- handle ~/file
  $file =~ s#^(~)(/.*)?$#((getpwnam(getlogin))[7]||$1).$2#e;

  open (IN, $file) || open (IN, "$file.bib") ||
                      ((warn "Can't open $file: $!\n"), return 0);
  $| = 1;
  print "loading $file..";

  while (! eof(IN)) {
    $key = &bibtexread(*IN);

    if ((!$records{$key}) && $key) {
      $num++;
      ($num % 50) || print ".";
      $records{$key} = $entry{FULL};

      $authors{$key} = $entry{author};

      if ($entry{booktitle}) {
        if ($entry{title}) {
          $titles{$key} = $entry{title} . ' in ' . $entry{booktitle};
        } else {
          $titles{$key} = $entry{booktitle};
        }
      } else {
        $titles{$key} = $entry{title};
      }

      foreach $auth (split(/ and /, $entry{author})) {
        $name = &parsename($auth);
        $name =~ tr/A-Za-z0-9\-//cd;   # delete non-alphanumerics
        $name =~ tr/A-Z/a-z/;          # everything lowercase
        $inauthors{$name} .= $; . $key;
      }

      foreach $word (split(/\s+/, $titles{$key})) {
        $word =~ tr/A-Za-z0-9\-//cd;
        $word =~ tr/A-Z/a-z/;
        if ($word && (index($ignorewords, $word) == -1)) {
          if ($worddebug) { print "$word\n"; }
          $intitles{$word} .= $; . $key;
        }
      }
    } else {
      $key && $debugging && print "Duplicate cite key: not adding $key\n";
      $key && $dups++;
    }
  }
  $| = $oldpipe;
  print "$num entries.";
  print $dups ? "  $dups duplicate cite keys.\n" : "\n";
}

########################################
sub handlesearch {
  local($_) = @_;
  local($afield, $lfield, $lvalue, $lval, $cite, $val);
  local(%resaar);
  local(%atolar) = ('a', 'author',
                    't', 'title',
                   );
  @result = ();

  if ( ($afield, $lvalue) = /^(\w)\s*=\s*(.*)$/ ) {
    $lfield = $atolar{$afield};
    if (!$lfield) {
      print "No abbreviation for $afield.  Spell out the field name.\n";
      return;
    }
  } else {
    ($lfield, $lvalue) = /^(\w+)\s*=\s*(.*)$/;
    $lfield =~ tr/A-Z/a-z/;
  }
  $debugging && print "lfield: $lfield, lvalue: $lvalue\n";
  if (substr($lvalue, 0, 1) eq '/') {    # regex search
    substr($lvalue, 0, 1) = '';
    print "$lfield is /$lvalue/";
    if ($lfield eq author) {
      while (($cite, $val) = each %authors) {
        ($val =~ /$lvalue/i) && (push(@result, $cite));
      }
    } elsif ($lfield eq title) {
      while (($cite, $val) = each %titles) {
        ($val =~ /$lvalue/i) && (push(@result, $cite));
      }
    } else {      # long search.  
                  # (this implementation could result in false matches)
      while (($cite, $val) = each %records) {
        ($val =~ /$lfield\s*=.*$lvalue/i) && (push(@result, $cite));
      }
    }
  } else {                              # exact search
    print "$lfield is $lvalue";
    $lvalue =~ tr/A-Za-z0-9\-//cd;
    $lvalue =~ tr/A-Z/a-z/;
    if ($lfield =~ /^author$/) {
      @result = split(/$;/, $inauthors{$lvalue});
    } elsif ($lfield =~ /^title$/) {
      @result = split(/$;/, $intitles{$lvalue});
    } else {
      print " -- Exact matching on $lfield not available.\n";
      return;
    }
    shift @result;
  }
  # weed out any duplicates that might have cropped up
  grep($resaar{$_}++, @result);
  @result = grep($resaar{$_}-- == 1, @result);

  $sortoutput && (@result = &titlesort(@result));
}

########################################
sub titlesort {
  return(sort { $titles{$a} cmp $titles{$b}; } @_);
}
 
########################################
sub printrecs {
  local($cite, $auth, $names);
  local($num) = shift(@_);

  foreach $cite (@_) {
    next if (!$cite);
    $num++;
    $debugging && print "cite: $cite\n";

    if ($displaymode eq full) {
      print $records{$cite}, "\n";
    } else {
      $names = '';
      foreach $auth (split(/ and /, $authors{$cite})) {
        $names .= ', ' . &parsename($auth);
      }
      $names =~ s/^, //;
      $debugging && print ":$num:$names:$titles{$cite}:\n";
      printf "%3d  %-20s  %-50s\n",
             $num,
             substr($names, 0, 20),
             substr($titles{$cite},  0, 50);
    }
  }
}


########################################
# sets @result to a list of citekeys of duplicates
sub finddups {
  local($curtitle);
  local($cite, $ocite, $name);
  local($type, $otype);
  local(@auths, @restauths);
  local(%resaar);

  @result = ();
  foreach $name (keys %inauthors) {
    $debugging && print "$name:";
    @auths = split(/$;/, $inauthors{$name});
    shift @auths;
    @restauths = @auths;
    foreach $cite (@auths) {
      $curtitle = $titles{$cite};
      ($type)  = ($records{$cite}  =~ /^\s*@\s*(\w+)/);
      shift(@restauths);
      foreach $ocite (@restauths) {
        next if $cite eq $ocite;
        ($otype) = ($records{$ocite} =~ /^\s*@\s*(\w+)/);
        next if $type ne $otype;
        next if $curtitle ne $titles{$ocite};
        # author in common, same type, and same title
        push(@result, $cite, $ocite);
      }
    }
  }
  $debugging && print "\n";

  grep($resaar{$_}++, @result);
  @result = grep($resaar{$_}-- == 1, @result);

  print "", ($#result == 0) ? "1 duplicate" : 
        ($#result == -1 ? "no" : $#result+1, " duplicates"), " found.\n";
}

########################################
#
# parsename takes a name in BibTeX format, and parses it into
# parts.  It returns the last name.  The following globals are
# set:
#       $First, $von, $Last, $Jr

sub parsename {
  local($name) = @_;
  local($doinglast) = 0;
  local($part) = 0;
  local($p1, $p2, $p3);
  local($sing, $dummy);

  ($dummy, $sing, $dummy) = $name =~ /(^|\s){(.*)}(\s|$)/;
  $name =~ s/(^|\s){(.*)}(\s|$)/$1ASingleNameString$3/;
  $First = $von = $Last = $Jr = '';

  ($p1, $p2, $p3) = split(/,/, $name, 3);
  if ($p3) {
    $First = $p3;
    $Jr = $p2;
    if ($p1 =~ s/^\s*{(.*)}\s*$/$1/) {
      $Last = $p1;
    } else {
      while ($p1 =~ /^[a-z]/) {
        ($part) = $p1 =~ /^(\S+)/;
        $p1 =~ s/^(\S+)\s*//;
        $von .= ' ' . $part;
      }
      $Last = $p1;
    }
  } elsif ($p2) {
    $First = $p2;
    if ($p1 =~ s/^\s*{(.*)}\s*$/$1/) {
      $Last = $p1;
    } else {
      while ($p1 =~ /^[a-z]/) {
        ($part) = $p1 =~ /^(\S+)/;
        $p1 =~ s/^(\S+)\s*//;
        $von .= ' ' . $part;
      }
      $Last = $p1;
    }
  } else {
    if ($p1 =~ s/^\s*{(.*)}\s*$/$1/) {
      $Last = $p1;
    } else {
      while ($p1 =~ /^[A-Z]/) {
        ($part) = $p1 =~ /^(\S+)/;
        $p1 =~ s/^(\S+)\s*//;
        $First .= ' ' . $part;
      }
      while ($p1 =~ /^[a-z]/) {
        ($part) = $p1 =~ /^(\S+)/;
        $p1 =~ s/^(\S+)\s*//;
        $von .= ' ' . $part;
      }
      if ($p1) {
        $Last = $p1;
      } else {
        ($Last) = $First =~ /\s+(\S+)\s*$/;
        $First =~ s/\s+\S+\s*$//;
      }
    }
  }
  $Last =~ s/ASingleNameString/$sing/;
  $Last =~  s/^\s+//;
  $von =~   s/^\s+//;
  $First =~ s/^\s+//;
  $Jr =~    s/^\s+//;
  # handle "et al" or "others"
  if ( (!$Last) && ($von =~ /^(others|et\.?\s*al)\.?$/i) ) {
     $Last = "others";
     $von = '';
  }
  if ($debugging) {
    $name =~ s/ASingleNameString/$sing/;
    $name =~  s/^\s+//;
    printf "%20s: %-15s %-10s %-20s %-10s\n", $name, $First, $von, $Last, $Jr;
  }
  return ($Last);
}


########################################
#
# split out the field parsing into a seperate routine.
# so we read in verbatim, then call &bibtexexplode to seperate
# into %entry.
#
sub bibtexread {
  local(*FILE) = @_;
  local($braces) = 1;
  local($ent, $delim);
  local($field, $value, @values);
  
  %entry = ();

  while (<FILE>) {
    last if /^\s*@/;
  }
  if (!/,/) {         # preamble is split on multiple lines
    $ent = $_;
    while (<FILE>) { 
      $ent .= $_;
      last if /,/;
    }
    $_ = $ent;
  }
  return 0 if eof(FILE);
  return 0 if /^\s*@\s*string/i;
  return 0 if /^\s*@\s*preamble/i;
  $ent = $_;
  ( ($entry{type}, $delim, $entry{citekey})
    = /^\s*@\s*(\w+)\s*([{(])\s*(\S+)\s*,\s*$/)
  || do { print "Error getting line: $_\n"; return 0; };
  $debugging && print $entry{type}, $delim, $entry{citekey}, "\n";
  if ($delim eq '{') {
    while (<FILE>) {
      $ent .= $_;
      $braces += s/{/{/g;
      $braces -= s/}/}/g;
      last if ($braces <= 0);
    }
    $entry{FULL} = $ent;
    $ent =~ s/}\s*$//;
  } else {
    while (<FILE>) {
      $ent .= $_;
      last if $ent =~ s/[)]\s*$//;
    }
    $entry{FULL} = $ent . ')';
  }
  $ent =~ s/\s+/ /g;
  @values = split(/,\s*(\w+)\s*=\s*/, $ent);
  $debugging && print join("//", @values), "\n";
  shift(@values);  # zap the beginning info
  while (@values) {
    $field = shift(@values);
    $field =~ tr/A-Z/a-z/;
    $value = shift(@values);
    $value =~ s/^\s*{(.*)}\s*$/$1/;
    $value =~ s/^\s*"(.*)"\s*$/$1/;
    $entry{$field} = $value;
  }
  return($entry{citekey});
}

