#!/bin/bash
source 'MessageInclude.sh'
###############################################################################
##
##  Purpose:
##    Retrieve a list of component names that comprise the project.  For each
##    component name, determine if the Context associated to a given target
##    type, exists.  If so, generate the target name by concatenating the
##    component name with the provided suffix.
##
##  Input:
##    $1 - Directory path to component directory.
##    $2 - Context path scheme.  A path containing the replaceable keyword
##         "<ComponentName>".
##    $3 - Context suffix value.
## 
##  Output:
##    When Successful:
##      SYSOUT - A list of target names presented as a single row. 
##
###############################################################################
function ContextTargetGen () {
  local -r pathScheme="$2"
  local -r suffixValue="$3"
  local componentName
  local targetNameList=''
  for componentName in `ls -F -- "$1"`
  do
    local directoryContext
    directoryContext="${pathScheme/<ComponentName>/$componentName}"
    if [ -d "$directoryContext" ]; then
      local targetName="${componentName/\//$suffixValue}"
      targetNameList+=" $targetName"
    fi
  done
  echo "${targetNameList:1}"
  return 0
}
###############################################################################
##
##  Purpose:
##    Attempts to replicate a 'make' timestamp comparison between a prerequsite
##    and its target.  
##    
##  Input:
##    $1  - File name of target.
##    $2  - File name of a prerequsite resource to the target
## 
##  Output:
##    0 - true:  target must be rebuilt.
##    1 - false: target need not be rebuilt.
## 
###############################################################################
function TimeStampTripIs () {
  local -r TARGET=`find "$1" -type f -printf '%T@ %p\n' 2> /dev/null | sort -n | tail -1 | awk '{print $1}'`
  local -r PREREQ=`find "$2" -type f -printf '%T@ %p\n' 2> /dev/null | sort -n | tail -1 | awk '{print $1}'`
  # prerequsite or target don't exist, then return true
  if [ -z "$PREREQ" ] || [ -z "$TARGET" ]; then return 0; fi
  # prerequsite older than the target - return false
  if [[ "$PREREQ" > "$TARGET" ]];          then return 1; fi
  # prerequsite same age or younger than target - return true
  return 0
}
###############################################################################
##
##  Purpose:
##    Given a directory, recursively retrive all its subdirectories and 
##    create one long prerequsite line, which also includes the given directory.
##    The wildcard '*' specification is appended to each directory to include
##    every file in the directory as a prerequsite too.
##    
##  Input:
##    $1  - Directory to recurse and return all other directories.
## 
##  Output:
##    When Successful:
##      A single line of all subdirectories.
## 
###############################################################################
function DirectoryRecurse () {
  local dirPathList
  local fileEntry
  # use while - read instead of for loop because file name can contain spaces.
  # However, newlines in file names will break this code. 
  while read fileEntry; do
    # Escape spaces in the directory name.
    fileEntry="${fileEntry// /\\ }"
    # include directory and all its files as prerequsites.
    dirPathList+="$fileEntry $fileEntry/* "
  done < <( find "$1" -type d )
  echo "$dirPathList"
  return 0
}
###############################################################################
##
##  Purpose:
##    Encapsulates shell methods used within the makefile layer to manage
##    its abstractions/concepts.
##    
##  Input:
##    $1    - Method name.
##    $2-$N - Method argument list. 
## 
###############################################################################
  case "$1" in
    ContextTargetGen)	    ContextTargetGen       "$2" "$3" "$4" ;; 
    TimeStampTripIs)        TimeStampTripIs        "$2" "$3"      ;;
    DirectoryRecurse)       DirectoryRecurse       "$2"           ;;
    *) ScriptUnwind "$LINENO" "Unknown method specified: '$1'"    ;;
  esac
exit $?;
