#!/bin/bash
# Determine if "installation" and "project" levels are one in the same.
SCRIPT_DIR_INSTALLATION="`dirname "${BASH_SOURCE[0]}"`"
export SCRIPT_DIR_DLW="$SCRIPT_DIR_INSTALLATION"
SCRIPT_DIR_INSTALLATION="`readlink -f $SCRIPT_DIR_INSTALLATION`"
SCRIPT_DIR_INSTALLATION="`dirname "$SCRIPT_DIR_INSTALLATION"`"
SCRIPT_DIR="`pwd -P`/script"
# Determine if recursive dlw call.  The dlw is designed to be recursive.
# If extending dlw, take this into account.  For example, to prevent
# PATH environment from becoming excessively long, because it generally
# prepends to existing path, check the path for a project level
# script directory in the path.  If it exists in the PATH then this
# is a recursive call.
if ! grep "${SCRIPT_DIR}:" < <( echo "$PATH" ) >/dev/null; then
  if [ "$SCRIPT_DIR_INSTALLATION" != "$SCRIPT_DIR" ]; then
    # Installation directory differs from project.  Prepend installation
    # directory first, as project level scripts override installation level
    # ones.
    PATH="$SCRIPT_DIR_INSTALLATION:$PATH"
    PATH="$SCRIPT_DIR_INSTALLATION/override:$PATH"
    PATH="$SCRIPT_DIR_INSTALLATION/command:$PATH"
    PATH="$SCRIPT_DIR_INSTALLATION/command/plugin:$PATH"
    PATH="$SCRIPT_DIR_INSTALLATION/command/override:$PATH"
  fi
  # Define Project level path to scripts that are included in
  # command scripts.  Note - included script names must be different
  # from command script names.
  PATH="$SCRIPT_DIR:$PATH"
  # Define Project level function override directory for Included scripts.
  # Each Include script automatically imports a file whose name is 
  # generated by adding a suffix of "Override.sh" to the Include script name.
  # This mechanism enables functions developed by others to override, replace 
  # the implementation of functions within Include scripts.
  PATH="$SCRIPT_DIR/override:$PATH"
  # Define Project level Command directory containing all
  # dlw's Command scripts.
  PATH="$SCRIPT_DIR/command:$PATH"
  # Define Project level directory to manage end user provided dlw commands or
  # completely override/replace existing ones.
  PATH="$SCRIPT_DIR/command/plugin:$PATH"
  # Define Project level directory to manage bash include files containing
  # functions developed by others that override, replace the implementation
  # of, the functions within Command scripts.  Each Command automatically imports
  # a file whose name is generated by adding a suffix of "Override.sh"
  # to the command name.  Ex. Command: 'rmi' generates a 
  # corresponding override file named: 'rmiInclude.sh'. 
  export PATH="$SCRIPT_DIR/command/override:$PATH"
  SCRIPT_RECURSIVE='false'
else
  # recursive call detected 
  SCRIPT_RECURSIVE='true'
