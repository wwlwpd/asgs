#!/usr/bin/env bash
# xxx THIS FILE IS GENERATED BY asgs-brew.pl                                           xxx
# xxx DO NOT CUSTOMIZE THIS FILE, IT WILL BE OVERWRITTEN NEXT TIME asgs-brew.pl IS RUN xxx

# This file is part of the ADCIRC Surge Guidance System (ASGS).
#
# The ASGS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ASGS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the ASGS.  If not, see <http://www.gnu.org/licenses/>.
#----------------------------------------------------------------

# Developer Note:
# This must remain consistent with what's exported by asgs-brew.pl, and
# vice versa; if something is added in define(), be sure to add the
# corresponding entry in show() - including usage
#
# Also note, any function that can be encapsulated as a separate shell
# script # is located in $SCRIPTDIR/bin; if a command is presented as a
# bash # function here, it is because it affects the environment. This
# impact can't be offloaded to the child process that is invoked when
# running external scripts.

I="(info)   "
W="(warning)"

asgsh() {  # disable
  echo "The nesting of \"asgsh\" inside of asgsh (you're in it now, pid: $_ASGSH_PID) is not allowed."
}

help() {
  echo Command Line Options \(used when invoking asgsh from login shell\):
  echo "   -d                          - debug mode, turns on 'set -x'"
  echo "   -h                          - displays available asgsh command line flags, then exits."
  echo "   -p     profile              - launches the ASGS Shell environment and immediate loads specified profile on start, if it exists."
  echo "   -x                          - skips loading of platforms.sh and properties.sh (could become default)"
  echo
  echo ASGS Shell Commands:
  echo "   clone   profile             - launches guided process for cloning the current profile, including copying the configuratin file."
  echo "   define  config              - defines ASGS configuration file used by 'run', (\$ASGS_CONFIG). 'define' replaces old 'set' command."
  echo "           editor              - defines default editor, (\$EDITOR)"
  echo "           scratchdir          - defines ASGS main script directory used by all underlying scripts, (\$SCRATCH)"
  echo "           scriptdir           - defines ASGS main script directory used by all underlying scripts, (\$SCRIPTDIR)"
  echo "           workdir             - defines ASGS main script directory used by all underlying scripts, (\$WORK)"
  echo "   delete  profile <name>      - deletes named profile"
  echo "           adcirc  <name>      - deletes named ADCIRC profile"
  echo "           config              - deletes configuration file for current profile, unsets 'config' var. Interactively confirms."
  echo "           statefile           - deletes the state file associated with a profile, effectively for restarting from the initial advisory"
  echo "   dump    <param>             - dumps (using cat) contents specified files: config, exported (variables); and if defined: statefile, syslog" 
  echo "   edit    adcirc  <name>      - directly edit the named ADCIRC environment file"
  echo "           config              - directly edit currently registered ASGS configuration file (used by asgs_main.sh)"
  echo "           jobs                - if RUNDIR is defined and exists, lists all job Ids associated with the current profile."
  echo "           meshes              - directly inspect or edit the list of supported meshes"
  echo "           platforms           - directly inspect or edit the list of supported platforms"
  echo "           profile <name>      - directly edit the named ASGSH Shell profile"
  echo "           statefile           - open up STATEFILE (if set) in EDITOR for easier forensics"
  echo "           syslog              - open up SYSLOG (if set) in EDITOR for easier forensics"
  echo "   goto    <param>             - change CWD to a supported directory. Type 'goto options' to see the currently supported options"
  echo "   guess   platform            - attempts to guess the current platform as supported by platforms.sh (e.g., frontera, supermic, etc)" 
  echo "   build adcirc                  - interactive tool for building and local registering versions of ADCIRC for use with ASGS"
  echo "   inspect <option>            - alias to 'edit' for better semantics; e.g., 'inspect syslog' or 'inspect statefile'"
  echo "   list    <param>             - lists different things, please see the following options; type 'list options' to see currently supported options"
  echo "   load    profile <name>      - loads a saved profile by name; use 'list profiles' to see what's available"
  echo "           adcirc  <name>      - loads information a version of ADCIRC into the current environment. Use 'list adcirc' to see what's available"
  echo "   purge   <param>             - deletes specified file or directory"
  echo "           rundir              - deletes run directory associated with a profile, useful for cleaning up old runs and starting over for the storm"
  echo "   rebuild profile             - wizard for recreating an ASGS profile using an existing configuration file"
  echo "   rl                          - reload current profile, equivalent to 'load profile <current-profile-name>'"
  echo "   run                         - runs asgs using config file, \$ASGS_CONFIG must be defined (see 'define config'); most handy after 'load'ing a profile"
  echo "   save    profile <name>      - saves an asgs named profile, '<name>' not required if a profile is loaded"
  echo "   show    <param>             - shows specified profile variables, to see current list type 'show help'"
  echo "           exported            - dumps all exported variables and provides a summary of what asgsh tracks"
  echo "   sq                          - shortcut for \"squeue -u \$USER\" (if squeue is available)"
  echo "   switch  <option>            - alias to 'load' for better semantics; e.g., 'switch profile next-profile'"
  echo "   tailf   syslog              - executes 'tail -f' on ASGS instance's system log"
  echo "   verify                      - verfies Perl and Python environments"
  echo "   exit                        - exits ASGS shell, returns \$USER to login shell"
}

