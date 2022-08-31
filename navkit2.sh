#!/bin/bash

if [ "$(hostname)" = "de3lxl-111986" ];
then
  # tomtom laptop:
  export SSD=/tom2;
else
  export SSD=$HOME/tom2;
  # WSL:
  #export DISPLAY="$(hostname):0.0"
fi

source $SSD/myDevEnvScripts/common_setup.sh;

export NK2_REPOS_ROOT=$SSD/nk2;
export JAVA_HOME=/usr/local/pkg/java/adoptopenjdk11-bin
export PATH=/usr/local/pkg/bin:/usr/local/pkg/sbin:/usr/local/pkg/gcc/bin:$JAVA_HOME/bin:$PATH
ulimit -n 2560

function getLabelForCurrentDirectory()
{
  local pattern=$(echo $SSD/ | nocolor | sed 's/\//\\\//g');
  pwd | sed 's/'$pattern'/@/g';
}

function getLabelForGitCurrBranch() { git branch 2> /dev/null | grep '\*' | awk -F' ' '{printf " # "$2}'; }

PS1="\n\[${SetColorToYELLOW}\][\$(getLabelForCurrentDirectory)\[${SetColorToLightYELLOW}\]\$(getLabelForGitCurrBranch)\[${SetColorToYELLOW}\]]$ \[${SetNoColor}\]";

###################################
# Einstellen Entwicklungsumgebung #
###################################

export CCACHE_DIR=$SSD/ccache;
export TT_CLANG_WARNING_FLAGS="-fcolor-diagnostics -Wno-deprecated";
export NDS_DEFAULT_KEYSTORE_PASSWORD=dL8Oe.5pi9dk4-
export KEYSTORE_PASSWORD=$NDS_DEFAULT_KEYSTORE_PASSWORD
export ROUTING_API_AUTH_TOKEN_KEY=2dGURzdZnUFRCoSYNYO9WW61XpQvLBys
export ANDROID_SDK_ROOT="/usr/local/pkg/android-sdk"

# Startet eine Anwedung in XTERM
# arg 1 = application_name
# arg 2 = run_directory
# arg 3 = command_to_run
function startAppInsideXTerm()
{
    local scriptFileName=$(echo $HOME/_tempScript_start)"$1$RANDOM.sh"
    echo "#!/bin/bash" >> $scriptFileName
    echo "cd $2" >> $scriptFileName
    echo "$3" >> $scriptFileName
    echo "read -n 1 -p 'Drücken Sie eine beliebige Taste, um die Fenster zu schließen...' irgendwas" >> $scriptFileName
    chmod +x $scriptFileName
    xterm -T $(hostname)" - "$1 $scriptFileName &
}

# Es schaltet ctest aus oder ein
#
# arg 1 = on|off
function switchTests()
{
  local ctestPath=$(which ctest);
  local ctestHiddenPath=$(which ctest | sed 's/ctest/_ctest/g');
  local fakePath=$(which true);

  if [ "$1" == "off" ];
  then
    if [ ! -f $ctestHiddenPath ];
    then
      sudo mv $ctestPath $ctestHiddenPath;
      sudo ln -s $fakePath $ctestPath;
    fi
    printf "${SetColorToLightYELLOW}<< ctest ist ausgeschaltet >>${SetNoColor}\n";
  elif [ "$1" == "on" ];
  then
    if [ -f $ctestHiddenPath ];
    then
      sudo rm $ctestPath;
      sudo mv $ctestHiddenPath $ctestPath;
    fi
  fi
}

# Läuft conan-install für ein Komponent mit vorgegebenen festen Parametern
#
# arg 1 = debug|release
function doConanInstall()
{
  # debug or release?
  if [ -n "$1" ];
  then
    case $1 in
      debug)
        local buildType="Debug";
        ;;
      release)
        local buildType="Release";
        ;;
      *)
        printf "${SetColorToLightRED}Option '${1}' ist nicht bekannt!${SetNoColor}\n";
        return;
        ;;
    esac
  else
    printf "${SetColorToLightRED}Leg bitte fest, ob Debug oder Release sein soll.${SetNoColor}\n";
    return;
  fi

  conan install .. $2 $3 $4 $5 $6 -s build_type=$buildType -e CC=clang-ccache -e CXX=clang++-ccache --profile=linux_x86_64 --build=missing;
}