fi
source "MessageInclude.sh";
source "ArgumentsGetInclude.sh";
source "ArrayMapTestInclude.sh";
source "VirtCmmdInterface.sh";
###############################################################################
##
##  Purpose:
##    Define default configuration for dlw's command execution context.
##
###############################################################################
function VirtCmmdConfigSetDefault() {
  # Ensure that bash shell is invoked by all subsequent scripts.
  export SHELL="/bin/bash"
  # Define Project Directory that contains all the various
  # objects required by this build system.  The Project directory
  # is the current working directory of the dlw command.  Note, the full
  # path name to the current directory must be used, as makefile execution 
  # will likely change the current directory, nullifying the currrent resolution
  # values of relative file references
  export PROJECT_DIR="`pwd`"
  # Provide the Project's name
  export PROJECT_NAME="`basename "$PROJECT_DIR"`"
  # Define the directory to implement the Image Catalog where the 
  # Image GUID List for each Component resides.
  export IMAGE_CAT_DIR="$PROJECT_DIR/image"
  # Define the directory to maintain the Image Time Stamp Catalog where a surrogate
  # 'image' file is generated to maintain its build time stamp for comparision
  # to the resources required to build the image.
  export IMAGE_BUILD_TIMESTAMP_DIR="$IMAGE_CAT_DIR/build"
  # Define the directory to implement the Component Catalog which contains the
  # Component dependency file, project Components, and resources/context for 
  # each Component differenciated by the docker command.
  export COMPONENT_CAT_DIR="$PROJECT_DIR/component"
  # Define the directory to implement the Component Catalog which contains the
  # Component dependency file, project Components, and resources/context for 
  # each Component differenciated by the docker command.
  export COMPONENT_CAT_DEPENDENCY="$COMPONENT_CAT_DIR/Dependency"
  # Ensure makefile layer exists and record its directory location.
  # makefile local to project script directory overrides installation level one. 
  local makefileDir="$SCRIPT_DIR"
  if ! [ -f  "$makefileDir/makefile" ]; then
    # attempt to find installation level one. 
    makefileDir="$SCRIPT_DIR_INSTALLATION"
    if ! [ -f  "$makefileDir/makefile" ]; then
      ScriptUnwind $LINENO "'makefile' dependency cannot be found in either project: '$SCRIPT_DIR' or installation: '$SCRIPT_DIR_INSTALLATION' script directory."
    fi
  fi
  export MAKEFILE_DIR="$makefileDir"
  # Define a temp file location within the Project's directory.
  export TMPDIR="$PROJECT_DIR/tmp"
  TmpDirRemove
  mkdir "$TMPDIR" >/dev/null 2>/dev/null
  
  return 0;
}
###############################################################################
##
##  Purpose:
##    Extract the command to be executed by dlw.sh.  It should always be the
##    first non-option argument.  That first argument is the only one
##    acted on and consumed by dlw.sh.
##
##  Inputs:
##    $1 - Variable name to an array whose values contain the label names
##         of the options and agruments appearing on the command line in the
##         order specified by it.
##    $2 - Variable name to an associative array whose key is either the
##         option or argument label and whose value represents the value
##         associated to that label.
##  Outputs:
##    When Successful:
##      All the argument passes a "sniff' test to ensure its valid command.
##    When Failure: 
##      SYSERR - Indicates unknown command.
##
###############################################################################
function VirtCmmdOptionsArgsVerify () {
  local -a dlwArgList
  local -A dlwArgMap
  if AssociativeMapKeyExist "$2" 'Arg1'; then
    dlwArgList[0]='Arg1'
    eval dlwArgMap\[\'Arg1\'\]=\"\$\{$2\[\'Arg1\'\]\}\"
  fi
  if OptionsArgsVerify 'VirtCmmdOptionsArgsDef' 'dlwArgList' 'dlwArgMap'; then
    #  This function can change the value of options/arguments.  In this
    #  case there is only one.  So must ripple this change back to
    #  original array.
    if AssociativeMapKeyExist 'dlwArgMap' 'Arg1'; then
      if ! AssociativeMapKeyExist "$2" 'Arg1'; then
        eval $1\+\=\(\'Arg1\'\)
      fi
      eval $2\[\'Arg1\'\]\=\"\$\{dlwArgMap[\'Arg1\'\]\}\"
    else
      #  Shouldn't happen as there should always be one argument
      return 1;
    fi
  else
    return 1;
  fi
}
###############################################################################
##
##  Purpose:
##    Define the argument accepted by the 'dlw' command.
##
###############################################################################
function VirtCmmdOptionsArgsDef (){
cat <<OPTIONARGS
Arg1 single help "CommandListVerify \\<Arg1\\>" required ""
OPTIONARGS
return 0
}
###############################################################################
##
##  Purpose:
##    Verify that the command name appears in the list of commands supported
##    by this script.  Interrogate the help.sh command to enumerate the 
##    supported commmands.
##
##  Inputs:
##    $1 - Command name
## 
##  Outputs:
##    When Failure: 
##      SYSERR - A message indicating reason for an error.
###############################################################################
function CommandListVerify () {
  local -r cmdName="$1"
  local cmdEntry
  while read cmdEntry; do
    if [ "$cmdName" == "$cmdEntry" ]; then return 0; fi
  done < <( "help.sh" '--dlwcmdlst=true' -- 'all' )
  echo "Command Name: '$cmdName' unknown.">&2
  return 1
return 0
}
###############################################################################
VirtCmmdOptionHelpVerify () {
  return 0
}
###############################################################################
##
##  Purpose:
##    Disable --help for the dlw command because it supports a command
##    called help.
##
###############################################################################
function VirtCmmdHelpIsDisplay () {
  return 1;
}
##############################################################################
##
##  Purpose:
##    Execute the dlw.sh subcommand.
##
##  Assumption:
##    Since bash variable names are passed to this routine, these names
##    cannot overlap the variable names locally declared within the
##    scope of this routine or its decendents.
##
##  Inputs:
##    $1 - Variable name to an array whose values contain the label names
##         of the options and agruments appearing on the command line in the
##         order specified by it.
##    $2 - Variable name to an associative array whose key is either the
##         option or argument label and whose value represents the value
##         associated to that label.
## 
##  Outputs:
##    When failure:
##      SYSERR - Reflects error message.
##
###############################################################################
function VirtCmmdExecute () {
  local -a optArgSubCommandLst
  local -A optArgSubCommandMap
  eval local -r subCommandName=\"\$\{$2\[\'Arg1\']\}\.sh\"
  OptionsArgsRemove 'Arg1' "$1" "$2" 'optArgSubCommandLst' 'optArgSubCommandMap'
  eval $subCommandName `OptionsArgsGen 'optArgSubCommandLst' 'optArgSubCommandMap'`
  if [ "$?" -eq '0' ]; then TmpDirRemove; fi 
}
##############################################################################
##
##  Purpose:
##    Remove the temporary directory deleting all its contents.
##
##  Assumption:
##    1. TMPDIR has been properly assigned before calling.
##    2. TMPDIR must be preserved during recursive calls, as the execution
##       context for certain functions relies on temporarily stored state.
##
##  Inputs:
##    TMPDIR - Variable name specifying the directory being removed.
## 
##  Outputs:
##    Silently fail or succeed 
##
###############################################################################
function TmpDirRemove () {
  # Determine if top of potentially recursive call stack
  if $SCRIPT_RECURSIVE; then
    # Not at top of recursive call stack :: don't delete temporary files
    # Note temporary files will remain in situations where some utility called
    # the initiating dlw session.
    return 0;
  fi
  if [ "$TMPDIR" != "$PROJECT_DIR/tmp" ]; then
    ScriptUnwind "$LINENO" "Expected temporary files to be within project directory: '$PROJECT_DIR/tmp' but it was: '$TMPDIR'."
  fi
  rm -f -r "$TMPDIR" >/dev/null 2>/dev/null
  return 0
}

FunctionOverrideCommandGet
source "ArgumentsMainInclude.sh";
