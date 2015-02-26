#!/bin/bash
###############################################################################
##
##  Purpose:
##    Extract and format Docker command options.
##
##  Output:
##    SYSOUT - A list of docker options for the provided command.
##
###############################################################################
function DockerOptionsFormat () {
  local -r commandName="$1"
  function VirtOptionsExtractHelpDisplay () {
    docker help "$commandName" 2>&1
  }
  OptionsExtract 'docker'
  return 0
}
###############################################################################
##
##  Purpose:
##    Generate common help text explaining command 'TARGET' argument.
##
##  Inputs:
##    $1  - Optional additional text to display as trailing sentence
##          explaining 'all' semantics.  if $1 empty then display default
##          behavior message.
## 
##  Outputs:
##    SYSOUT
##      Help message text.
##
###############################################################################
function HelpCommandTarget() {
  local allSemantics='Default Behavior.'
  if [ -n "$1" ]; then allSemantics="$1"; fi
  echo "TARGET:  {'all'|COMPONENT [COMPONENT...]}"
  echo "  'all'              Process all Components defined by Project. $allSemantics"
  echo "  COMPONENT          Replace with one or more Component names."
}
function HelpOptionHeading  () {
  echo ''
  echo 'OPTIONS: dlw:'
}
function HelpComponentVersion  () {
  local defaultValue="$1"
  if [ -n "$defaultValue" ]; then 
    ComponentVersionVerify "$defaultValue"
  fi
  defaultValue="`ColumnPadding "$defaultValue" 3`"
  echo "    --dlwcomp-ver=$defaultValue     Apply command to specified Component version managed by Image Catalog."
  echo "                          Valid values: [cur|all|allButCur]."
  echo "                            'cur' - Most recent (latest) Component version."
  echo "                            'all' - Current and every past version."
  echo "                            'allButCur' - Every past version."
}
function HelpComponentOrder () {
  local -r operationName="$2"
  HelpTrueFalseOption  '--dlwno-order' "  Do not order $operationName by dependencies." "$1"
}
function HelpComponentNoPrereq () {
  local -r operationName="$1"
  local defaultValue="$2"
  if [ -n "$defaultValue" ]; then 
    ComponentNoPrereqVerify "$defaultValue"
  fi
  defaultValue="`ColumnPadding "$defaultValue" 5`"
  echo "    --dlwno-prereq=$defaultValue  Ignore Component dependencies when generating and ordering"
  echo "                          command for $operationName."
  echo '                          Valid values: [true|order|false].'
  echo "                            'false' - Include prerequisite Component(s) when generating commands for"
  echo "                                      targeted Component(s) and order execution by this command's"
  echo "                                      dependency graph."
  echo "                            'order' - Generate command(s) for only the Component(s) specified by the"
  echo "                                      target list but order exection by this command's dependency graph."
  echo "                            'true'  - Generate command(s) for only the Component(s) specified by the"
  echo "                                      target list and order by the Component's position in the command's"
  echo "                                      target list."
}
function HelpIgnoreStateDocker () {
  HelpTrueFalseOption '--dlwign-state' ' Ignore container state when generating docker command.' "$1"
}
function HelpNoExecuteDocker () {
  HelpTrueFalseOption '--dlwno-exec' '   Do not execute the generated docker command.' "$1"
}
function HelpShowDocker (){
  local defaultValue="$1"
  if [ -n "$defaultValue" ]; then 
    ShowOptionVerify "$defaultValue";
  fi
  defaultValue="`ColumnPadding "$defaultValue" 6`"
  echo "    --dlwshow=$defaultValue      Write the generated docker command to SYSOUT."
}
function HelpHelpDisplay (){
  HelpTrueFalseOption '--help' '         Display help for this command.' "$1"
}
function HelpColumnSelectExclude () {
  local defaultValue="$1"
  if [ -n "$defaultValue" ]; then 
    ColumnSelectExcludeVerify "$defaultValue"
  fi
  defaultValue="`ColumnPadding "$defaultValue" 9`"
  echo "    --dlwcol=${defaultValue}    Include dlw column."
  echo '                            syntax: <AttributeName>[/[<ColumnName>][/<ColumnWidth>]][,..'
  echo "                            <AttributeName> - dwl attribute name. Special name of 'all'"
  echo '                                              includes every dlw attribute name in report while the special'
  echo "                                              name of 'none' excludes all dlw extended attribute names." 
  echo '                            <ColumnName>    - use this label as column heading instead of attribute name.'
  echo '                            <ColumnWidth>   - attribute values will be space padded or truncated to this length.'
  echo "                            To display only Docker columns, specify an empty string ('') for its value."
}
function HelpTrueFalseOption () {
  local optionName="$1"
  local optionMessage="$2"
  local defaultValue="$3"
  if [ -n "$defaultValue" ]; then 
    OptionsArgsBooleanVerify "$defaultValue";
  fi
  defaultValue="`ColumnPadding "$defaultValue" 5`"
  echo "    $optionName=$defaultValue $optionMessage"
}
function HelpColumnHeadingRemove () {
  HelpTrueFalseOption '--dlwno-hdr' '    Remove all column headings.' "$1"
}

