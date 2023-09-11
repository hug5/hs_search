#!/bin/env bash

# // 3/22
# // 2022-04-04 Mon 09:33

# Location of bash history file
BHISTORYLOG="$HOME/.bash_history";


hs_help() {
  echo "Usage: hs [option] [filter]"
  echo ""
  echo "  [no option]   Search Mode"
  echo "  -d, --delete  Delete Mode"
  echo "  -h, --help    Help"
  echo ""
  echo "Examples:"
  echo "  hs          Search mode"
  echo "  hs rsync    Search mode; filter by 'rsync'"
  echo "  hs -d       Delete mode; then press tab to select"
  echo ""
}


hs_delete() {

  local USELECTED=$(echo "$BHISTORY" | fzf -m --tac)
    # We echo the history file we created and pass to fzf;
    # --tac : reverse order of input; want newest at bottom; but doesn't really appear that way? Nweest commands don't seem to appear;
    # -m : multi select

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
  echo "DELETED:"

  local STR=''
  # for (( n=0; n < ${#strarr[*]}; n++)); do
  for (( n=0; n < $COUNT; n++)); do

    STR="${strarr[n]}";
    # Print line we're deleting
    echo "$STR";

    # Escape special characters: *, [ and /
    STR=$(echo "$STR" | sed "s/\\*/\\\\\\*/g");
      # The * is another special character!!
    STR=$(echo "$STR" | sed "s/\\[/\\\\\\[/g");
      # the [ character
    STR=$(echo "$STR" | sed "s/\\//\\\\\\//g");
      # The / slash, since we're using that for our delimiter;

    # There should be a way to escape multiple characters in an or search
    # The sed regex doesn't have to be double-quoted (single quotes don't work);
    # or I don't think it does; but it heops with the editor highlighting;
    # the [ character seems to screw up the editor;

    # search for the string and delete it from history file;
    sed -i /^"$STR"$/d $BHISTORYLOG;

  done

  history -c;history -r
}

hs_search() {

  local USELECTED=$(echo "$BHISTORY" | fzf --tac --query="$PARAM_ALL")
    # We echo the history file we created and pass to fzf;
    # --tac : reverse order of input; want newest at bottom; but doesn't really appear that way? Nweest commands don't seem to appear;
    # --query= : catch the user's input; use that as initial filter;

  # if $USELECTED variable is not null, then copy to clipboard
  if [[ -n "$USELECTED" ]]; then

    # copy selection to clipboard
    # echo $USELECTED | xclip && echo $USELECTED
    # Use this with >>
    echo "$USELECTED" | xclip
      # Use this with tee command

      # xclip -o # supposed to output clipboard to line, but simiilar to echo
      # Was trying to see if I could just auto paste into terminal; doesn't work
      # But can just execute doing below:
      # $USELECTED
      # But also get an error if there's # comment in the command;
      # The shortcoming of this is that it doesn't go into history;

      # So figured out a way to add our selection to the bash history log; then user can just up arrow or paste as well;
      # I could use tee or >>>; chose to use tee, because then that precludes the need to echo out anything separately as originally above;


    # local ENTRY="$CALLED_COMMAND\n$USELECTED"

    # pass our selection to tee or append to history
    echo "$USELECTED" | tee -a $BHISTORYLOG
    # echo "$ENTRY" | tee -a $BHISTORYLOG
      # tee will output the selection as well
      # echo $USELECTED >> "$BHISTORYLOG"
      # >> doesn't output selection; so then would have to echo out earlier

  # else
  #   local ENTRY="$CALLED_COMMAND"
  #   echo "$ENTRY" >> $BHISTORYLOG
  fi

  # clear our history; reload history from log; which then allows user access to that command with up-arrow;
  history -c; history -r

}

# $1, $2, $3 : The 1st, 2nd, 3rd argument, if passed
# $* : To catch all parameters as a single string:
# Catch user arguments
PARAM_ALL=$*;

# Help parameter
if [[ $PARAM_ALL == "-h" ]] || [[ $PARAM_ALL == "--help" ]]; then

  hs_help
  return
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
CALLED_COMMAND+=" $PARAM_ALL"

# Remove last key entries, ie, hs call; we'll put it back in later;
# history -d -1
  # NO longer need to delete the last entry; just hide it temporarily
# add pending history to bash_history file
history -a


# load history in reverse; remove # entries; remove duplicates
# BHISTORY=$(tac $BHISTORYLOG | grep -v ^# | grep -v ^"$KEXCLUDE *" | awk '!a[$0]++')
# BHISTORY=$(tac $BHISTORYLOG | grep -v ^# | awk '!a[$0]++');
# BHISTORY=$(tac $BHISTORYLOG | grep -v ^# | grep -v ^"$CALLED_COMMAND"$ | awk '!a[$0]++')
BHISTORY=$(tac $BHISTORYLOG | grep -v ^# | grep -vw "$CALLED_COMMAND" | awk '!a[$0]++')
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
BHISTORY=$(tac <<< $BHISTORY);
# BHISTORY+=$'\n';


# Delete parameter
if [[ $PARAM_ALL == "-d" ]] || [[ $PARAM_ALL == "--delete" ]]; then

  hs_delete $PARAM_ALL;

# Run normal history search function
else
  hs_search $PARAM_ALL;
fi