_is_a_num()
{
  re='[1-9][0-9]?$'
  if [[ "${1}" =~ $re ]] ; then
    echo -n $1 
  else
    echo -n -1 
  fi
  return
}

_pwd() {
  echo "${I} ... $(pwd)"
}

# change to a directory know by asgsh
goto() {
  case "${1}" in
  adcircworkdir)
    if [ -e "$ADCIRCDIR/work" ]; then
      cd $ADCIRCDIR/work
      _pwd
    else
      echo "ADCIRCDIR not yet defined"
    fi
    ;;
  adcircdir)
    if [ -e "$ADCIRCDIR" ]; then
      cd $ADCIRCDIR
      _pwd
    else
      echo "ADCIRCDIR not yet defined"
    fi
    ;;
  installdir)
    if [ -e "$ASGS_INSTALL_PATH" ]; then
      cd $ASGS_INSTALL_PATH
      _pwd
    else
      echo "ASGS_INSTALL_PATH not defined, which is concerning. Did you complete the installation of ASGS?"
    fi
    ;;
  rundir)
    if [ -e "$RUNDIR" ]; then
      cd $RUNDIR
      _pwd
    else
      echo "RUNDIR not yet defined"
    fi
    ;;
  scratchdir)
    if [ -e "$SCRATCH" ]; then
      cd $SCRATCH
      _pwd
    else
      echo "SCRATCH not yet defined"
    fi
    ;;
  scriptdir)
    if [ "$SCRIPTDIR" ]; then
      cd $SCRIPTDIR
      _pwd
    else
      echo "scriptdir not yet defined"
    fi
    ;;
  workdir)
    if [ "$WORK" ]; then
      cd $WORKDIR
      _pwd
    else
      echo "workdir not yet defined"
    fi
    ;;
  *)
    echo 'Only "adcircdir", "rundir", "scratchdir", "scriptdir", and "workdir" are supported at this time.'
    ;;
  esac
}

