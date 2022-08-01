#!/bin/bash

export TOM2ROOT=$HOME/tom2
source $TOM2ROOT/myDevEnvScripts/common_setup.sh;

export CCACHE_DIR=$TOM2ROOT/ccache;
export NAVKIT_DATASET=$HOME/sync/maps/navkit;

function getLabelForCurrentDirectory()
{
  local pattern=$(echo $TOM2ROOT/ | nocolor | sed 's/\//\\\//g');
  pwd | sed 's/'$pattern'/@/g';
}

function getLabelForGitCurrBranch() { git branch 2> /dev/null | grep '\*' | awk -F' ' '{printf " # "$2}'; }

PS1="\n\[${SetColorToBLUE}\][\$(getLabelForCurrentDirectory)\[${SetColorToLightBLUE}\]\$(getLabelForGitCurrBranch)\[${SetColorToBLUE}\]]$ \[${SetNoColor}\]";
