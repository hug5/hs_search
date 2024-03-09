#!/bin/env bash

#------------------------------------------
### hs_search.sh : history search
#------------------------------------------

  # // 2022-03-18 Fri 06:35
  # // 2022-04-04 Mon 09:33
  # // 2022-10-24 Mon 17:52  # removed fzy search by default;
  # // 2024-01-27 Sat 01:46  # space bug fix; check that xclip can be run; can't on remote servers;

  # history with fuzzy search, fzf
  # This is meant to be a replacement for c-r command; reverse search;
  # Example:
  # $ hs mount  # will prefilter for 'mount' keyword
  # $ hs  # no prefilter; just start typing
  # This will then save into clipboard and history

  # Enable bracket paste in .bashrc
  # bind 'set enable-bracketed-paste on'
    # this prevents auto execution when command is pasted in;

  # TODO:
    # allow -d <search>
    # Figure out why this doesn't work here:
      # local NAME=`echo $0 | awk -F/ '{print $NF}'`
    # shows up "bash"


#------------------------------------------
### Conf
#------------------------------------------

# Location of bash hs file
# BHISTORYLOG="$HOME/.bash_history";
# BHISTORYLOG="$HISTFILE";



#------------------------------------------
### Code
#------------------------------------------


# Check that the script is being called as "source"
# Not sure how $PS1 variable checks that it's run as source; apepars that if not run
# as source, then PS1 is an empty string; Otherwise contains some value;
if [ -z "$PS1" ]; then
  echo "This script must be sourced. Use \"source <script>\" instead."
  exit
fi
# Something about $PS1 :
# https://www.gnu.org/software/bash/manual/html_node/Is-this-Shell-Interactive_003f.html
# "It is unset in non-interactive shells, and set in interactive shells."

###
  #function hs_help() {
  #  echo "Usage: hs [option] [filter]"
  #  echo ""
  #  echo "  [no option]   Search Mode"
  #  echo "  -d, --delete  Delete Mode"
  #  echo "  -h, --help    Help"
  #  echo ""
  #  echo "Examples:"
  #  echo "  hs          Search mode"
  #  echo "  hs rsync    Search mode; filter by 'rsync'"
  #  echo "  hs -d       Delete mode; then press tab to select"
  #  echo ""
  #}

