# xxx THIS FILE IS GENERATED BY asgs-brew.pl                                           xxx
# xxx DO NOT CUSTOMIZE THIS FILE, IT WILL BE OVERWRITTEN NEXT TIME asgs-brew.pl IS RUN xxx
export PS1='asgs (none)> '
echo Type \'exit\' to return to the login shell.

# COMMANDS DEFINED AS BASH FUNCTIONS

help() {
echo
echo Commands:
echo "   delete <name> - deletes named session"
echo "   load   <name> - loads a saved session by name"
echo "   save   <name> - saves an asgs named session"
echo "   list-configs  - lists ASGS configuration files based on year (interactive)"
echo "   list-sessions - lists all saved sessions that can be specified by load"
echo "   run           - runs asgs using config file, if set (use 'set config /path/to/config' to set this)"
echo "   set           - sets specified session variables (i.e., variables that do not last after 'exit')"
echo "     subcommands:"
echo "        * 'config' - sets ASGS configuration file used by 'run'"
echo "   show          - shows specified session variables (i.e., variables that do not last after 'exit')"
echo "     subcommands:"
echo "        * 'config' - shows ASGS configuration file used by 'run'"
echo "   sq            - shortcut for \"squeue -u \$USER\" (if squeue is available)"
echo "   verify        - verfies Perl and Python environments"
echo "   exit          - exits ASGS shell, returns \$USER to login shell"
}

list-configs() {
  read -p "Show configs for what year? " year
  if [ -d $SCRIPTDIR/config/$year ]; then
    ls $SCRIPTDIR/config/$year/* | less
  else
    echo ASGS configs for $year do not exist 
  fi
}

delete() {
  if [ -z "${1}" ]; then
    echo \'delete\' requires a name parameter, does NOT unload current session 
    return
  fi
  NAME=${1}
  if [ -e "$HOME/.asgs/$NAME" ]; then
    rm -f "$HOME/.asgs/$NAME"
    echo deleted \'$NAME\'
  else
    echo no saved session found
  fi
}

list-sessions() {
  if [ ! -d "$HOME/.asgs/" ]; then
    echo no sessions saved
  else
    for session in $(ls -1 "$HOME/.asgs/" | sort); do
      echo "- $session"
    done
    return
  fi
}

load() {
  if [ -z "${1}" ]; then
    echo \'load\' requires a name parameter, use \'list-sessions\' to list saved sessions
    return
  fi
  NAME=${1}
  if [ -e "$HOME/.asgs/$NAME" ]; then
    . "$HOME/.asgs/$NAME"
    export PS1="asgs ($NAME)> "
    echo loaded \'$NAME\' into current session;
  else
    echo no saved session found
  fi
}

run() {
  if [ -n "${ASGS_CONFIG}" ]; then
    echo "Running ASGS using the config file, '${ASGS_CONFIG}'"
    $SCRIPTDIR/asgs_main.sh -c $ASGS_CONFIG
  else
    echo "ASGS_CONFIG must be set before the 'run' command can be used";  
    return;
  fi
}

save() {
  if [ -z "${1}" ]; then
    echo \'save\' requires a name parameter
    return
  fi
  NAME=${1}
  if [ ! -d $HOME/.asgs ]; then
    mkdir -p $HOME/.asgs
  fi
  # be very specific about the "session variables" saved
  if [ -n "${ASGS_CONFIG}" ]; then
    echo "export ASGS_CONFIG=${ASGS_CONFIG}" > "$HOME/.asgs/$NAME"
    echo saved current session as \'$NAME\', use \'list-sessions\' to see what others are available to \'load\'
  else
    echo "no session variables found to save..."
    echo "saved variables are:"
    echo "  ASGS_CONFIG"
  fi
}

set() {
  case "${1}" in
  config)
    if [ -n "${2}" ]; then
      export ASGS_CONFIG=${2}
      echo "ASGS_CONFIG is set to '${ASGS_CONFIG}'"
    else
      echo "'set config' requires a value to assign to ASGS_CONFIG. Use 'show config' to display current value."
      return 
    fi
    ;;
  *) echo "'set' requires a supported subcommand: 'config'"
    ;;
  esac 
}

show() {
  case "${1}" in
  config)
    if [ -n "${ASGS_CONFIG}" ]; then
      echo "ASGS_CONFIG is set to '${ASGS_CONFIG}'"
    else
      echo "ASGS_CONFIG is not set to anything. Try, 'set config /path/to/asgs/config.sh' first"
    fi
    ;;
  *) echo "'show' requires a supported subcommand: 'config'"
    ;;
  esac 
}

sq() {
  if [ -n $(which squeue) ]; then
    squeue -u $USER  
  else
    echo The `squeue` utility has not been found in your PATH \(slurm is not available\)
  fi
}

verify() {
  echo verifying Perl Environment:
  which perl
  pushd $SCRIPTDIR > /dev/null 2>&1
  perl $SCRIPTDIR/cloud/general/t/verify-perl-modules.t
  echo verifying Perl scripts can pass compile phase \(perl -c\)
  for file in $(find . -name "*.pl"); do perl -c $file > /dev/null 2>&1 && echo ok     $file || echo not ok $file; done
  which python
  python $SCRIPTDIR/cloud/general/t/verify-python-modules.py && echo Python modules loaded ok
  echo verifying Python scripts can pass compile phase \(python -m py_compile\)
  for file in $(find . -name "*.py"); do
    python -m py_compile $file > /dev/null 2>&1 && echo ok     $file || echo not ok $file;
    # clean up potentially useful *.pyc (compiled python) files
    rm -f ${file}c
  done
  popd > /dev/null 2>&1
}