# Hält eine Datei conanfile.ttlock auf dem Laufenden mit den Versionen,
# auf die bom-crossplatform verweist.
function upgradeConanFile()
{
  local tempFile="$(tempfile)";
  echo '# TTLOCKv1: use ttlock.py to manipulate this file' > $tempFile;
  cat conanfile.ttlock | cut -d/ -f1 | xargs -I% grep '%/' $NK2_REPOS_ROOT/nk2-bom-crossplatform/conanfile.ttlock >> $tempFile;
  mv $tempFile conanfile.ttlock;
}

# Erstellt ein NK2 Komponent:
#
# arg 1 = rebuild|build
# arg 2 = test|notest
# arg 3 = debug|release|asan
function buildNk2Component()
{
  local buildProfile="linux_x86_64";

  # testen?
  if [ -n "$2" ];
  then
    case $2 in
      test)
        switchTests on;
        ;;
      notest)
        switchTests off;
        ;;
      *)
        printf "${SetColorToLightRED}Option '${2}' ist nicht bekannt!${SetNoColor}\n";
        return;
        ;;
    esac
  fi

  # Debug oder Release?
  if [ -n "$3" ];
  then
    case $3 in
      debug)
        local buildType="Debug";
        ;;
      release)
        local buildType="Release";
        ;;
      asan)
        local buildType="Debug";
        local addressSanitizerParams="-s $componentName:compiler.sanitizer=Address";
        ;;
      *)
        printf "${SetColorToLightRED}Option '${3}' ist nicht bekannt!${SetNoColor}\n";
        return;
        ;;
    esac
  fi

  local previousPath=$PWD;
  local componentDir=$PWD;
  local componentName=$(ls -d $componentDir 2> /dev/null | sed 's/[\/\.]//g' | cut -d- -f2-);
  local componentPath=$componentDir;
  local vscodeCfgPath="$componentDir/.vscode";
  (ls $vscodeCfgPath || mkdir $vscodeCfgPath) 2> /dev/null 1> /dev/null;
  local packageVersion=$(git log --decorate | grep -o 'tag: [0-9\.]*' | head -1 | grep -o '[0-9\.]*' | nocolor);
  local action=$1;

  # was tun?
  if [ -n "$1" ];
  then
    case $action in
      rebuild)
        (ls build/ && rm -rf build) 2> /dev/null 1> /dev/null;
        ;& # fallthrough
      build)
        (ls build/ || mkdir build) 2> /dev/null 1> /dev/null # build to separate directory
        cd build;

	local isLinuxBuild=$(echo $buildProfile | grep linux);

        if [ -n "$isLinuxBuild" ];
        then
          local conanExtraFlags="-e CC=clang-ccache -e CXX=clang++-ccache";
        fi

        conan install .. $4 $5 $6 $addressSanitizerParams -s build_type=$buildType $conanExtraFlags --profile=$buildProfile --build=missing;
        conan build ..;

        if [ $? -eq 0 ] && [ -n "$packageVersion" ];
        then
          #startAppInsideXTerm CONAN ../ 
          printf "${SetColorToLightYELLOW}switchTests off; conan create . $componentName/$packageVersion@tomtom/stable -s build_type=$buildType $conanExtraFlags --profile=$buildProfile --build=missing${SetNoColor}\n"
        fi

        # generate debug configuration for the project:
        if [ -f $componentPath/build/conan.lock ];
        then
          echo '{"version": "0.2.0", "configurations": [' > $vscodeCfgPath/launch.json;

          cd $componentPath/build/bin;
          local builtExecutables=$(find . -maxdepth 1 -type f -executable | grep -v '\.so' | sed "s|./|$(pwd)/|g");

          for executablePath in $builtExecutables
          do
            local debugConfigName=$(filename $executablePath);
            cat $NK2_REPOS_ROOT/vscode_cxx_launch_template.json >> $vscodeCfgPath/launch.json;
            sed -i 's|CONFIG_NAME|'$debugConfigName'|g' $vscodeCfgPath/launch.json;
            sed -i 's|CWD_PLACEHOLDER|'$componentPath/build/bin'|g' $vscodeCfgPath/launch.json;
            sed -i 's|EXECUTABLE_PATH_PLACEHOLDER|'$executablePath'|g' $vscodeCfgPath/launch.json;
            echo ',' >> $vscodeCfgPath/launch.json;
          done

          echo ']}' >> $vscodeCfgPath/launch.json;

          printf "${SetColorToLightBLUE}Debug-Einstellung für Komponent '${componentName}' wurde erfolgreich erzeugt :-)${SetNoColor}\n";
        fi
        ;;
      *)
        printf "${SetColorToLightRED}Option '${1}' ist nicht bekannt!${SetNoColor}\n";
        ;;
    esac
  fi

  switchTests on;

  # set up intellisense:
  if [ -f $componentPath/build/compile_commands.json ];
  then
    mv $componentPath/build/compile_commands.json $componentPath;
    cp $NK2_REPOS_ROOT/vscode_cxx_props_template.json $vscodeCfgPath/c_cpp_properties.json;
    sed -i 's|COMPONENT_NAME_PLACEHOLDER|'$componentName'|g' $vscodeCfgPath/c_cpp_properties.json;
    printf "${SetColorToLightBLUE}Intellisense für Komponent '${componentName}' wurde erfolgreich eingesetzt :-)${SetNoColor}\n";
  else
    printf "${SetColorToLightRED}Das 'compile_commands.json' für Komponent '${componentName}' konnte nicht erstellt werden!${SetNoColor}\n";
  fi

  cd $previousPath;
}
alias nk2do=buildNk2Component;

