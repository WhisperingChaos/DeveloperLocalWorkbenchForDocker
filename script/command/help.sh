#!/bin/bash
source "MessageInclude.sh";
source "ArgumentsGetInclude.sh";
source "ArrayMapTestInclude.sh";
source "VirtCmmdInterface.sh";
###############################################################################
##
##  Purpose:
##    Insure dlw.sh has established a valid path to the command directory.
##
##  Input:
##    $0 - Name of running script that included this configuration interface.
##
##  Output:
##    When Failure: 
##      SYSERR - Reflect message indicating reason for error
##
#################################################################################
function VirtCmmdConfigSetDefault (){
  return 0
}
###############################################################################
##
##  Purpose:
##    Define both the options and arguments accepted by the 'help' command.
##
###############################################################################
function VirtCmmdOptionsArgsDef (){
cat <<OPTIONARGS
Arg1 single all "CommandListHelpVerify \\<Arg1\\>" required ""
--dlwcmdlst single false=EXIST=true "OptionsArgsBooleanVerify \\<--dlwcmdlst\\>" required ""
OPTIONARGS
return 0
}
###############################################################################
##
##  Purpose:
##    Verify that the command name, including all,
##    appears in the list of commands supported by this script. 
##
##  Inputs:
##    $1 - Command name
## 
##  Outputs:
##    When Failure: 
##      SYSERR - A message indicating reason for an error.
###############################################################################
function CommandListHelpVerify () {
  local -r cmdName="$1"
  if [ "$cmdName" == "all" ]; then return 0; fi
  if [ "$cmdName" == "onlyDocker" ]; then return 0; fi
  CommandListVerify "$cmdName"
}
###############################################################################
##
##  Purpose:
##    Verify that the command name appears in the list of commands supported
##    by this script. 
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
  done < <( CommandList 'all')
  echo "Command Name: '$cmdName' unknown.">&2
  return 1
}
###############################################################################
##
##  Purpose:
##    Produce a list of only command names supported by this script.  There
##    are two varieties of commands: dlw specific ones, that is, dlw commands 
##    that have no Docker equivalent and dlw commands that wrap existing Docker
##    commands.  The dlw specific commands must appear after the wrapper
##    commands and follow the "section" named 'dlw specific:' 
##    
##  Input:
##    $1  - Command scope:
##          'all' - All commands available through the dlw CLI.
##          'onlyDocker' - Only those dlw commands that wrap specific Docker
##          commands.
##
##  Outputs:
##    When Success:
##       SYSOUT - a list of potentially filtered commands, each on a separate
##                line.
##    When Failure: 
##      SYSERR - A message indicating reason for an error.
##
###############################################################################
function CommandList () {
  local -r cmmdScope="$1"
  function CommandExtract (){
    echo "$1"
  }
  local cmdEntry
  local scanState='COMMAND:'
  while read cmdEntry; do
    if [ "$cmdEntry" == "$scanState" ]; then
      scanState='PROCESS_CMDS'
    elif [ "$scanState" == 'PROCESS_CMDS' ]; then
      # empty line signifies end of command list
      if [ -z "$cmdEntry" ]; then return 0; fi
      # remove section header
      if [ "$cmdEntry" == 'dlw specific:' ]; then continue; fi
      CommandExtract $cmdEntry
    fi
  done < <( CommandHelp "$cmmdScope" )
  return 0
}
###############################################################################
##
##  Purpose:
##    Defines the list of commands supported by the dlw and provides a 
##    short description explaining the purpose for each one.
##
##  Constraints:
##    The list of commands is immediately preceeded, without whitespace, by the
##    word "COMMAND:", starting in the first column and followed by End Of Line.
##    Each line of the command list begins with a command name, separated by
##    whitespace from its short description.  There are no empty lines separating commands.
##    Termination of the command list occurs with either the fist blank line
##    or no more lines. 
## 
##  Input:
##    $1  - Command scope:
##          'all' - All commands available through the dlw CLI.
##          'onlyDocker' - Only those dlw commands that wrap specific Docker
##          commands.
##
##  Outputs:
##    SYSOUT - The command list with descriptions.
##
###############################################################################
function CommandHelp () {
  if [ "$1" == 'all' ]; then 
    if ! helpDoc.sh; then 
      ScriptUnwind $LINENO "Missing help text for dlw commands.  File missing or returned fatal error: 'helpDoc.sh'."
    fi
    return 0;
  fi
  if [ "$1" != 'onlyDocker' ]; then 
    ScriptUnwind $LINENO "Unknown command scope: '$1'.  Should be: 'all' or 'onlyDocker'."
  fi
  # display only Docker wrapped command help
  local entry
  local scanState='Initial'
  while read entry; do
    case "$scanState" in 
      Initial)
        if [ "$entry" == 'COMMAND:' ]; then scanState='OnlyDocker'; fi
        ;;
      OnlyDocker)
        if [ "$entry" == 'dlw specific:' ]; then
          scanState='SkipDLW'
          continue
        elif [ -z "$entry" ]; then
          scanState='IncludeRemaining'
        fi
        ;;
      SkipDLW)
        if [ -z "$entry" ]; then
          scanState='IncludeRemaining'
        else
          continue
        fi
        ;;
      IncludeRemaining)
        ;;
      *) ScriptUnwind $LINENO "Transitioned to unknown state: '$scanState'."
       ;;
    esac
    echo "$entry"
  done < <( helpDoc.sh )
  return 0 
}
###############################################################################
##
##  Purpose:
##    Describes purpose and arguments for the 'help' command itself.
##
##  Outputs:
##    SYSOUT - The command list with descriptions.
##
###############################################################################
function VirtCmmdHelpDisplay () {
  cat <<COMMAND_HELP_HELP

Provide help for dlw command.

Usage: dlw help [OPTIONS] ARGUMENT

ARGUMENT:  [{'all'|'onyDocker'|COMMAND_NAME}]
    'all'              List help for all commands. Default behavior.
    'onlyDocker'       List only wrapped Docker commands.
    COMMAND_NAME       Specific command name.

OPTIONS:
    --help=false       Provide help for help.
    --dlwcmdlst=false  Provide only the command names.  Applies only to 'all'
                       or 'onlyDocker'.
COMMAND_HELP_HELP
return 0
}
###############################################################################
##
##  Purpose:
##    Implements the dlw help command. It will either list all dlw commands
##    with summary text, list just the command names, or provide
##    help text for a specific dlw command.
##
##  Assumption:
##    Since bash variable names are passed to this routine, these names
##    cannot overlap the variable names locally declared within the
##    scope of this routine or is decendents.
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
##    When Successful:
##      SYSOUT - Displays helpful documentation.
##    When Failure: 
##      SYSERR - Displays informative error message.
##
###############################################################################
function VirtCmmdExecute (){
  local argOptListNm="$1"
  local argOptMapNm="$2"
  local -r target="`AssociativeMapAssignIndirect    "$argOptMapNm" 'Arg1'`"
  local -r cmdLstInd="`AssociativeMapAssignIndirect "$argOptMapNm" '--dlwcmdlst'`"
  if [ "$target" == 'all' ] || [ "$target" == 'onlyDocker' ]; then
    if $cmdLstInd; then
      CommandList "$target"
    else
      CommandHelp "$target"
    fi
    return 0
  fi
 "$target.sh" '--help=true'
}
FunctionOverrideCommandGet
source "ArgumentsMainInclude.sh";