function show_help() {
cat << EOF
hs history search

SYNOPSIS
  Search your shell history efficiently.

FLAG OPTIONS
  [ search ]        Enter Search
  -d, --delete      Enter Delete
  -h, --help        Display this help

FUZZY SEARCH
  By default, fuzzy search is disabled.
  To enable, precede word with single quote (').

EXAMPLES
  $ hs -h           Show help
  $ hs              Enter search. Then type search characters. Enter to select.
  $ hs rsync        Search for 'rsync'. Enter to select.
  $ hs ^rsync d$    Search beginning with 'rsync', ending with 'd'.
  $ hs 'rsync       Search 'rsync' using fuzzy search.
  $ hs -d           Delete history. Press tab to select for deletion. Enter to delete.

EOF
}


function hs_delete() {

  local USELECTED
  USELECTED=$(echo "$BHISTORY" | fzf -m --exact --tac $HS_STYLE)
    # We echo the history file we created and pass to fzf;
    # --tac : reverse order of input; want newest at bottom; but doesn't really appear that way? Nweest commands don't seem to appear;
    # -m : multi select
    # --exact : disable fuzzy search; to enable, prepend search word with ' (single quote); eg: 'alacrty 'tme

  echo "$CALLED_COMMAND" >> $HISTFILE

  # If selected nothing, then return
  if [[ -z "$USELECTED" ]] ; then
    return
  fi

  # https://helpmanual.io/builtin/readarray/
  # readarray -d $'\n' -t strarr <<< "$USELECTED"
  # mapfile is alias to readarray
  # -t : Remove a trailing delim (default newline) from each line read.
  # <<< : It redirects the string to stdin of the command.
  # By default, the -d value is new line!; don't need it, actually;
  # So this parses the string by new line into the array;
  local strarr
  readarray -t strarr <<< "$USELECTED";

  # Get # of elements in array
  COUNT=${#strarr[*]};

  # Output DELETED: to terminal; then we'll output the deleted lines
  echo "DELETE ($COUNT):"

  local STR='';

  # for (( n=0; n < ${#strarr[*]}; n++)); do
  for (( n=0; n < $COUNT; n++ )); do

    STR="${strarr[n]}";
    # Print line we're deleting
    echo "$STR";

    # Escape special characters: *, [, \ and /
    # I would presume that the order would count?
    # don't want to create \ and then escape it?
    if [[ $STR == *\\* ]]; then
      STR=$(echo "$STR" | sed "s/\\\/\\\\\\\/g");
        # Escape / character
    fi
    if [[ $STR == *\** ]]; then
      STR=$(echo "$STR" | sed "s/\\*/\\\\\\*/g");
        # The * is another special character!!
    fi
    if [[ $STR == *\[* ]]; then
      STR=$(echo "$STR" | sed "s/\\[/\\\\\\[/g");
        # the [ character
    fi
    if [[ $STR == *\/* ]]; then
      STR=$(echo "$STR" | sed "s/\\//\\\\\\//g");
        # The / slash, since we're using that for our delimiter;
    fi



    # Checking for the string before doing the sed regex seems to speed things up;

    # There should be a way to escape multiple characters in an or search
    # The sed regex doesn't have to be double-quoted (single quotes don't work);
    # or I don't think it does; but it heops with the editor highlighting;
    # the [ character seems to screw up the editor;
    # Can't figure out how to quote *\[* so that the editor doesn't
    # get screwed up; so just leaving it;

    # search for the string and delete it from history file;
    sed -i /^"$STR"$/d $HISTFILE;
      # It's probably very inefficient to write to file each time there is a delete!!

    # Was trying to edit a variable instead... not working
    # BHISTORY=sed s/^"$STR"$//g <<< "$BHISTORY"
    # BHISTORY=sed "s/$STR//g" <<< "$BHISTORY"

  done

  history -c;history -r
}

function hs_search() {

  if [[ -n "$PARAM_ALL" ]]; then
      PARAM_ALL="$PARAM_ALL "
  fi

  local USELECTED
  USELECTED=$(echo "$BHISTORY" | grep -v ^"$CALLED_COMMAND"$ | fzf $HS_STYLE --exact --tac --query="$PARAM_ALL")
  # Quoting "$HS_STYLE" doesn't work; not sure why;
  # local USELECTED=$(echo "$BHISTORY" | fzf --tac --query="$PARAM_ALL")
    # We echo the history file we created and pass to fzf;
    # --tac : reverse order of input; want newest at bottom; but doesn't really appear that way? Nweest commands don't seem to appear;
    # --query= : catch the user's input; use that as initial filter;
    # --exact : disable fuzzy search; to enable, prepend search word with ' (single quote); eg: 'alacrty 'tme
    # grep -v : exclude the command we just called; don't make visible; the called
    # command will be 'hs <something>'; exclude this exact phrase; we're not excluding
    # the <something>, but the 'hs <something>';
    # $HS_STYLE in double quotes don't seem to work; not sure why;

  # if $USELECTED variable is not null, then copy to clipboard
  if [[ -n "$USELECTED" ]]; then

    # copy selection to clipboard
    # echo $USELECTED | xclip && echo $USELECTED
    # Use this with >>
    # echo -n "$USELECTED" | xclip
    # echo -n "$USELECTED" | xclip -selection p
      # ON remote systems, this seems to cause an error;
      # I also don't remember why I did this???
      # see xclip_notes.txt

    # Check that xclip command exists and can be called;
    # If so, then copy selection to copy buffer; if not, then do nothing;
    # if command xclip <<< "" &>/dev/null; then
    #     echo -n "$USELECTED" | xclip -selection c
    # fi
      # On use, auto copying to buffer may not be such a great idea; screws up
      # copies I make that I want to paste into terminal;

      # Let's copy the text to clipboard; why didn't I do this originallly?
      # This still doesn't work on remote servers; have to enable X11 forwarding on SSH;

      # -selection primary :
        # specify which X selection to use 
        # options are : "primary" to use XA_PRIMARY (default)
        #             : "secondary" for XA_SECONDARY 
        #             : "clipboard" for XA_CLIPBOARD 
        # Can also substitute with abbreviations; 
        # eg, p for primary; c for clipboard; or clip; sec; etc; anything reasonable, it seems;
          
          # 1. p, primary
            # Cannot ctrl-shift-v!
          # 2. sec, secondary
            # Cannot ctrl-shift-v!
          # 3. c, clip, clipboard
            # Can ctrl-shift-v with this option


      # xclip -o # supposed to output clipboard to line, but simiilar to echo
      # Was trying to see if I could just auto paste into terminal; doesn't work
      # But can just execute doing below:
      # $USELECTED
      # But also get an error if there's # comment in the command;
      # The shortcoming of this is that it doesn't go into history;

      # So figured out a way to add our selection to the bash history log; then user can just up arrow or paste as well;
      # I could use tee or >>>; chose to use tee, because then that precludes the need to echo out anything separately as originally above;

    # Put called command and selected into history
    #local ENTRY=$CALLED_COMMAND$'\n'$USELECTED
    local ENTRY="$CALLED_COMMAND"$'\n'"$USELECTED"
    echo "$ENTRY" >> "$HISTFILE"
    history -c; history -r
    #####################################


    # Output to prompt
    IFS= read -rei "$USELECTED" -p "${PS1@P}" NEW_USELECTED
    # *** If we go below this, it means user pressed enter! ***
    # *** The script should pause here and wait for user input ***

    # Save user's entry
    # local ENTRY=$CALLED_COMMAND$'\n'$NEW_USELECTED
    ENTRY="$NEW_USELECTED"
    echo "$ENTRY" >> "$HISTFILE"
    ##########################

    # local ENTRY="$CALLED_COMMAND\n$USELECTED"
    # local ENTRY=$CALLED_COMMAND$'\n'$USELECTED
    # local ENTRY="$CALLED_COMMAND"
    # ENTRY+=$'\n'
    # ENTRY+="$USELECTED"

    # pass our selection to tee or append to history
    # echo "$USELECTED" | tee -a $HISTFILE
    # echo "$ENTRY" | tee -a $HISTFILE
      # This unforutnately outputs both CALLED_COMMAND and USELECTED
    # echo "$USELECTED"  # xxxxxxxxxxx removed
    # echo "$ENTRY" >> $HISTFILE  #xxxxxxxxxxxxxxxxxxx
      # tee will output the selection as well
      # echo $USELECTED >> "$HISTFILE"
      # >> doesn't output selection; so then would have to echo out earlier

    history -c; history -r  # Have to save into history before calling the line
    eval "$NEW_USELECTED"   # run the command


  else
    echo "$CALLED_COMMAND" >> "$HISTFILE"
    history -c; history -r  # Need to add here since removed below
  fi

  # clear our history; reload history from log; which then allows user access to that command with up-arrow;
  # history -c; history -r   # xxxxxxxxx removed

}



# $0 : Name of file; Just returns '-bash'
# $1, $2, $3 : The 1st, 2nd, 3rd argument, if passed
# $* : To catch all parameters as a single string; Like this: $1$2"
# $@ : equivalent to, "$1" "$2"; quotes each separately;
# https://linux.die.net/man/1/bash
# Catch user arguments
# PARAM_ALL=$*
# PARAM_ALL="$*"
PARAM_ALL=$(echo -n "$*" | xargs)
# How to catch the # character??
# Remove any spaces

# Help parameter
if [[ "$PARAM_ALL" == "-h" ]] || [[ "$PARAM_ALL" == "--help" ]]; then
  #hs_help
  show_help
  return 0
fi

# The script that was invoked, but not the original command
# echo $BASH_SOURCE;

# This gives us the original command in history; then awk the command; exclude options;
# Don't know how to get everything but the # field
CALLED_COMMAND=$(history 1 | awk '{print $2}')
  # 14524 hs -d  <--- so want to get everything after the line#; but dont' know how;
  # So getting the 2nd field, the hs;
  # Then add back the parameter to the originall called command;
  # We'll then exclude this in our fzw search;
  # This way, the caled command doesn't have to be deleted from history
  # -n : string is not empty; not null;
if [[ -n "$PARAM_ALL" ]]; then
  CALLED_COMMAND+=" $PARAM_ALL"
fi

# Remove last key entries, ie, hs call; we'll put it back in later;
history -d -1
  # NO longer need to delete the last entry; just hide it temporarily
# add pending history to bash_history file
history -a


# load history in reverse; remove # entries; remove duplicates
# BHISTORY=$(tac $HISTFILE | grep -v ^# | grep -v ^"$KEXCLUDE *" | awk '!a[$0]++')
# BHISTORY=$(tac $HISTFILE | grep -v ^# | grep -v ^"$CALLED_COMMAND"$ | awk '!a[$0]++')
# BHISTORY=$(tac $HISTFILE | grep -v ^# | grep -vw "$CALLED_COMMAND" | awk '!a[$0]++')
BHISTORY=$(tac "$HISTFILE" | grep -v ^# | awk '!a[$0]++');
#
  # Not sure if the -vw search is giving me what I intend; has the effect of removing all historical commands, not just the most recent; so if there is 'hs awk' in the history; and I enter 'hs awk', then 'hs awk' can't be found'; Also creates the unfortunate situation that as I type in hs -d, it goes into history; but I can never delete it! because it's filtered away;
  # This is also flawed in that if I call hs, then hs will show up because the CALLED_COMMAND expects a paramter; and there's a space there; so actually need to check for null before concatating;

  # grep -vw "$CALLED_COMMAND"
    # -w : whole word match;
    # -v : inverse match;
  # grep -v ^#
    # Also could have used: awk '!/^#/' :
    # ^# means to match # at start of line.
    # ! in awk, and -v in grep negate the match.
    # I'd prefer to do an "or" expression for the grep commands...
  # grep -v ^"$KW *"
    # This also works: grep -v ^"$KW"; combine with variable: local KW='hs *' or local KW='hs\s*'
    # Want to exclude all history that begins with 'hs', which is the call to this function
    # Seems have to use double quotes; single quote not work; and no quote not work for variable;
    # the regex is it begins with hs, followed by a space (can use actual space or \s);
    # and the space can be 0 or more times, denoted by *;

  # 2 ways to remove duplicates: awk and sort+uniq; not sure which is faster; awk feels faster!
  # awk '!a[$0]++' :
    # removes duplicates; the 'a' is supposed to be a variable;
    # see awk notes on duplicates;
    # If duplicate, then don't output out; so effectively gets deleted;
  # sort : sort the list; prepares for uniq, which only checks adjacent duplicates
  # uniq : filter duplicates; but only if adjacent!! So have to sort first to use!

  # **These 2 have been removed; using the --query flag for fzf instead;
  # awk /$PARAM_ALL/ :
    # This is the prefilter if user passed a paramter
    # Doing something like, fzf --tac -f $1, doesn't work; that's not interactive;
    # Keep in mind that the awk filter is order sensitive, unlike fzf;
    # So if you do, "hs rsync --partial --progress", it will filter for exactly that order;
    # But if you did "hs rsync", and then enter "--partial --progress", fzf does a fuzzy search instead;
    # and the keywords can be in any order, anywhere;
  # grep -E "$PARAM_ALL"
    # This is more of an anywhere search, unlike the awk above; more like a fuzzy;
  # use tac to get reverse order for cat

# Reverse the order again to correct order
# <<< Feeding the string to stdin for tac command;
BHISTORY=$(tac <<< "$BHISTORY")
# BHISTORY+=$'\n';

# fzf styling; see man fzf; set border; set margin (seems to be in percentage);
# set the bottom prompt; and set first line above # found;
HS_STYLE='--border --margin=1 --prompt=:  --header=————————————————————————————————'
  # Get error if try to put quotes around header with spaces in the dash;

# Delete parameter
if [[ "$PARAM_ALL" == "-d" ]] || [[ "$PARAM_ALL" == "--delete" ]]; then

  hs_delete "$PARAM_ALL";

# Run normal history search function
else
  hs_search "$PARAM_ALL";
fi
