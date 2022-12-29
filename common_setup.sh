#!/bin/bash

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

function download()
{
    for count in 1 .. 3
    do
        wget --no-check-certificate --retry-connrefused --waitretry=1 --read-timeout=15 --timeout=15 -t 2 --continue --no-dns-cache $1

        if [ $? = 0 ];
        then
            break
        fi

        sleep 1s;
    done
}

function mountVmwareShares()
{
    sudo /usr/bin/vmhgfs-fuse .host:/ $HOME/sync -o subtype=vmhgfs-fuse,allow_other
}

# Löscht Datei (oder Ordner), wenn sie älter als eine Woch ist.
# arg 1 = Datei oder Ordner
function removeIfOlderThanOneWeek()
{
    let week=7*24*3600;
    local now=$(date +%s);
    let weekAgo=now-week;
    local timestamp=$(stat -c%Z $1);

    if [ $timestamp -lt $weekAgo ];
    then
        printf "Löscht: $1\n";
        rm -rf $1;
    fi
}

function cleanUpConanCache()
{
    cd $HOME/.conan/data;
    echo "# !/bin/bash" > clean_up_script.sh;
    echo "source $HOME/ct" >> clean_up_script.sh;
    find . -maxdepth 2 -type d | grep -v "map-nds-" | grep --color=never '\.[0-9][0-9]*$' >> clean_up_script.sh;
    sed -i 's|\./|removeIfOlderThanOneWeek |g' clean_up_script.sh;
    chmod +x clean_up_script.sh;
    ./clean_up_script.sh;
}

function getLabelForCurrentDirectory()
{
  local pattern=$(echo $SSD/ | nocolor | sed 's/\//\\\//g');
  pwd | sed 's/'$pattern'/@/g';
}

function getLabelForGitCurrBranch() { git branch 2> /dev/null | grep '\*' | awk -F' ' '{printf " # "$2}'; }

PS1="\n\[${SetColorToYELLOW}\][\$(getLabelForCurrentDirectory)\[${SetColorToLightYELLOW}\]\$(getLabelForGitCurrBranch)\[${SetColorToYELLOW}\]]$ \[${SetNoColor}\]";

alias ll='ls -la --color=always'
alias du='du -h --max-depth=1 -BM 2> /dev/null'
alias gls='git log --stat'
alias gst='git status -uno'
alias nocolor="sed 's/\x1B\[[0-9;]*[JKmsu]//g'"

alias %cmake="find . -type f | grep 'CMakeLists.txt$\|CMakeAddon.txt\|.cmake$' | grep -v 'Build/Output/'";
findInCMake() { %cmake | xargs grep --color=always -n "$@" | sed -e 's/[ \t]\+/ /'; }
alias @cmake=findInCMake;

alias %cpp="find . -type f | grep '\.h$\|\.hpp$\|\.c$\|\.cpp$'";
findInCpp() { %cpp | xargs grep --color=always -n "$@" | sed -e 's/[ \t]\+/ /'; }
alias @cpp=findInCpp;

alias %sql="find . -type f | grep '\.sql$'";
findInSql() { %sql | xargs grep --color=always -in "$@" | sed -e 's/[ \t]\+/ /'; }
alias @sql=findInSql;

alias %xml="find . -type f | grep '\.xml$'";
findInXml() { %xml | xargs grep --color=always -in "$@" | sed -e 's/[ \t]\+/ /'; }
alias @xml=findInXml;

alias %gxl="find . -type f | grep '\.gxl$'";
findInGxl() { %gxl | xargs grep --color=always -in "$@" | sed -e 's/[ \t]\+/ /'; }
alias @gxl=findInGxl;

alias %idl="find . -type f | grep '\.rid$'";
findInIdl() { %idl | xargs grep --color=always -in "$@" | sed -e 's/[ \t]\+/ /'; }
alias @idl=findInIdl;

alias %java="find . -type f | grep '\.java$'";
findInJava() { %java | xargs grep --color=always -n "$@" | sed -e 's/[ \t]\+/ /'; }
alias @java=findInJava;

alias %kotlin="find . -type f | grep '\.kt$'";
findInKotlin() { %kotlin | xargs grep --color=always -n "$@" | sed -e 's/[ \t]\+/ /'; }
alias @kotlin=findInKotlin;

alias %json="find . -type f | grep '\.json$'";
findInJson() { %json | xargs grep --color=always -in "$@" | sed -e 's/[ \t]\+/ /'; }
alias @json=findInJson;

alias %python="find . -type f | grep '\.py$'";
findInPython() { %python | xargs grep --color=always -in "$@" | sed -e 's/[ \t]\+/ /'; }
alias @python=findInPython;

alias %kml="find . -type f | grep '\.kml$'";

currentDirectoryName() { pwd | rev | cut -d/ -f1 | rev; }