###############################################################################
##
##  Purpose:
##    Pad a given column to its maximum length with spaces.
##
##  Assumption:
##    Since bash variable names are passed to this routine, these names
##    cannot overlap the variable names locally declared within the
##    scope of this routine or its decendents.
##
##  Inputs:
##    $1 - Column value to print.
##    $2 - Maximum column width.
##    SYSIN - Output from the Execute command.
## 
##  Return Code:     
##    When Failure: 
##      Indicates unknown parse state or token type.
##
###############################################################################
function ColumnPadding () {
  local -r columnValue="$1"
  local -ir columnWidthMax=$2
  local -ir valueLen=${#columnValue}
  local -ir repeatCnt=$columnWidthMax-$valueLen
  printf '%s' "$columnValue"
  if [ $repeatCnt -gt 0 ]; then
    eval printf \' \%\.0s\' \{1\.\.$repeatCnt\}
  fi
  return 0
}
###############################################################################
##
##  Purpose:
##    Generate declarative argument entries to verify the Component
##    list for specific command.  The argument entry assumes the Component
##    list represents the entire argument list, entries 1-N.
##
##  Inputs:
##    $1  - Command name.
##    $2  - Default value.
## 
##  Outputs:
##    SYSOUT
##      Declarative table entries to verify the Component Name as the first
##      argument.
##
###############################################################################
function ComponentNmListArgument () {
  local -r commandNm="$1"
  local -r defaultValue="$2"
  echo "Arg1 single '$defaultValue' 'ComponentNmListVerify $commandNm \<Arg1\>' required ''"
  echo "ArgN list '' 'ComponentNmListVerify $commandNm \<ArgN\>' optional ''"
}
###############################################################################
##
##  Purpose:
##    Generate declarative long option entry to verify a Component's version
##    specifier.
##
##  Outputs:
##    SYSOUT
##      Declarative long option entry
##
###############################################################################
function ComponentVersionArgument () {
  local -r defaultValue="$1"
  echo "--dlwcomp-ver single '$1' 'ComponentVersionVerify \<--dlwcomp-ver\>' required ''"
}
###############################################################################
##
##  Purpose:
##    Verify the GUID scope specified for a command.
##      "cur" - Limit a Component's image GUID to only its 
##              most recent image version.
##      "all" - For a given Component show every known image GUID.
##      "allButCur" - For a given Component show every known image GUID
##                    except its most recent one.
##
##  Inputs:
##    $1    - GUID scope option value.
## 
##  Outputs:
##    When Failure: 
##      SYSERR - A message indentifying the provided component names that don't 
##               exist in the list of all component names that are valid for
##               the specified command.
##
###############################################################################
function ComponentVersionVerify () {
  local GUIDscope="$1"
  if [   "$GUIDscope" == "cur" \
      -o "$GUIDscope" == "all"     \
      -o "$GUIDscope" == "allButCur" ]; then return 0; fi

  OptionsArgsMessageErrorIssue "Incorrect GUID scope specified: '$1', should be: 'cur', 'all', or 'allButCur'" 
  return 1
}
###############################################################################
##
##  Purpose:
##    Verify the prerequisite setting specified for a command.
##      "true"   - Generate commands for only those Component(s) specified
##                 as targets and order them in target list order.
##      "order" - For a given Component show every known image GUID.
##      "false" - For a given Component show every known image GUID
##
##  Inputs:
##    $1    - Prerequsite setting.
## 
##  Outputs:
##    When Failure: 
##      SYSERR - A message indentifying the provided component names that don't 
##               exist in the list of all component names that are valid for
##               the specified command.
##
###############################################################################
function ComponentNoPrereqVerify () {
  if [    "$1" == 'true'  ] \
     || [ "$1" == 'order' ] \
     || [ "$1" == 'false' ]; then return 0; fi

  OptionsArgsMessageErrorIssue "Incorrect NoPrerequisite specified: '$1', should be: 'true', 'order', or 'false'" 
  return 1
}
###############################################################################
##
##  Purpose:
##    Generate declarative long option entry to remove all column headerings 
##    added by the dlw.
##
##  Outputs:
##    SYSOUT
##      Declarative long option entry
##
###############################################################################
function ColumnHeadingRemove () {
  echo '--dlwno-hdr single false=EXIST=true "OptionsArgsBooleanVerify \<--dlwno-hdr\>" required ""'
}
###############################################################################
##
##  Purpose:
##    Generate declarative long option entry to remove an entire column: both 
##    its data and heading.
##
##  Outputs:
##    SYSOUT
##      Declarative long option entry
##
###############################################################################
function ColumnSelectExclude () {
  echo '--dlwcol single "ComponentName/COMPONENT/15,ComponentDescription/DESCRIPTION/15,=EXIST=none" "ColumnSelectExcludeVerify \<--dlwcol\>" required ""'
}
###############################################################################
##
##  Purpose:
##    Generate declarative long option to affect the reported column list.
##
##  Outputs:
##    When Failure: 
##      SYSERR - A message indicating invalid column specifier.
##
###############################################################################
function ColumnSelectExcludeVerify () {
  local -A colmHdrIncludeMap 
  if ! ColmIncludeDetermine "$1" 'colmHdrIncludeMap'; then return 1; fi
  return 0
}
###############################################################################
##
##  Purpose:
##    Test that a boolean type is being assigned a value of either 
##    'true' or 'false' value.
##
##  Inputs:
##    $1 - Value being assigned to the boolean.
## 
##  Outputs:
##    When Successful:
##    When Failure: 
##      SYSERR - A message indicating reason for an error.
##
###############################################################################
function OptionsArgsBooleanRevVerify () {
  if [ "$1" == "true" -o "$1" == "false" -o "$1" == "rev" ]; then return 0; fi
  OptionsArgsMessageErrorIssue "Value: '$1' invalid.  Please specify either 'true', 'false', or 'rev'."
  return 1;
}
###############################################################################
##
##  Purpose:
##    Test show option value to be either:
##    'false'  - don't display the command to be executed. 
##    'true'   -   write the command to be executed to SYSOUT
##    'packet' - forward the packet containing the commmandor 'false' value.
##
##  Inputs:
##    $1 - Value being assigned to the boolean.
## 
##  Outputs:
##    When Successful:
##    When Failure: 
##      SYSERR - A message indicating reason for an error.
##
###############################################################################
function ShowOptionVerify () {
  if [ "$1" == 'false' ] || [ "$1" == 'true' ] || [ "$1" == 'packet' ]; then return 0; fi
  OptionsArgsMessageErrorIssue "Value: '$1' invalid.  Please specify either 'true', 'false', or 'packet'."
  return 1;
}
FunctionOverrideIncludeGet