# Invoke gradlew for a given NK2 component
function callNk2ComGradlew()
{
  local gradleConfig=$(find . -type f -name build.gradle | xargs grep "abiFilters\|android {" | cut -d: -f1 | uniq);
  if [ -f $gradleConfig ];
  then
    if [ "$(grep abiFilters $gradleConfig)" ];
    then
      sed -i 's/abiFilters .*/abiFilters "x86_64"/g' build.gradle  $gradleConfig;
    else
      echo '' >> $gradleConfig;
    fi
  fi

  ./gradlew $2 $3 $4 $5 $6 $7 $8;

  ls $gradleConfig 2> /dev/null && git checkout $gradleConfig;
}
alias nk2gradlew=callNk2ComGradlew;

# Führt NavKit 2 devapp aus.
# arg 1 = onboard|online
# arg 2 = Pfad der Kartendaten (optional)
# arg 3 = Pfad des Keystore (optional)
function runNavKit2DeveloperApp()
{
  local mapDataPath=$2;
  if [ -z $mapDataPath ];
  then
    mapDataPath="$NAVKIT_DATASET/NDSmaps/NDS_AutomotiveReference_2019.12_2.4.6_EUR_IQ/DATA";
  fi

  local keystorePath=$3;
  if [ -z $keystorePath ];
  then
    keystorePath="$NAVKIT_DATASET/NK_AUTO_DEV.NKS";
  fi

  if [ "$1" == "onboard" ];
  then
    if [ -z "$(ps -ef | grep 'nav-engine' | grep '\--map' | grep -v grep)" ];
    then
      startAppInsideXTerm ENGINE \
        $NK2_REPOS_ROOT/nk2-developer-app/build \
        "./bin/nav-engine --api $ROUTING_API_AUTH_TOKEN_KEY --map $mapDataPath --keystore $keystorePath --password $NDS_DEFAULT_KEYSTORE_PASSWORD --guidance-mode onboard-v2 2> bin/engine.log.txt"
    fi
  elif [ "$1" == "online" ];
  then
    if [ -z "$(ps -ef | grep 'nav-engine' | grep -v grep)" ];
    then
      startAppInsideXTerm ENGINE \
        $NK2_REPOS_ROOT/nk2-developer-app/build \
        "./bin/nav-engine --api $ROUTING_API_AUTH_TOKEN_KEY --guidance-mode online-v2 2> bin/engine.log.txt"
    fi
  else
    printf "\n${SetColorToRED}Argument nicht anerkannt! Wähl bitte entweder 'onboard' oder 'online' aus.${SetNoColor}\n\n";
    return;
  fi

  if [ -z "$(ps -f | grep 'nav-dimui' | grep -v grep)" ];
  then
    startAppInsideXTerm GUI \
      $NK2_REPOS_ROOT/nk2-developer-app/build \
      "./bin/nav-dimui --api $ROUTING_API_AUTH_TOKEN_KEY 2> bin/gui.log.txt";
  fi
}
alias nk2devapp=runNavKit2DeveloperApp;