# load environment related things like an ADCIRC environment or saved ASGS environment
load() {
  CHOICES=();
  case "${1}" in
    adcirc)
      if [ -z "${2}" ]; then
        for i in $(list adcirc | awk '{print $2}'); do
          CHOICES+=("$i")
        done 
        C=${#CHOICES[@]}
        if [ $C -eq 0 ]; then
          echo "No versions of ADCIRC are available. Run 'build adcirc' to install one." 
          return
        elif [ $C -eq 1 ]; then
          __ADCIRC_BUILD=$(list adcirc | awk '{print $2}')
        elif [ $C -gt 1 ]; then
          list adcirc
          read -p "Choose a number (1-$C) or name from above: " _SELECTION
          _isnum=$(_is_a_num $_SELECTION)
          if [[ $_isnum -gt -1 && $_isnum -le $C ]]; then
            __ADCIRC_BUILD=${CHOICES[$(($_isnum-1))]}
          elif [ -n "$_SELECTION" ]; then
            __ADCIRC_BUILD=$_SELECTION
          else
            echo "A valid selection must be made to proceed."
            return
          fi 
        fi
      else
        __ADCIRC_BUILD=${2}
      fi
      echo "${I} loading ADCIRC build, '$__ADCIRC_BUILD'."
      if [ -e "${ADCIRC_META_DIR}/${__ADCIRC_BUILD}" ]; then
          # source it
          . ${ADCIRC_META_DIR}/${__ADCIRC_BUILD}
          echo "${I} prepending ADCIRCDIR and SWANDIR to PATH"
          echo "${I}   + $ADCIRCDIR"
          echo "${I}   + $SWANDIR"
          PATH=${SWANDIR}:${ADCIRCDIR}:${PATH}
          export PATH
          save profile ${_ASGSH_CURRENT_PROFILE}
      else
          echo "ADCIRC build, '$__ADCIRC_BUILD' does not exist. Use 'list adcirc' to see a which ADCIRCs are available to load"
      fi
      ;;
    profile)
      if [ -z "${2}" ]; then
        for i in $(list profiles | awk '{print $2}'); do
          CHOICES+=("$i")
        done 
        C=${#CHOICES[@]}
        if [ $C -eq 1 ]; then
          NAME=$(list profiles | awk '{print $2}')
        elif [ $C -gt 1 ]; then
          list profiles
          read -p "Choose a number (1-$C) or name from above: " _SELECTION
          _isnum=$(_is_a_num $_SELECTION)
          if [[ $_isnum -gt -1 && $_isnum -le $C ]]; then
            NAME=${CHOICES[$(($_isnum-1))]}
          elif [ -n "$_SELECTION" ]; then
            NAME=$_SELECTION
          else
            echo "${W} A valid selection must be made to proceed."
            return
          fi 
        fi
      else
        NAME=${2}
      fi
      if [ -e "$ASGS_HOME/.asgs/$NAME" ]; then
        export _ASGSH_CURRENT_PROFILE="$NAME"
        _reset_ephemeral_envars
        . "$ASGS_HOME/.asgs/$NAME"
        export PS1="asgs ($_ASGSH_CURRENT_PROFILE)> "
        echo "${I} loaded '$NAME' into current profile"
        if [ -e "$ASGS_CONFIG" ]; then
          # extracts info such as 'instancename' so we can derive the location of
          # the state file, then the log file path and actual run directory
          _parse_config $ASGS_CONFIG
        fi
      else
        echo "${W} ASGS profile, '$NAME' does not exist. Use 'list profiles' to see a which profile are available to load"
      fi
      ;;
    *)
      echo "${W} 'load' requires 2 parameters: 'adcirc' or 'profile' as the first; the second parameter defines what to load."
      return
  esac
}

# alias for load, so one may more naturally "switch" profiles
switch() {
  load $@
}

# used to reset ephemeral variables - those created via _parse_config and
# those sourced via _load_state_file (currently hard coded list based on
# what is currently available via STATEFILE
_reset_ephemeral_envars() {
  export INSTANCENAME=
  export STATEFILE=
  export RUNDIR=
  export LASTSUBDIR=
  export SYSLOG=
  export ASGS_CONFIG=
}

_parse_config() {
  if [ ! -e "${1}" ]; then
    echo "${W} config file is defined, but the file '${1}' does not exist!"
    return
  fi
  # pull out var info the old fashion way...
  export INSTANCENAME=$(egrep '^ *INSTANCENAME=' "${1}" | sed 's/^ *INSTANCENAME=//' | sed 's/ *#.*$//g')
  echo "${I} config file found, instance name is '$INSTANCENAME'"
  export STATEFILE="$SCRATCH/${INSTANCENAME}.state"
  _load_state_file $STATEFILE
}

