#!/bin/bash

export TOM2ROOT=$HOME/tom2
export CCACHE_DIR=$TOM2ROOT/ccache;
export NAVKIT_DATASET=$HOME/sync/maps/navkit;

##################################
# Define some helpers for colors #
##################################

export SetColorToRED='\033[0;31m';
export SetColorToLightRED='\033[1;31m';
export SetColorToYELLOW='\033[0;33m';
export SetColorToLightYELLOW='\033[1;33m';
export SetColorToGREEN='\033[0;32m';
export SetColorToLightGREEN='\033[1;32m';
export SetColorToBLUE='\033[0;34m';
export SetColorToLightBLUE='\033[1;34m';
export SetColorToWHITE='\033[0;37m';
export SetNoColor='\033[0m';

alias du='du -h --max-depth=1 -BM 2> /dev/null'
alias gls='git log --stat'
alias gst='git status -uno'
alias nocolor="sed 's/\x1B\[[0-9;]*[JKmsu]//g'"

function getLabelForCurrentDirectory()
{
  local pattern=$(echo $TOM2ROOT/ | nocolor | sed 's/\//\\\//g');
  pwd | sed 's/'$pattern'/@/g';
}

function getLabelForGitCurrBranch() { git branch 2> /dev/null | grep '\*' | awk -F' ' '{printf " # "$2}'; }

PS1="\n\[${SetColorToBLUE}\][\$(getLabelForCurrentDirectory)\[${SetColorToLightBLUE}\]\$(getLabelForGitCurrBranch)\[${SetColorToBLUE}\]]$ \[${SetNoColor}\]";
