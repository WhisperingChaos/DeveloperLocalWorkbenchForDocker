#!/bin/bash
###############################################################################
##
##  Purpose:
##    Ensure entire list of component names provided as arguments are actual
##    components of the provided command's context.
##
##  Inputs:
##    $1    - Command name.
##    $2-$n - A list, of one or more component names.
## 
##  Outputs:
##    When Failure: 
##      SYSERR - A message indentifying the provided component names that don't 
##               exist in the list of all component names that are valid for
##               the specified command.
##
###############################################################################
function ComponentNmListVerify (){
  local -r commandName="$1"
  declare -A componentSetAll
  #  A component name of 'all' is always valid representing the entire list of
  #  component names for the given project
  if [ "$2" == "all" ]; then return 0; fi
  local componentName
  for componentName in `ComponentNmListGetAll "$commandName" '-B'`
  do
    componentSetAll["$componentName"]="$componentName"
  done
  shift
  local componentMissingList=""
  local errorTripped=false
  while [ $# -ne 0 ]; do
    if [ "${componentSetAll["$1"]}" != "$1" ]; then
      errorTripped=true
      componentMissingList="$componentMissingList $1"
    fi
  shift
  done
  if $errorTripped; then 
    echo "These component(s): $componentMissingList are absent from the following command context: '$commandName'." >&2
    return 1;
  fi
  return 0;
}
###############################################################################
##
##  Purpose:
##    Retrieve the entire list of components  of Image GUID List names.
##
##  Inputs:
##    $1 - Command name
##    $2 - optional GNU make options
## 
##  Outputs:
##    When Successful:
##      SYSOUT - Displays a single row which enumberates the list Image 
##               GUID List names as columns in this row separated by
##               whitespace.
##
###############################################################################
function ComponentNmListGetAll () {
  local imageGUIDListName=""
  local imageGUIDListNameList=""
  while read imageGUIDListName; do
    imageGUIDListNameList="$imageGUIDListNameList $imageGUIDListName"
  done < <( make --no-print-directory --always-make --directory=$MAKEFILE_DIR COMMAND_CURRENT=$1 COMP_NAME_ONLY=true $1 )
  # echo absent of enclosing quotes cleans leading/trailing whitespace and generates only a single whitespace character between tokens. 
  echo $imageGUIDListNameList | grep '^make: ' >/dev/null 2>/dev/null && imageGUIDListNameList=""
  echo $imageGUIDListNameList
  return 0;
}
FunctionOverrideIncludeGet