_load_state_file() {
  if [ -e "${1}" ]; then
    STATEFILE=${1}
    . $STATEFILE
  else
    echo "${W} state file '${1}' does not exist."
    echo "${I} no indication of first run yet?"
  fi

  if [ -d "$RUNDIR" ]; then
    PROPERTIESFILE="$RUNDIR/run.properties"
    if [ -e "$PROPERTIESFILE" ]; then
      echo "... found 'run.properties' file, at '$PROPERTIESFILE'"
    fi
  fi
  return
}

# saves environment as a file named what is passed to the command, gets the
# list of environmental variables to save from $_ASGS_EXPORTED_VARS
save() {
  case "${1}" in
    profile)
      DO_RELOAD=1
      NAME=${2:-$_ASGSH_CURRENT_PROFILE}
      DO_RELOAD=0
    
      if [ ! -d $ASGS_HOME/.asgs ]; then
        mkdir -p $ASGS_HOME/.asgs
      fi
    
      if [ -e "$ASGS_HOME/.asgs/$NAME" ]; then
        IS_UPDATE=1
      fi
    ;;
    *)
      echo "'save' requires 2 parameters: 'profile' as the first; the second is the profile name."
      return
    return
  esac

  # generates saved provile as a basic shell resource file that simply
  # includes an 'export' line for each variable asgsh cares about; this
  # is defined as part of the shell installation by asgs-brew.pl
  for e in $_ASGS_EXPORTED_VARS; do
    echo "export ${e}='"${!e}"'"  >> "$ASGS_HOME/.asgs/${NAME}.$$.tmp"
  done
  mv "$ASGS_HOME/.asgs/${NAME}.$$.tmp" "$ASGS_HOME/.asgs/${NAME}"
  
  # print different message based on whether or not the profile already exists
  if [ -n "$IS_UPDATE" ]; then
    echo "${I} profile '$NAME' was updated"
  else
    echo "${I} profile '$NAME' was written"
  fi

  # update prompt so that it's easy to tell at first glance what's loaded
  export _ASGSH_CURRENT_PROFILE=$NAME
  export PS1="asgs (${_ASGSH_CURRENT_PROFILE})> "

  if [ 1 -eq "$DO_RELOAD" ]; then
    load profile $_ASGSH_CURRENT_PROFILE
  fi
}

rebuild() {
  case "${1}" in
    profile)
      _default_base_profile=default
      read -p "Base profile [$_default_base_profile]? " _base_profile
      if [ -z "$_base_profile" ]; then
        _base_profile=$_default_base_profile
      fi
      load profile $_base_profile
      read -p "Path to ASGS configuration file: " _config
      if [[ -z "$_config" || ! -e "$_config" ]]; then
        echo "'rebuild profile' requires an existing ASGS configuration file."
        return
      fi 
      ABS_PATH=$(readlink -f "$_config")
      export ASGS_CONFIG=$ABS_PATH
      _parse_config $ASGS_CONFIG
      # default is $INSTANCENAME, grabbed from _parse_config when $ASGS_CONFIG
      # is parsed above
      read -p "New profile name [$INSTANCENAME]? " _profile_name 
      if [ -z "$_profile_name" ]; then
        _profile_name=$INSTANCENAME
      fi
      save profile $_profile_name
    ;;
    *) echo "'clone' only applies to 'profile'"
    ;;
  esac
}