formatTrackedChangedFiles()
{
  git status -s -uno | cut -d" " -f3 | grep '\.c$\|\.cpp$\|\.cxx$\|\.cc$\|\.h$\|\.hpp$' | xargs clang-format-6.0 -i
}
alias format=formatTrackedChangedFiles;

### Start Android Studio with a particular config:
startAndroidStudio()
{
  $SSD/android-studio/bin/studio.sh &
}
alias androide=startAndroidStudio;

###################################################
# Check whether build enviroment has been altered #
###################################################

# checks whether path in env var is valid
function checkEnvironmentVariable()
{
  local name=$1;
  local var=$2;
  if [ -d "$var" ] || [ -f "$var" ];
  then
    printf "%18s = $var ${SetColorToGREEN}checked${SetNoColor}\n" "$name";
  else
    printf "%18s = $var ${SetColorToRED}error!${SetNoColor}\n" "$name";
  fi
}

checkEnvironmentVariable CCACHE_DIR     $CCACHE_DIR;
checkEnvironmentVariable NK2_REPOS_ROOT $NK2_REPOS_ROOT;

# if a link, prints final target, othwerwise, same path
function followLink()
{
  local link=$1;

  while [ -n "$link" ]
  do
    local target=$(ll "$link" 2> /dev/null | awk -F" -> " '{print $2}' | nocolor);

    if [ -n "$target" ];
    then
      link=$target;
    else
      printf "$link";
      break;
    fi
  done
}

# works with java, javac, ant and conan
function getShorterVersionLabel()
{
  case $1 in
    conan)
      local optionForVersion="-v";
      ;;
    java)
      ;& #fallthrough
    javac)
      ;& #fallthrough
    ant)
      local optionForVersion="-version";
      ;;
    *)
      local optionForVersion="--version";
      ;;
  esac

  $1 $optionForVersion 2>&1 | nocolor | sed 's/version //g' | sed 's/\"//g' | sed 's/(/[/g' | sed 's/)/]/g' | head -1;
}

function getCommandStamp()
{
  printf "$(followLink $(which $1)) ($(getShorterVersionLabel $1))";
}

# prints a report with label 1, whether parameters 2 and 3 are equal
function checkEquivalence()
{
  local command=$1;
  local commandStamp=$2;
  local label=$3;

  if [ "$commandStamp" = "$label" ];
  then
    printf "%12s = $commandStamp ${SetColorToGREEN}checked${SetNoColor}\n" "$command"
  else
    printf "%12s = $commandStamp ${SetColorToRED}error!${SetNoColor}\n" "$command"
  fi
}

# checks command invoked path and exec version
function checkCommand()
{
  local command=$1;
  local label=$2;
  checkEquivalence "$command" "$(getCommandStamp $1)" "$label";
}

printf "\n";
checkCommand java  "/usr/local/pkg/java/adoptopenjdk11-bin/bin/java (openjdk 11.0.15 2022-04-19)"
checkCommand javac "/usr/local/pkg/java/adoptopenjdk11-bin/bin/javac (javac 11.0.15)"
checkCommand conan "/usr/local/pkg/bin/conan (Conan 1.48.1)"

"$@"