clone() {
  case "${1}" in
    profile)
      if [[ -z "$ASGS_CONFIG" || ! -e "$ASGS_CONFIG" ]]; then
        echo "'clone profile' only proceeds if the parent profile's config file has been defined."
        echo "type, 'save profile <new-profile-name>' if you don't wish to define a config file first."
        return
      fi
      _epoch=$(date +%s)
      _default_new_profile=${_ASGSH_CURRENT_PROFILE}-${_epoch}-clone
      read -p "Name of new profile? [$_default_new_profile] " new_profile_name
      if [ -z "$new_profile_name" ]; then
        new_profile_name=$_default_new_profile
      fi
      _year=$(date +%Y)
      _default_new_config="$SCRIPTDIR/config/$_year/${new_profile_name}.sh"
      read -p "Name of new config file? [$_default_new_config] " new_config
      if [ -z "$new_config" ]; then
        new_config=$_default_new_config
      fi
      read -p "Create new profile? [y] " create
      if [[ -z "$create" || "$create" = "y"  ]]; then
        cp -v $ASGS_CONFIG $new_config
        define config $new_config
        save profile $new_profile_name
        rl
        read -p "Would you like to edit the new configuration file? [y] " _edit
        if [[ -z "$_edit" || "$_edit" = "y" ]]; then
          edit config
        fi
      else
        echo "Profile cloning operation has been aborted."
      fi
      ;;
    *) echo "'clone' only applies to 'profile'"
      ;;
  esac
}


# reload current profile
rl() {
  load profile $_ASGSH_CURRENT_PROFILE
}

# defines the value of various important environmental variables,
# exports them to current session (and are available to be saved)
define() {
  if [ -z "${2}" ]; then
    echo "'define' requires 2 arguments - parameter name and value"
    return 
  fi
  _DEFINE_OK=1
  case "${1}" in
    adcircdir)
      export ADCIRCDIR=${2}
      echo "${I} ADCIRCDIR is defined as '${ADCIRCDIR}'"
      ;;
    adcircbranch)
      export ADCIRC_GIT_BRANCH=${2}
      echo "${I} ADCIRC_GIT_BRANCH is defined as '${ADCIRC_GIT_BRANCH}'"
      ;;
    adcircremote)
      export ADCIRC_GIT_REMOTE=${2}
      echo "${I} ADCIRC_GIT_REMOTE is defined as '${ADCIRC_GIT_REMOTE}'"
      ;;
    config)
      # converts relative path to absolute path so the file is available regardless of the `pwd`
      ABS_PATH=$(readlink -f "${2}")
      # makes sure that file exists, will not 'define config' if the file does not
      if [ ! -e "$ABS_PATH" ]; then
        echo "'${ABS_PATH}' does not exist! 'define config' command has failed."
        _DEFINE_OK=0
        return
      fi 
      export ASGS_CONFIG=${ABS_PATH}
      echo "${I} ASGS_CONFIG is defined as '${ASGS_CONFIG}'"
      ;;
    editor)
      export EDITOR=${2}
      echo "${I} EDITOR is defined as '${EDITOR}'"
      ;;
    scriptdir)
      export SCRIPTDIR=${2} 
      echo "${I} SCRIPTDIR is now defined as '${SCRIPTDIR}'"
      ;;
    workdir)
      export WORK=${2} 
      echo "${I} WORK is now defined as '${WORK}'"
      ;;
    scratchdir)
      export SCRATCH=${2} 
      echo "${I} SCRATCH is now defined as '${SCRATCH}'"
      ;;
    *) echo "define requires one of the supported parameters: adcircdir, adcircbranch, adcircremote, config, editor, scratchdir, scriptdir, or workdir"
      _DEFINE_OK=0
      ;;
  esac 
  if [ 1 -eq "$_DEFINE_OK" ]; then
    export PS1="asgs (${_ASGSH_CURRENT_PROFILE}*)> "
  fi
}

# interactive dialog for choosing an EDITOR if not defined
_editor_check() {
  if [ -z "$EDITOR" ]; then
    __DEFAULT_EDITOR=vim
    echo "\$EDITOR is not defined. Please define it now (selection updates environment):"
    echo
    echo "Editors available via PATH"
    for e in vim nano vi; do
      full=$(which `basename $e`)
      echo "- $e	(full path: $full)"
    done 
    read -p "Choose [vim]: " _DEFAULT_EDITOR
    if [ -z "$_DEFAULT_EDITOR" ]; then
      _DEFAULT_EDITOR=$__DEFAULT_EDITOR
    fi
    define editor "$_DEFAULT_EDITOR"
    save profile
    echo
  fi
}

# opens up $EDITOR to directly edit files defined by the case
# statement herein
edit() {
  # if it's not defined
  _editor_check

  # dispatch subject of edit command
  case "${1}" in
  adcirc)
    BRANCH=${2}
    if [ ! -e "$ADCIRC_META_DIR/$BRANCH" ]; then
      echo "An ADCIRC environment named '$BRANCH' doesn't exist"
      return
    fi
    $EDITOR "$ADCIRC_META_DIR/$BRANCH"
    ;;
  config)
    if [ -z "$ASGS_CONFIG" ]; then
      echo "\$ASGS_CONFIG is not defined. Use 'define config' to specify an ASGS config file."
      return
    elif [ ! -e "$ASGS_CONFIG" ]; then
      echo "ASGS_CONFIG file, '$ASGS_FILE' doesn't exist"
      return
    fi
    $EDITOR $ASGS_CONFIG
    if [ 0 -eq $? ]; then
      read -p "reload edited profile '$_ASGSH_CURRENT_PROFILE'? [y]" reload
      if [[ -z "$reload" || "$reload" = "y" ]]; then
        rl
      else
        echo "warning - profile '$ASGS_CONFIG' has been edited, but the profile has not been reloaded. To reload, use the 'rl' or 'load profile $_ASGSH_CURRENT_PROFILE' command."
      fi
    fi
    ;;
  meshes)
    $EDITOR $ASGS_MESH_DEFAULTS
    ;;
  platforms)
    $EDITOR $ASGS_PLATFORMS
    ;;
  profile)
    NAME=${2}
    if [[ -z "$NAME" || ! -e "$ASGS_HOME/.asgs/$NAME" ]]; then
      echo "An ASGS profile named '$NAME' doesn't exist"
      return
    fi
    $EDITOR "$ASGS_HOME/.asgs/$NAME"
    if [ 0 -eq $? ]; then
      read -p "reload edited profile '$_ASGSH_CURRENT_PROFILE'? [y]" reload
      if [[ -z "$reload" || "$reload" = "y" ]]; then
        rl
      else
        echo "warning - profile '$_ASGSH_CURRENT_PROFILE' has been edited, but not reloaded. To reload, use the 'rl' or 'load profile $_ASGSH_CURRENT_PROFILE' command."
      fi
    fi
    ;;
  statefile)
    if [ -z "$STATEFILE" ]; then
      echo "STATEFILE is not defined. Perhaps you have not defined a config or loaded a completed profile file yet?"
      return
    elif [ ! -e "$STATEFILE" ]; then
      echo "STATEFILE file, '$STATEFULE' doesn't exist"
      return
    fi
    $EDITOR "$STATEFILE"
    ;;
  syslog)
    if [ -z "$SYSLOG" ]; then
      echo "SYSLOG is not defined. Perhaps you have not defined a config or loaded a completed profile file yet?"
    elif [ ! -e "$SYSLOG" ]; then
      echo "Log file, '$SYSLOG' doesn't exist - did it get moved or deleted?"
      return
    fi
    $EDITOR "$SYSLOG"
    ;;
  *)
    echo "Supported options:"
    echo "adcirc <name>  - directly edit named ADCIRC environment file"
    echo "config         - directly edit ASGS_CONFIG, if defined"
    echo "profile <name> - directly edit named ASGS profile (should be followed up with the 'load profile' command"
    echo "statefile      - open STATEFILE from a run in EDITOR for easier forensics"
    echo "syslog         - open SYSLOG from a run in EDITOR for easier forensics"
    ;;
  esac
}

# deletes a saved profile by name
delete() {
  case "${1}" in
    adcirc)
      if [ -z "${2}" ]; then
        echo \'delete adcirc\' requires a name parameter, does NOT unload current ADCIRC settings 
        return
      fi
      NAME=${2}
      if [ -e "$ADCIRC_META_DIR/$NAME" ]; then
        rm -f "$ADCIRC_META_DIR/$NAME"
        echo deleted ADCIRC configuration \'$NAME\'
      else
        echo "no saved ADCIRC configuration named '$NAME' was found"
      fi
      ;;
    config)
      if [ -z "$ASGS_CONFIG" ]; then
        echo "Config file not yet defined."
        return
      elif [ ! -e "$ASGS_CONFIG" ]; then
        echo "Can't find config fie, $ASGS_CONFIG"
        return
      fi 
      read -p "Are you sure you want to delete the '$ASGS_CONFIG'?[y] " delete
      if [[ -z "$delete" || "$delete" = "y" ]]; then
         rm -f $ASGS_CONFIG
         export ASGS_CONFIG=
        echo "Deleted config file and unset 'config' for this profile."
      fi
      save profile $_ASGSH_CURRENT_PROFILE
      ;;
    profile)
      if [ -z "${2}" ]; then
        echo \'delete profile\' requires a name parameter, does NOT unload current profile 
        return
      fi
      NAME=${2}
      if [ -e "$ASGS_HOME/.asgs/$NAME" ]; then
        rm -f "$ASGS_HOME/.asgs/$NAME"
        echo deleted profile \'$NAME\'
      else
        echo "no saved profile named '$NAME' was found"
      fi
      ;;
    statefile)
     read -p "This will delete the state file, \"${STATEFILE}\". Type 'y' to proceed. [N] " DELETE_STATEFILE
     if [ 'y' == "${DELETE_STATEFILE}" ]; then
       rm -rvf "${STATEFILE}"
       export STATEFILE=
     else
       echo "Purge of state file cancelled."
     fi
    ;;
    *)
      echo "'delete' requires 2 parameters for 'adcirc' and 'profile' specifying which ADCIRC build or profile to delete. All others do not."
      return
  esac
}

purge() {
  if [ -z "${1}" ]; then
    echo "'purge' requires 1 argument - currently only supports 'rundir' and 'scratchdir''."
    return 
  fi
  case "${1}" in
    rundir)
     read -p "This will delete the current run director, \"${RUNDIR}\". Type 'y' to proceed. [N] " DELETE_RUNDIR
     if [ 'y' == "${DELETE_RUNDIR}" ]; then
       rm -rvf "${RUNDIR}"
       export RUNDIR=
     else
       echo "Purge of rundir cancelled."
     fi
    ;;
    scratchdir)
     read -p "This will delete EVERYTHING in the SCRATCH directory, \"${SCRATCH}\". Type 'y' to proceed. [N]? " DELETE_SCRATCH
     if [ 'y' == "${DELETE_SCRATCH}" ]; then
       rm -rvf ${SCRATCH}/*
     else
       echo "Purge of scratch directory cancelled."
     fi
    ;;
    *)
     echo "'${1}' is not supported. 'purge' currently only supports 'rundir' and 'scratchdir'."
    ;;
  esac 
}

if [ 1 = "${skip_platform_profiles}" ]; then
  echo "(-x used) ... skipping the loading platform.sh and properties.sh ..." 
else
  echo "${I} initializing..."
  # loading support for reading of run.properties file
  if [ -e "$SCRIPTDIR/properties.sh" ]; then
    echo "${I} found properties.sh"
    . $SCRIPTDIR/properties.sh
  else
    echo "${W} could not find $SCRIPTDIR/properties.sh"
  fi
  # initializing ASGS environment and platform, based on $asgs_machine_name
  if [ -e "$SCRIPTDIR/monitoring/logging.sh" ]; then
    echo "${I} found logging.sh"
    . $SCRIPTDIR/monitoring/logging.sh 
    if [ -e "$SCRIPTDIR/platforms.sh" ]; then
      echo "${I} found platforms.sh"
      . $SCRIPTDIR/platforms.sh
      env_dispatch $ASGS_MACHINE_NAME
    else
      echo "${W} could not find $SCRIPTDIR/platforms.sh"
    fi
  else
    echo "${W} could not find $SCRIPTDIR/monitoring/logging.sh"
  fi
fi

# initialization, do after bash functions have been loaded
export PS1='asgs (none)>'
if [ -n "$_asgsh_splash" ]; then
echo
echo "Quick start:"
echo "  'build adcirc' to build and local register versions of ADCIRC"
echo "  'list profiles' to see what scenario package profiles exist"
echo "  'load profile <profile_name>' to load saved profile"
echo "  'list adcirc' to see what builds of ADCIRC exist"
echo "  'load adcirc <adcirc_build_name>' to load a specific ADCIRC build"
echo "  'run' to initiated ASGS for loaded profile"
echo "  'help' for full list of options and features"
echo "  'goto scriptdir' to change current directory to ASGS' script directory"
echo "  'verify' the current ASGS Shell Environment is set up properly"
echo "  'exit' to return to the login shell"
echo
echo "NOTE: This is a fully function bash shell environment; to update asgsh"
echo "or to recreate it, exit this shell and run asgs-brew.pl with the"
echo " --update-shell option"
echo
fi

# runs script to install ADCIRC interactively
build () {
  if [ -z "${1}" ]; then
    echo "The 'build' command requires an argument specifying what to build, e.g., 'build adcirc'"
    exit
  fi
  TO_BUILD=${1}
  case "${1}" in
    adcirc)
      init-adcirc.sh ${2}
      ;;
    *)
      echo "Only 'adcirc' supported at this time."
      exit
      ;;
  esac
}

# deprecation (may change *again* if we create a general install manager
initadcirc(){
  echo "(deprecation notice): 'initadcirc' should now be called as, 'build adcirc'."
  echo "No action taken..."
  echo
  return
}

# alias to edit that may be more semantically correct in some
# cases; e.g., "inspect statefile" or "inspect log"
cpann() { # disable
  echo 'To install a Perl module, use "cpanm" instead.'
}

inspect() {
  edit $@
}

# function alias for `goto dir` command
g() {
  goto $@
}

screen() { # disable
  echo 'The use of the "screen" utility *inside* of asgsh is strongly discouraged.'
}

tmux() {   # disable
  echo 'The use of the "tmux" utility *inside* of asgsh is strongly discouraged.'
}

# common aliases users expect - if you see something missing, please create a github issue
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias grep='grep --color=auto'
alias l.='ls -d .* --color=auto'
alias ll='ls -l --color=auto'
alias ls='ls --color=auto'

# handy aliases for the impatient
alias a="list adcirc"
alias c="edit config"
alias ds="delete statefile"
alias p="list profiles"
alias m="inspect meshes"
alias lm="list meshes"
alias r="run"
alias rd="goto rundir"
alias sd="goto scriptdir"
alias s="goto scratchdir"
alias t="tailf syslog"
alias v="verify"
alias va="verify adcirc"
alias vp="verify perl"
alias vpy="verify python"
alias vr="verify regressions"

if [ -n "$_asgsh_splash" ]; then
# show important directories
show scriptdir
show scratchdir
goto scriptdir
else
goto scriptdir >/dev/null 2>&1
fi

# when started, ASGS Shell loads the 'default' profile,
# this can be made variable at some point
load profile ${profile-default}
echo

# construct to handle "autorun" options
case "$_asgsh_flag_do" in
  run_list)
    list ${_asgsh_flag_do_args}
    exit
  ;;
  run_profile)
    run
  ;;
  run_tailf_syslog)
    tailf syslog
  ;;
  run_verify_and_quit)
    verify
    exit
  ;;
  *)
  ;;
esac
