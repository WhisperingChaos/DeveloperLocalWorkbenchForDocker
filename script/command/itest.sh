#!/bin/bash
source "MessageInclude.sh";
source "ArgumentsGetInclude.sh";
source "ArrayMapTestInclude.sh";
source "VirtCmmdInterface.sh";
source "ArgumentsDockerVerifyInclude.sh";
###############################################################################
##
##  Purpose:
##    Insure user is within the 'sample' project as this test script will
##    destructively write to this project space..
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
  if ! [ -d "$PROJECT_DIR" ]; then 
    echo "Error: Project directory for 'sample' must exist.">&2
    return 1
  elif [ "`basename "$PROJECT_DIR"`" != 'sample'  ]; then 
    echo "Error: Must run command while current in the 'sample' project directory.">&2
    return 1
  fi
  # all generated test files share the same prefix to facilitate detection and removal.
  TEST_FILE_PREFIX="$TMPDIR/itest"
  # establishes name space that prefixes each test function. This environment
  # variable is placed here because it is used in function declarations to
  #  prefix function names :: it must be available when the script starts.
  TEST_NAME_SPACE='dlw_Test_'
  # establishes name space that prefixes each function that defines a Component
  # for the sample Project.  This environment variable is placed here because
  # it is used in function declarations to prefix function names :: it must
  # be available when the script starts.
  COMPONENT_NAME_SPACE='SampleProject_Component_'
  # defines complete list of components (image names) required by all tests.
  TEST_COMPONENT_LIST="`SampleProjectComponentNameList "$COMPONENT_NAME_SPACE"`"
  return 0
}
###############################################################################
##
##  Purpose:
##    Define both the options and arguments accepted by the 'itest' command. 
##
###############################################################################
function VirtCmmdOptionsArgsDef (){
cat <<OPTIONARGS
Arg1 single '[0-9]*' "TestSelectSpecificationVerify \\<Arg1\\>" required ""
ArgN single '' "TestSelectSpecificationVerify \\<ArgN\\>" optional ""
--no-clean single false=EXIST=true "OptionsArgsBooleanVerify \\<--no-clean\\>" required ""
--no-check single false=EXIST=true "OptionsArgsBooleanVerify \\<--no-check\\>" required ""
OPTIONARGS
return 0
}
###############################################################################
##
##  Purpose:
##    Ensure test selection specification selects at least one test.
##
##  Input:
##    $1 - A potential RegEx expression.
##
##  Output:
##    When failure:
##      SYSERR    
##
###############################################################################
function TestSelectSpecificationVerify () {
  local -r testSelectSpec="$1"
  if ! read < <( TestSelectSpecificationApply "$testSelectSpec" ); then
    ScriptError "Regex spec of: '$testSelectSpec' must select at least one test."
    return 1
  fi
  return 0
}
###############################################################################
##
##  Purpose:
##    Ensure specification selects at least one test.
##
##  Input:
##    $1 - A possible RegEx
##
##  Output:
##    SYSOUT - zero or more test function names matching RegEx filter.
##
###############################################################################
function TestSelectSpecificationApply () {
  declare -F | awk '{ print $3 }' | grep "^${TEST_NAME_SPACE}$1\$"
}
###############################################################################
##
##  Purpose:
##    Describes purpose and arguments for the 'version' command.
##
##  Outputs:
##    SYSOUT - The command list with descriptions.
##
###############################################################################
function VirtCmmdHelpDisplay () {
  cat <<COMMAND_HELP_INTEGRATION

Execute dlw integration tests against the 'sample' project. Tests will destroy project
  contents, therefore, please save its state to another location to retain any end user
  updates you wish to preserve.  Once a test set successfully completes, the 
  sample Project reverts to its initial install state.

Usage: dlw IntegrationTestOnSample [OPTIONS] TEST_NUM

TEST_NUM:  {'[0-9]*'| REGEX_SPEC [REGEX_SPEC...]}
    '[0-9]*'    Execute every test in numerical order.  Default value.
    REGEX_SPEC  A regular expression that selects the desired integer test label
                set. Must select at least one test to be considered valid. 
                Selected set executed in numerical order.
COMMAND_HELP_INTEGRATION
HelpOptionHeading
cat <<COMMAND_HELP_INTEGRATION_OPTIONS
    --no-clean=false     Retain current project state and begin executing tests.
                           Do not destroy and recreate sample project contents.
    --no-check=false     Continue script execution even when the local Docker Repository
                           contains image names that overlap image names employed by
                           this script or detected remnants of a failed previous
                           test exist.
    --keep-script=false  Retain contents of Project level 'script' directory.  Set
                           to 'true' when testing your own function overrides or
                           plugins using the sample project. 
COMMAND_HELP_INTEGRATION_OPTIONS
return 0
}
###############################################################################
#
#  Purpose:
#    Create one or more containers from the current version of the specified
#    image name.
#
#  Input:
#    $1 - LINENO
#    $2 - dlw & Docker options.
#    $3 - Number of containers to create.
#    $4 - Next Temporary file index to record container GUID.
#
#  Return:
#    0 - Successfully created all containers.
#    Otherwise Abort.
#
###############################################################################
function ContainerCreateAssert () {
  local ixFile
  for ((ixFile=$4; $ixFile < ($3+$4); ixFile++ )); do
    if ! dlw.sh run --cidfile="${TEST_FILE_PREFIX}$ixFile" $2 > /dev/null 2>/dev/null; then
      ScriptUnwind "$1" "Failed run container with following dlw/Docker options: '$2'"
    fi
  done
  ContainerExistAssert $LINENO $4 $3
  return 0;
}
###############################################################################
#
#  Purpose:
#    Test the existence of a container.
#
#  Input:
#    $1 - Container Id
#
#  Return:
#    0 - Container exists.
#    1 - Otherwise.
#
################################################################################
function ContainerExist () {
  local searchGUID=${1:0:12};
  local dockerGUID=`docker ps -a | grep ^$searchGUID`;
  dockerGUID=${dockerGUID:0:12}
  if [ "$dockerGUID" == "$searchGUID" ]; then return 0; fi
  return 1;
}
###############################################################################
#
#  Purpose:
#    Ensure that given range of containers exist.
#
#  Input:
#    $1 - LINENO
#    $2 - Number of containers to check.
#    $3 - Start of range.
#
#  Return:
#    0 - Assertion true.
#    Otherwise Abort.
#
###############################################################################
function ContainerExistAssert (){
 local ixFile
 for ((ixFile=$3; $ixFile < ($3+$2); ixFile++ )); do 
    cat "${TEST_FILE_PREFIX}$ixFile" | xargs -I GUID bash -c 'ContainerExist GUID'
    if [ $? -ne 0 ]; then ScriptUnwind $1 "Container missing when it should exist.  See ${TEST_FILE_PREFIX}$ixFile"; fi
  done
  return 0;
}
###############################################################################
#
#  Purpose:
#    Ensure that given range of containers have been deleted.
#
#  Input:
#    $1 - LINENO
#    $2 - Number of containers to check.
#    $3 - Start of range.
#
#  Return:
#    0 - Assertion true.
#    Otherwise Abort.
#
###############################################################################
function ContainerDeleteAssert (){
  local ixFile
  for ((ixFile=$3 ; $ixFile < ($3+$2) ; ixFile++ )); do 
    cat "${TEST_FILE_PREFIX}$ixFile" | xargs -I GUID bash -c 'ContainerExist GUID'
    if [ $? -eq 0 ]; then ScriptUnwind $1 "Container exists when it should have been deleted.  See ${TEST_FILE_PREFIX}$ixFile"; fi
  done
  return 0;
}
###############################################################################
#
#  Purpose:
#    Remove containers via make.
#
#  Input:
#    $1 - LINENO
#    $2 - dlw rm options and arguments.
#    $3 - Number of containers to check.
#    $4 - Start of range.
#
#  Return:
#    0 - Remove operation successful.
#    Otherwise Abort.
#
###############################################################################
function ContainerRemoveAssert (){
  if ! dlw.sh rm $2 > /dev/null 2> /dev/null;
    then ScriptUnwind $1 "Container remove failed: parameters: '$2'";
  fi
  ContainerDeleteAssert "$1" "$3" "$4"
  return 0
}
###############################################################################
#
#  Purpose:
#    Ensure provided image GUID has been removed from the local Docker repository.
#
#  Input:
#    $1 - LINENO
#    $2-$N - Docker image GUID.
#
#  Return:
#    0 - Assertion true.
#    Otherwise Abort.
#
###############################################################################
function DockerRepositoryImageDeleteAssert (){
  local lineNo='$1'
  shift
  while [ "$#" -gt '0' ]; do
    if docker inspect --format="{{.Id}}" "$1" >/dev/null 2>/dev/null; then
      ScriptUnwind "$lineNo" "Docker image exists but should have been deleted: $1."
    fi
    shift
  done
  return 0;
}
###############################################################################
#
#  Purpose:
#    Ensure provided image GUID exists in local Docker repository.
#
#  Input:
#    $1 - LINENO
#    $2 - Docker image GUID.
#
#  Return:
#    0 - Assertion true.
#    Otherwise Abort.
#
###############################################################################
function DockerRepositoryImageExistsAssert (){
  docker inspect --format='{{.Id}}' "$2" >/dev/null 2>/dev/null
  if [ $? -ne 0 ]; then ScriptUnwind $1 "Docker image should exist but doesn't: $2."; fi
  return 0;
}
###############################################################################
#
#  Purpose:
#    Obtain the most recent GUID for given image name output it to
#    sysout.
#
#  Input:
#    $1 - LINENO
#    $2 - Docker image name.
#
#  Return:
#    0 - Successful
#    sysout - reflects the GUID.
#    Otherwise Abort.
#
###############################################################################
function DockerRepositoryImageAssign (){
  local -r ImageGUID="`docker inspect --format='{{.Id}}' "$2" 2>/dev/null`";
  if [ $? -ne 0 ]; then ScriptUnwind $LINENO "Docker image name: $2 doesn't exist."; fi
  if [ "$ImageGUID" == "" ]; then ScriptUnwind $LINENO "Docker image GUID for name: $2 not provided."; fi
  echo "$ImageGUID";
  return 0;
}
###############################################################################
#
#  Purpose:
#    Change the content of a Dockerfile resource called ChangeVersion.
#    Assumes that ChangeVersion is a file that's included in the resulting
#    image.
#
#  Input:
#    $1 - Docker image name.
#
###############################################################################
function ImageChangeVersion (){
  echo "$RANDOM" >> "$COMPONENT_CAT_DIR/$1/context/build/ChangeVersion";
}	
###############################################################################
#
#  Purpose:
#    Create a specific image and ensure the image was successfully created.
#
#  Input:
#    $1 - LINENO
#    $2 - build options.
#    $3 - Component name.
#    $4 - Total number of image GUIDs expected in Image GUID List for component.
#
#  Return:
#    0 - Successfully created image and/or desired container instances.
#    Otherwise Abort.
#
###############################################################################
function ImageCreate (){
  local -r lineNo="$1"
  local -r buildOpts="$2"
  local -r compName="$3"
  local -r imageGUIDtot="$4"
  if ! dlw.sh build $buildOpts -- $compName > /dev/null 2> /dev/null; then
    ScriptUnwind "$lineNo" "Build of: $compName failed"
  fi
  ImageGUIDListAssert "$lineNo" "$compName" "$imageGUIDtot"
  return 0;
}
###############################################################################
#
#  Purpose:
#    Remove images and associated containers - even running ones.
#
#  Input:
#    $1 - LINENO
#    $2-$5 - Various "dlw rmi" arguments.
#
#  Return:
#    0 - make Remove operation successful.
#    Otherwise Abort.
#
###############################################################################
function ImageContainerRemove (){
  if ! dlw.sh rmi --dlwrm $2 > /dev/null 2> /dev/null; then 
    ScriptUnwind $1 "$FUNCNAME failed: parameters: '$2'."
  fi
  return 0
}
###############################################################################
#
#  Purpose:
#    Remove image(s) from Local Repository.
#
#  Input:
#    $1 - LINENO
#    $2 - Various "dlw rmi" arguments.
#
#  Return:
#    0 - make Remove operation successful.
#    Otherwise Abort.
#
###############################################################################
function ImageRemoveAssert (){
  if ! dlw.sh rmi $2 > /dev/null; then 
    ScriptUnwind $1 "$FUNCNAME failed: parameters: '$2'."
  fi
  return 0
}
###############################################################################
#
#  Purpose:
#    Report on containers and/or images.
#
#  Input:
#    $1 - LINENO
#    $2 - Type to report on:
#         ps - container
#         images - image
#    $2-$5 - Various "make Show" arguments.
#
#  Return:
#    0 - make Show operation successful.
#    Otherwise Abort.
#
###############################################################################
function ImageContainerShow (){
  dlw.sh $2 $3 $4 $5
  if [ $? -ne 0 ]; then ScriptUnwind $1 "Show failed: parameters: $2 $3 $4 $5"; fi
  return 0
}
###############################################################################
#
#  Purpose:
#    Check Image GUID List to ensure it has proper number of GUIDs.
#
#  Input:
#    $1 - LINENO	
#    $2 - Docker image name.
#    $3 - Expected number of GUIDs.
#
#  Return:
#    0 - GUID List updated correctly.
#    Otherwise Abort.
#
###############################################################################
function ImageGUIDListAssert (){
  local -r lineNo="$1"
  local -r imageGUIDlistName="./image/${2}.GUIDlist"
  local -r expectTot="$3"
  if [ $expectTot -lt 1 ]; then 
    if [ -e "$imageGUIDlistName" ]; then ScriptUnwind $1 "Image GUID List for: '$imageGUIDlistName' shouldn't exist."; fi
    return 0;
  fi
  if ! [ -e "$imageGUIDlistName" ]; then ScriptUnwind $1 "Image GUID List for: '$imageGUIDlistName' should exist."; fi
  local GUIDcnt="`wc -l "$imageGUIDlistName"| awk '{print $1;}'`"
  if [ $GUIDcnt -ne $expectTot ]; then ScriptUnwind $1 "Image GUID List for: '$imageGUIDlistName' contains: '$GUIDcnt' but: '$expectTot' was expected."; fi
  return 0;
}
##############################################################################
#
#  Purpose:
#    Check local Docker repository for an image with the provided name.
#
#  Input:
#    $1 - Docker image name.
#
#  Return:
#    0 - Image exists.
#    1 - Nonexistent image.
#
##############################################################################
function ImageNameExist () {
  if ! docker inspect "$1" > /dev/null 2>/dev/null; then return 1; fi
 return 0;
}
###############################################################################
#
#  Purpose:
#    Examine state of local repository to determine if possible overlap with
#    Component names used by the sample project.
#
#  Input:
#    $1-$N - Docker image name list.
#
#  Return:
#    0 - No image name overlap detected.
#    Otherwise Abort.
#
###############################################################################
function ImageNameLocalOverlapPass () {
  local errorInd='false'
  while [ "$#" -gt '0' ]; do
    if ImageNameExist "$1"; then
      errorInd='true'
      ScriptError "A Docker image with name of: '$1' already exists in local Docker Repository."
    fi
    shift
  done
  if $errorInd; then return 1; fi
  return 0;
}
###############################################################################
#
#  Purpose:
#    Run report with provided options and cache its output for later scanning.
#
#  Assumption:
#    Checking the most recent ReporRun execution.
#    The shell variable 'reportCache' will be used to contain in memory cache.
#
#  Input:
#    $1 - LINENO
#    $2 - Expected Report line total.
#
#  Return:
#    0 - Assertion true.
#    Otherwise Abort
#
###############################################################################
function ReportLineCntAssert () {
  if [ "$2" == "" ]; then ScriptUnwind $1 "Please specify expected line count."; fi
  if [ ${#reportCache[@]} -ne $2 ]; then ScriptUnwind $1 "Line count of: '${#reportCache[@]}' different from expected: '$2'"; fi
  return 0
}
###############################################################################
#
#  Purpose:
#    Run report with provided options and cache its output for later scanning.
#
#  Assumption:
#    Provided arguments do not contain embedded whitespace.
#    The shell variable 'reportCache' will be used to contain in memory cache
#    and its contents are destroyed and recreated every time this function
#    is called.
#
#  Input:
#    $1 - LINENO
#    $2 - dlw command to run.
#
#  Return:
#    0 - Assertion true.
#    Otherwise Abort
#
###############################################################################
function ReportRun () {
 unset reportCache
 if ! SYSOUTcacheRecord 'reportCache' "$2"; then
   ScriptUnwind $1 "Report run problem. Report command: '$2'.";
 fi
}
###############################################################################
#
#  Purpose:
#    Scan provided stream for list of tokens. Tokens are compared on word boundaries
#    using grep.
#
#  Assumption:
#    Recorded SYSOUT stream to 'reportCache' shell variable.
#    Provided arguments do not contain whitespace.
#
#  Input:
#    $1 - LINENO
#    $2 - Scan operation:
#         'I' - Include
#         'E' - Exclude
#    $3 - List of N tokens to check.
#    SYSIN - Stream of tokens to search.
#
#  Return:
#    0 - Assertion true.
#    Otherwise Abort
#    SYSOUT - When about one or more tokens that violated scan operation.
#             Otherwise, nothing. 
#
###############################################################################
function ReportScanTokenAssert (){
  local operName
  local operMess
  if   [ "$2" == 'I' ]; then
    operName='Include';
    operMess='not found'
  elif [ "$2" == 'E' ]; then
    operName='Exclude'
    operMess='found'
 else
    ScriptUnwind $1 "Invalid scan operation specified: '$2'"
  fi 
  local -i tokenCnt
  tokenCnt=$(( $#-2 ))
  if [ $tokenCnt       -lt 1 ]; then ScriptUnwind $1 "Must provide at least one search token!"; fi
  if [ ${#reportCache} -lt 1 ]; then ScriptUnwind $1 "Assert requires at least one line of Report output."; fi
  local tokenErr
  tokenErr=$( SYSOUTcachePlayback 'reportCache' |  StreamScan "$2" ${@:3} 2>&1 )
  if [ $? -ne 0 ]; then ScriptUnwind $1 "$operName tokens $operMess: $tokenErr."; fi
}
###############################################################################
#
#  Purpose:
#    Scan provided report for list of tokens and ensure given token
#    is completely excluded from the report. Tokens are compared on word boundaries
#    using grep.
#
#  Assumption:
#    Provided arguments do not contain whitespace.
#
#  Input:
#    $1 - LINENO
#    $2 - List of N tokens to check for excusion.  Tokens may include
#         limited set of regular expressons
#    SYSIN - Stream of tokens to search.
#
#  Return:
#    0 - Assertion true.
#    Otherwise Abort
#    SYSOUT - When about one or more tokens that violated scan operation.
#             Otherwise, nothing. 
#
###############################################################################
function ReportScanTokenExcludeAssert (){
  ReportScanTokenAssert "$1" 'E' ${@:2}
  return 0;
}
###############################################################################
#
#  Purpose:
#    Scan provided report for list of tokens and ensure given token
#    exists somewhere in report. Tokens are compared on word boundaries
#    using grep.
#
#  Assumption:
#    Provided arguments do not contain whitespace.
#
#  Input:
#    $1 - LINENO
#    $2 - List of N tokens to check for existance.  Tokens may include
#         limited set of regular expressons
#    SYSIN - Stream of tokens to search.
#
#  Return:
#    0 - Assertion true.
#    Otherwise Abort
#    SYSOUT - When about one or more tokens that violated scan operation.
#             Otherwise, nothing. 
#
###############################################################################
function ReportScanTokenIncludeAssert (){
  ReportScanTokenAssert "$1" 'I' ${@:2}
  return 0;
}
###############################################################################
#
#  Purpose:
#    Scan provided stream for list of tokens.  An inclusive scan tests
#    that all provided tokens are mentioned somewhere in the stream.  While
#    an exclusive scan examines the stream to ensure that none of the tokens
#    appear in it.
#
#  Input:
#    $1 - Include/Exclude operator:
#           I - All specified tokens must appear.
#           E - All specified tokens must be absent
#    $2 - list of N tokens to check for existance.
#    SYSIN - Stream to inspect.
#
#  Return:
#    0 - When Exclude: no provided tokens exist in stream.
#        When Include: all tokens exist in stream.
#    1 - Violation detected
#    SYSOUT - When violation occurs, variable name assigned problem token value.
#
###############################################################################
function StreamScan () {
  local -a aTokenFnd
  local line
  local violation
  violation=true
  while read line; do
    local token
    local -i tokenFndIx=0
    for token in ${@:2}
    do
      if [ "${aTokenFnd[tokenFndIx]}" != 'X' ]; then
        echo "$line" | grep -w "$token" > /dev/null
        if [ $? -eq 0 ]; then
          aTokenFnd[tokenFndIx]='X'
        else
          aTokenFnd[tokenFndIx]='A'
        fi
      fi
      let ++tokenFndIx
    done
    local -i iter
    local -i tokenFndCnt=0
    local -i tokenFndNotCnt=0
    for (( iter=0; $iter < $tokenFndIx; iter++ )); do
      if [ "${aTokenFnd[$iter]}" == 'X' ]; then let ++tokenFndCnt; continue; fi
      let ++tokenFndNotCnt;
    done
    if [ "$1" == 'I' ]; then
      if [ $tokenFndCnt -eq $tokenFndIx ]; then
        violation=false
        break
      fi
      violation=true
    elif [ "$1" == 'E' ]; then
      if [ $tokenFndCnt -ne 0 ]; then
        violation=true
      else
        violation=false
      fi
      continue
    else
      ScriptUnwind $LINENO "Scan operator: '$1' invalid"
    fi
  done
  if [ "$violation" = true ]; then
    TokensCausingViolation "$1" 'aTokenFnd' ${@:2}
  fi
  if [ "$violation" = false ]; then return 0; fi
  return 1
}
###############################################################################
#
#  Purpose:
#    Truncate GUID to conform to GUIDs that appear on Docker reports.
#
#  Input:
#    $1 - A GUID of 12 or more charaters.
#
#  Return:
#    SYSOUT - A GUID of exactly 12 characters.
#
###############################################################################
function ReportGUIDformat () {
  echo "${1:0:12}"
}
###############################################################################
##
##  Purpose:
##    Using reflection services, generate the 'sample' Project's 
##    Component list by extracting Component names from functions whose prefix
##    (namespace) matches those reserved to the callback functions that define
##    a specific Component's Component Catalog entry.
##
##  Input:
##     $1  - Component name space prefix assigned to all functions that 
##           define components.
##    'declare -F' - Generates a lis of function names declared in this module.
##
##  Output:
##    When Success: 
##      SYSOUT - contains a single line of space separated Component names.  The
##          Component names start with 'dlw_'.
##
#################################################################################
function SampleProjectComponentNameList () {
  local -r compNameSpace="$1"
  local -r declarePrefix='declare -f '
  local compNameList
  local compName
  while read compName; do
    compName="${compName:${#declarePrefix}}"
    if [ "${compName:0:${#compNameSpace}}" == "$compNameSpace" ]; then
     compNameList="${compName:${#compNameSpace}} $compNameList"
    fi
  done < <( declare -F )
  echo "$compNameList"
  return 0
}
###############################################################################
#
#  Purpose:
#    Remove all files and directories in the sample project except retain
#    an empty Component Catalog (directory).  Also, when directed, retain
#    the Project's Script Catalog to enable testing of end user function
#    overrides and plugins.  
#
#  Input:
#    $1  - LINENO initiating assert.
#    $2  - Option to keep Script Catalog. 
#           'true' - keep
#            otherwise - remove.
#    PROJECT_DIR - Variable set to Project directory to clean.
#    COMPONENT_CAT_DIR - Variable set to Project's Component Catalog.
#
#  Return:
#    0 - Project cleaned.
#    SYSERR - Message indicating artifacts exist in Component Catalog.
#
###############################################################################
function SampleProjectObliterateAssert () {
  local -r lineNo="$1"
  local -r keepScript="$2"
  if [ "keepScript" == 'true' ]; then
    local -r exceptList='component\|script'
  else 
    local -r exceptList='component'
  fi
  # delete all files except those excluded from Project level directory
  ls -A1 "$PROJECT_DIR" | grep -v "$exceptList" | while read entry; do echo "'$PROJECT_DIR/$entry'"; done | xargs rm -f -R 
  local -i pipeStatus=$(( PIPESTATUS[0] + PIPESTATUS[1] + PIPESTATUS[2] + PIPESTATUS[3] ))
  if [ "$pipeStatus" -ne 0 ]; then
   ScriptUnwind "$LINENO" "Cleaning files from project directory: '$PROJECT_DIR' failed.  PIPESTATUS='$pipeStatus'."
  fi
  # delete all files/directories within the Component Catalog but retain
  # the Component root directory
  if ! rm -f -R "$COMPONENT_CAT_DIR"/*; then
    ScriptUnwind "$lineNo" "Remove failed while deleting: '$COMPONENT_CAT_DIR/*'."
  fi
  return 0
}
###############################################################################
#
#  Purpose:
#    Determine if sample project is empty.  If it isn't generate an error
#    indicating that its artifacts may need to be preserved.
#
#  Input:
#    COMPONENT_CAT_DIR - Bash variable set by dlw that's been asserted to
#        reference the 'sample' Project's Component Catalog.
#
#
#  Return:
#    SYSERR - Message indicating artifacts exist in Component Catalog.
#
###############################################################################
function SampleProjectPass () {
  if [ -n "`ls -A "$COMPONENT_CAT_DIR"`" ]; then
    ScriptError "Project Component directory: '$COMPONENT_CAT_DIR' contains artifacts which you may want to preserve."
    return 1
  fi
  return 0
}
###############################################################################
#
#  Purpose:
#    Create and populate a Project's Component Catalog with Project's initial
#    (install) state.
#
#  Input:
#    $1  - Line number of call issuing assert.
#    $2  - Directory path to Project's Component Catalog.
#    $3  - File path to Project's Dependency File.
#    $4  - Function namespace prefix for Components.  Every function employed
#          to manufacture a Component must begin with this prefix and end with
#          its Component name.
#    $5-$N  - The list of Components to be created in the Catalog.  
#
#  Output:
#    When Success:
#      Project succesfully configured.
#    When failure:
#      SYSERR - Message & script terminates.
#
###############################################################################
function ComponentCatalogCreateAssert () {
  local -r lineNo="$1"
  local -r compCatDir="$2"
  local -r compCatDependency="$3"
  local -r compNameSpace="$4"
  local errorInd='false'
  set -- ${@:5}
  while [ "$#" -gt '0' ]; do
    local compName="$1"
    if ! ComponentCreate "$compCatDir" "${compNameSpace}${compName}" 'ComponentDependRuleCapture'; then 
      ScriptError "While attempting to create Component directory structure for Component named: '$compName'."
      errorInd='true'
    fi
    shift
  done
  if ! ComponentDependencyCreate "$compCatDependency"; then 
     ScriptError "Unable to create Dependency file: '$compCatDependency'."
     errorInd='true'
  fi
  if $errorInd; then ScriptUnwind "$lineNo" "Unable to properly create '`basename "$compCatDir"`' Project Components."; fi
  TestFileDeleteAssert $LINENO All
  return 0
}
###############################################################################
#
#  Purpose:
#    Create the Dependency file that establishes the order in which Components
#    should be processed for a given Docker command. Typically, there are only
#    two general classes of dependencies: build and runtime, however,
#    the makefile system can support a distinct dependency graph for each
#    Docker command.
#
#  Input:
#    $1  - Docker Command name.
#    SYSIN - Typically one makefile rule for the given command.
#    TEST_FILE_PREFIX - A path and file name prefix assigned to all files
#         procuded when running this integration test command.
#
#  Output:
#    ${TEST_FILE_PREFIX}${$cmmdName} - A temporary file containing the 
#        makefile rule(s) for the given Docker command and Component.
#  Return:
#    SYSERR - Message describing the reason this function failed.
#
###############################################################################
function ComponentDependencyCreate () {
  local -r componentCatDependency="$1"
  # generate comments that preface the file to provide some explaination
  # regarding its contents.
  cat << DEPENDENCY_FILE_DOC > "$componentCatDependency"
###############################################################################
#
# The content of this file expresses the dependencies between a Component and
# others based on the type of the Docker command being executed.  For example,
# one would encode a makefile dependency rule that associates a Component's
# ancestor (parent, See Docker FROM statement) as a prerequisite for the
# targeted child Component when processing a Docker build command.
#
# A Project that defines interdependent components, must encode this 'Dependency'
# file in the Project's Compnent directory.  Ex: '.../sample/component/Dependency'
# where 'sample' reflects the name assigned to the Project.  
# 
# Although distinct dependency graphs can be specified for each Docker command,
# so far, the makefile rules categorized a Docker command as a member of either
# 'build' or 'run' types.  These dependency types are encoded as makefile rules
# with a suffix of either '.build' or '.run'.  For example, given a Component
# named "Child" with a static build dependency on another Component named
# "Parent" and assuming that "Parent" is a root Component, it doesn't depend
# on other (parent) Components then the dependency graph for the Docker
# 'build' command for these components would be expressed as:
#
#  Child.build : Parent.build
#
# In an analogous way, run-time dependencies, for example, the requirement to 
# start one container before another would be encoded as:
#
#  RequiresServices.run : OffersService_1.run OffersService_2.run
#
# Where containers derived from the images OffersService_1 and OffersService_2
# must be started before initiating a container derived from RequiresServices.
#
# Note, only rules that define dependencies should be specified.  Root (independent)
# Components are automatically deduced by examining the Component Catalog.
#
###############################################################################

DEPENDENCY_FILE_DOC
  if ! [ -f "$componentCatDependency" ]; then
    ScriptUnwind "$LINENO" "Failed to create Dependency file: '$componentCatDependency'."
  fi
  local cmmdName
  while read cmmdName; do
    if [ -f "${TEST_FILE_PREFIX}${cmmdName}" ]; then
       # append each set of makefile rules generated for a specific
       # command to the Dependency file.
       cat "${TEST_FILE_PREFIX}${cmmdName}" >> "$componentCatDependency"
     fi
  done < <( dlw.sh help --dlwcmdlst=true -- onlyDocker )
  return 0
}
###############################################################################
#
#  Purpose:
#    Records every Component's makefile rules to potentially several temporary
#    files, so they can be integrated into a single Dependecy file.  Since each Docker 
#    command can implement its own depency graph, a temporary file may exist for
#    each command.  A temporary file clusters all makefile rules for a
#    specific command so they may be added as a coherent "section" to the 
#    Dependency file by a later process.
#
#  Input:
#    $1  - Docker Command name.
#    SYSIN - Typically one makefile rule for the given command.
#    TEST_FILE_PREFIX - A path and file name prefix assigned to all files
#         procuded when running this integration test command.
#
#  Output:
#    ${TEST_FILE_PREFIX}${$cmmdName} - A temporary file used to contain the 
#        makefile rule(s) for the given Docker command and Component.
#  Return:
#    SYSERR - Message describing the reason this operation failed.
#
###############################################################################
function ComponentDependRuleCapture () {
  local -r cmmdName="$1"
  local dependSpec
  while read dependSpec; do
    echo "$dependSpec">>"${TEST_FILE_PREFIX}${cmmdName}"
    if ! [ "-f ${TEST_FILE_PREFIX}${cmmdName}" ]; then 
      ScriptError "Could not capture Component's makefile dependency as file named: '${TEST_FILE_PREFIX}${cmmdName}'."
      return 1
    fi
  done
  return 0 
}
###############################################################################
#
#  Purpose:
#    Create a specific Component's Catalog instance containing its Command
#    Context directories and populate them with appropriate resources.  Also
#    update the Component Catalog's Dependency Specification with the appropriate
#    Component-Command level GNU makefile rules.
#    
#    A 'conversation' between a Component specific callback function populates
#    the Catalog structure created by this routine.
#
#  Input:
#    $1  - Directory path to Project's Component Catalog.
#    $2  - The name of a callback function providing Component specific 
#          information.
#    $3  - The name of a callback function accepting streamed input in the form
#          of makefile dependency rules from another process' SYSOUT.
#
#  Output:
#    When successful:
#      A successfull constructed Component specific Catalog entry.
#    Otherwise:
#      SYSERR - One or more messages indicating reason for failing to successfully
#               construct the Component Catalog.
#      An incomplete Component specific Catalog entry.
#
###############################################################################
function ComponentCreate () {
  local -r compDir="$1"
  local -r compCallBackFunNm="$2"
  local -r depndProcSubFunNm="$3"
  local -r compName="`$compCallBackFunNm 'NameGet'`"
  # create specific Component's hive
  local -r compHive="$compDir/$compName"
  if ! mkdir "$compHive"; then 
    ScriptUnwind $LINENO "Creating Component directory: '$compHive' failed."
  fi
  # create specific Component's Context directory
  local -r compContextDirName="$compHive/context"
  if ! mkdir "$compContextDirName"; then 
    ScriptUnwind $LINENO "Creating Component Context directory: '$compContextDirName' failed."
  fi
  local errorInd='false'
  function ContextError () {
    ScriptError "$1"
    errorInd='true'
  }
  local commandName
  while read commandName; do
    # create specific Component's Context directory for each Command
    $compCallBackFunNm 'ContextSupported' "$commandName"
    local -i supportLevel="$?"
    if [ "$supportLevel" -gt '1' ]; then
      ContextError "Component named: '$compName' lacks support for Command Context: '$commandName'."
    fi
    if [ "$supportLevel" == '0' ]; then
      # support level indicates Component's Command Context will contribute content.
      local compCmmdContextDirName="$compContextDirName/$commandName"
      if ! mkdir "$compCmmdContextDirName"; then 
        ContextError "Creating Component Context Command directory: '$compCmmdContextDirName' failed."
      fi
      # call callback function to populate specific Component's Command Context directory
      # with its resources.
      if ! $compCallBackFunNm 'ContextCreate' "$commandName" "$compCmmdContextDirName"; then 
        ContextError "Saving resources to Component Context Command directory: '$compCmmdContextDirName' failed."
      fi
    fi
    # call callback function to acquire Dependency Specification, if it exists, and eventually update Catalog level Dependency Spec file.
    if ! $compCallBackFunNm 'DependencySpecUpdate' "$commandName" "$depndProcSubFunNm"; then 
      ContextError "Component named: '$compName' Dependency Specification update for Command Context: '$commandName' failed."
    fi
  done < <( dlw.sh help --dlwcmdlst=true -- onlyDocker )
  if $errorInd; then return 1; fi
  return 0
}
###############################################################################
#
#  Purpose:
#    Create a specific Component's Catalog instance containing its Command
#    Context directories and populate them with appropriate resources.  Also
#    update the Component Catalog's Dependency Specification with the appropriate
#    Component-Command level GNU makefile rules.
#    
#    A 'conversation' between a Component specific callback function populates
#    the Catalog structure created by this rouitine.
#
#  Input:
#    $1  - Directory path to Project's Component Catalog.
#    $2  - The name of a callback function providing Component specific 
#          information.
#    $3  - The name of a callback function accepting streamed input in the form
#          of makefile dependency rules from another process' SYSOUT.
#
#  Output:
#    When successful:
#      A successfull constructed Component specific Catalog entry.
#    Otherwise:
#      SYSERR - One or more messages indicating reason for failing to successfully
#               construct the Component Catalog.
#      An incomplete Component specific Catalog entry.
#
###############################################################################
function SampleProject_Component_dlw_sshserver  () {
  local -r methodName="$1"
  local -r commandName="$2"
  case "$methodName" in
    NameGet)
      echo "dlw_sshserver"
      ;;
    ContextSupported)
      local -A cmmdSupportMap
      cmmdSupportMap["attach"]="1"
      cmmdSupportMap["build"]="0"
      cmmdSupportMap["diff"]="1"
      cmmdSupportMap["images"]="1"
      cmmdSupportMap["kill"]="1"
      cmmdSupportMap["logs"]="1"
      cmmdSupportMap["pause"]="1"
      cmmdSupportMap["port"]="1"
      cmmdSupportMap["ps"]="1"
      cmmdSupportMap["restart"]="1"
      cmmdSupportMap["images"]="1"
      cmmdSupportMap["rm"]="1"
      cmmdSupportMap["rmi"]="1"
      cmmdSupportMap["create"]="1"
      cmmdSupportMap["run"]="0"
      cmmdSupportMap["start"]="1"
      cmmdSupportMap["stop"]="1"
      cmmdSupportMap["top"]="1"
      cmmdSupportMap["unpause"]="1"
      local supportLevel="${cmmdSupportMap["$commandName"]}" 
     if [ -z "$supportLevel" ]; then return 3; else return $supportLevel; fi
      ;;
    ContextCreate)
      if [ "$commandName" == 'run' ]; then return 0; fi
      if [ "$commandName" != 'build' ]; then return 1; fi
      local compCmmdContextDirName="$3"
      echo "dlw_sshserver Initial">"$compCmmdContextDirName/ChangeVersion"
      if ! [ -f "$compCmmdContextDirName/ChangeVersion" ]; then
        ScriptError "Failed to initialize Command Context for Component: 'dlw_sshserver' Command: '$commandName' Content: '$compCmmdContextDirName/ChangeVersion'."
        return 1
      fi
      cat <<DockerFile_dlw_sshserver >"$compCmmdContextDirName/Dockerfile"
###############################################################################
#
# Purpose: Construct a minimal Ubuntu V12.04 image that simply includes the
# a configurable file.  This is a pseudo sshserver implementation
#
##############################################################################

FROM	   ubuntu:12.04
MAINTAINER Richard Moyse <license@Moyse.US>

ADD ChangeVersion /root/

RUN echo "dlw_sshserver">/root/ComponentName.txt

# Create an entry point to automatically run the bash shell. Permits further configuration.
ENTRYPOINT  /bin/bash
DockerFile_dlw_sshserver
      if ! [ -f "$compCmmdContextDirName/Dockerfile" ]; then
        ScriptError "Failed to initialize Command Context for Component: 'dlw_sshserver' Command: '$commandName' Content: '$compCmmdContextDirName/Dockerfile'."
        return 1
      fi
      ;;
    DependencySpecUpdate)
      $FUNCNAME 'ContextSupported' "$commandName"
      if [ "$?" -gt '1' ]; then return 1; fi
      # do nothing as dlw_sshserver is an independent component.
      ;;
    *) ScriptUnwind $LINENO "Unknown method specified: '$methodName'" ;;
  esac
  return 0
}
###############################################################################
#
#  Purpose:
#    Create a specific Component's Catalog instance containing its Command
#    Context directories and populate them with appropriate resources.  Also
#    update the Component Catalog's Dependency Specification with the appropriate
#    Component-Command level GNU makefile rules.
#    
#    A 'conversation' between a Component specific callback function populates
#    the Catalog structure created by this rouitine.
#
#  Input:
#    $1  - Directory path to Project's Component Catalog.
#    $2  - The name of a callback function providing Component specific 
#          information.
#    $3  - The name of a callback function accepting streamed input in the form
#          of makefile dependency rules from another process' SYSOUT.
#
#  Output:
#    When successful:
#      A successfull constructed Component specific Catalog entry.
#    Otherwise:
#      SYSERR - One or more messages indicating reason for failing to successfully
#               construct the Component Catalog.
#      An incomplete Component specific Catalog entry.
#
###############################################################################
function SampleProject_Component_dlw_parent  () {
  local -r methodName="$1"
  local -r commandName="$2"
  case "$methodName" in
    NameGet)
      echo "dlw_parent"
      ;;
    ContextSupported)
      local -A cmmdSupportMap
      cmmdSupportMap["attach"]="1"
      cmmdSupportMap["build"]="0"
      cmmdSupportMap["diff"]="1"
      cmmdSupportMap["images"]="1"
      cmmdSupportMap["kill"]="1"
      cmmdSupportMap["logs"]="1"
      cmmdSupportMap["pause"]="1"
      cmmdSupportMap["port"]="1"
      cmmdSupportMap["ps"]="1"
      cmmdSupportMap["restart"]="1"
      cmmdSupportMap["images"]="1"
      cmmdSupportMap["rm"]="1"
      cmmdSupportMap["rmi"]="1"
      cmmdSupportMap["create"]="1"
      cmmdSupportMap["run"]="1"
      cmmdSupportMap["start"]="1"
      cmmdSupportMap["stop"]="1"
      cmmdSupportMap["top"]="1"
      cmmdSupportMap["unpause"]="1"
      local supportLevel="${cmmdSupportMap["$commandName"]}" 
     if [ -z "$supportLevel" ]; then return 3; else return $supportLevel; fi
      ;;
    ContextCreate)
      if [ "$commandName" != 'build' ]; then return 1; fi
      local compCmmdContextDirName="$3"
      echo "dlw_parent Initial">"$compCmmdContextDirName/ChangeVersion"
      if ! [ -f "$compCmmdContextDirName/ChangeVersion" ]; then
        ScriptError "Failed to initialize Command Context for Component: 'dlw_parent' Command: '$commandName' Content: '$compCmmdContextDirName/ChangeVersion'."
        return 1
      fi
      cat <<DockerFile_dlw_parent >"$compCmmdContextDirName/Dockerfile"
###############################################################################
#
# Purpose: Construct a minimal Ubuntu V12.04 image that simply includes the
# a configurable file.  This is a pseudo sshserver implementation
#
##############################################################################

FROM	   ubuntu:12.04
MAINTAINER Richard Moyse <license@Moyse.US>

ADD ChangeVersion /root/

RUN echo "dlw_parent">/root/ComponentName.txt

# Create an entry point to automatically run the bash shell. Permits further configuration.
ENTRYPOINT  /bin/bash
DockerFile_dlw_parent
      if ! [ -f "$compCmmdContextDirName/Dockerfile" ]; then
        ScriptError "Failed to initialize Command Context for Component: 'dlw_parent' Command: '$commandName' Content: '$compCmmdContextDirName/Dockerfile'."
        return 1
      fi
      ;;
    DependencySpecUpdate)
      $FUNCNAME 'ContextSupported' "$commandName"
      if [ "$?" -gt '1' ]; then return 1; fi
      # do nothing as dlw_parent is an independent component.
      ;;
    *) ScriptUnwind $LINENO "Unknown method specified: '$methodName'" ;;
  esac
  return 0
}
###############################################################################
#
#  Purpose:
#    Create a specific Component's Catalog instance containing its Command
#    Context directories and populate them with appropriate resources.  Also
#    update the Component Catalog's Dependency Specification with the appropriate
#    Component-Command level GNU makefile rules.
#    
#    A 'conversation' between a Component specific callback function populates
#    the Catalog structure created by this rouitine.
#
#  Input:
#    $1  - Directory path to Project's Component Catalog.
#    $2  - The name of a callback function providing Component specific 
#          information.
#    $3  - The name of a callback function accepting streamed input in the form
#          of makefile dependency rules from another process' SYSOUT.
#
#  Output:
#    When successful:
#      A successfull constructed Component specific Catalog entry.
#    Otherwise:
#      SYSERR - One or more messages indicating reason for failing to successfully
#               construct the Component Catalog.
#      An incomplete Component specific Catalog entry.
#
###############################################################################
function SampleProject_Component_dlw_mysql  () {
  local -r methodName="$1"
  local -r commandName="$2"
  case "$methodName" in
    NameGet)
      echo "dlw_mysql"
      ;;
    ContextSupported)
      local -A cmmdSupportMap
      cmmdSupportMap["attach"]="1"
      cmmdSupportMap["build"]="0"
      cmmdSupportMap["diff"]="1"
      cmmdSupportMap["images"]="1"
      cmmdSupportMap["kill"]="1"
      cmmdSupportMap["logs"]="1"
      cmmdSupportMap["pause"]="1"
      cmmdSupportMap["port"]="1"
      cmmdSupportMap["ps"]="1"
      cmmdSupportMap["restart"]="1"
      cmmdSupportMap["images"]="1"
      cmmdSupportMap["rm"]="1"
      cmmdSupportMap["rmi"]="1"
      cmmdSupportMap["create"]="1"
      cmmdSupportMap["run"]="0"
      cmmdSupportMap["start"]="1"
      cmmdSupportMap["stop"]="1"
      cmmdSupportMap["top"]="1"
      cmmdSupportMap["unpause"]="1"
      local supportLevel="${cmmdSupportMap["$commandName"]}" 
     if [ -z "$supportLevel" ]; then return 3; else return $supportLevel; fi
      ;;
    ContextCreate)
      local -r compCmmdContextDirName="$3"
      if [ "$commandName" == 'run' ]; then
        echo '-i --tty --name dlw_mysql'>"$compCmmdContextDirName/DOCKER_CMMDLINE_OPTION"
        if ! [ -f "$compCmmdContextDirName/DOCKER_CMMDLINE_OPTION" ]; then
          ScriptError "Failed to initialize Command Context for Component: 'dlw_msql' Command: '$commandName' Content: '$compCmmdContextDirName/DOCKER_CMMDLINE_OPTION'."
          return 1
        fi
        return 0
      fi
      if [ "$commandName" != 'build' ]; then return 1; fi
      echo "dlw_mysql Initial">"$compCmmdContextDirName/ChangeVersion"
      if ! [ -f "$compCmmdContextDirName/ChangeVersion" ]; then
        ScriptError "Failed to initialize Command Context for Component: 'dlw_mysql' Command: '$commandName' Content: '$compCmmdContextDirName/ChangeVersion'."
        return 1
      fi
      cat <<DockerFile_dlw_mysql >"$compCmmdContextDirName/Dockerfile"
###############################################################################
#
# Purpose: Construct a minimal Ubuntu V12.04 image that simply includes the
# a configurable file.  This is a pseudo sshserver implementation
#
##############################################################################

FROM	   dlw_parent
MAINTAINER Richard Moyse <license@Moyse.US>

ADD ChangeVersion /root/

RUN echo "dlw_mysql">/root/ComponentName.txt

# Create an entry point to automatically run the bash shell. Permits further configuration.
ENTRYPOINT  /bin/bash
DockerFile_dlw_mysql
      if ! [ -f "$compCmmdContextDirName/Dockerfile" ]; then
        ScriptError "Failed to initialize Command Context for Component: 'dlw_mysql' Command: '$commandName' Content: '$compCmmdContextDirName/Dockerfile'."
        return 1
      fi
      ;;
    DependencySpecUpdate)
      $FUNCNAME 'ContextSupported' "$commandName"
      if [ "$?" -gt '1' ]; then return 1; fi
      if [ "$commandName" == 'build' ]; then
        # establish build dependency
        $3 'build' < <( echo 'dlw_mysql.build : dlw_parent.build' )
      fi
      ;;
    *) ScriptUnwind $LINENO "Unknown method specified: '$methodName'" ;;
  esac
  return 0
}
###############################################################################
#
#  Purpose:
#    Create a specific Component's Catalog instance containing its Command
#    Context directories and populate them with appropriate resources.  Also
#    update the Component Catalog's Dependency Specification with the appropriate
#    Component-Command level GNU makefile rules.
#    
#    A 'conversation' between a Component specific callback function populates
#    the Catalog structure created by this rouitine.
#
#  Input:
#    $1  - Directory path to Project's Component Catalog.
#    $2  - The name of a callback function providing Component specific 
#          information.
#    $3  - The name of a callback function accepting streamed input in the form
#          of makefile dependency rules from another process' SYSOUT.
#
#  Output:
#    When successful:
#      A successfull constructed Component specific Catalog entry.
#    Otherwise:
#      SYSERR - One or more messages indicating reason for failing to successfully
#               construct the Component Catalog.
#      An incomplete Component specific Catalog entry.
#
###############################################################################
function SampleProject_Component_dlw_apache  () {
  local -r methodName="$1"
  local -r commandName="$2"
  case "$methodName" in
    NameGet)
      echo "dlw_apache"
      ;;
    ContextSupported)
      local -A cmmdSupportMap
      cmmdSupportMap["attach"]="1"
      cmmdSupportMap["build"]="0"
      cmmdSupportMap["diff"]="1"
      cmmdSupportMap["images"]="1"
      cmmdSupportMap["kill"]="1"
      cmmdSupportMap["logs"]="1"
      cmmdSupportMap["pause"]="1"
      cmmdSupportMap["port"]="1"
      cmmdSupportMap["ps"]="1"
      cmmdSupportMap["restart"]="1"
      cmmdSupportMap["images"]="1"
      cmmdSupportMap["rm"]="1"
      cmmdSupportMap["rmi"]="1"
      cmmdSupportMap["create"]="1"
      cmmdSupportMap["run"]="0"
      cmmdSupportMap["start"]="1"
      cmmdSupportMap["stop"]="1"
      cmmdSupportMap["top"]="1"
      cmmdSupportMap["unpause"]="1"
      local supportLevel="${cmmdSupportMap["$commandName"]}" 
     if [ -z "$supportLevel" ]; then return 3; else return $supportLevel; fi
      ;;
    ContextCreate)
      local -r compCmmdContextDirName="$3"
      if [ "$commandName" == 'run' ]; then
        echo '-i --tty --name dlw_apache --link dlw_mysql:mysql'>"$compCmmdContextDirName/DOCKER_CMMDLINE_OPTION"
        if ! [ -f "$compCmmdContextDirName/DOCKER_CMMDLINE_OPTION" ]; then
          ScriptError "Failed to initialize Command Context for Component: 'dlw_apache' Command: '$commandName' Content: '$compCmmdContextDirName/DOCKER_CMMDLINE_OPTION'."
          return 1
        fi
        return 0
      fi
      if [ "$commandName" != 'build' ]; then return 1; fi
      echo "dlw_apache Initial">"$compCmmdContextDirName/ChangeVersion"
      if ! [ -f "$compCmmdContextDirName/ChangeVersion" ]; then
        ScriptError "Failed to initialize Command Context for Component: 'dlw_apache' Command: '$commandName' Content: '$compCmmdContextDirName/ChangeVersion'."
        return 1
      fi
      cat <<DockerFile_dlw_apache >"$compCmmdContextDirName/Dockerfile"
###############################################################################
#
# Purpose: Construct a minimal Ubuntu V12.04 image that simply includes the
# a configurable file.  This is a pseudo sshserver implementation
#
##############################################################################

FROM	   dlw_parent
MAINTAINER Richard Moyse <license@Moyse.US>

ADD ChangeVersion /root/

RUN echo "dlw_apache">/root/ComponentName.txt

# Create an entry point to automatically run the bash shell. Permits further configuration.
ENTRYPOINT  /bin/bash
DockerFile_dlw_apache
      if ! [ -f "$compCmmdContextDirName/Dockerfile" ]; then
        ScriptError "Failed to initialize Command Context for Component: 'dlw_apache' Command: '$commandName' Content: '$compCmmdContextDirName/Dockerfile'."
        return 1
      fi
      ;;
    DependencySpecUpdate)
      $FUNCNAME 'ContextSupported' "$commandName"
      if [ "$?" -gt '1' ]; then return 1; fi
      if [ "$commandName" == 'build' ]; then
        # establish build dependency
        $3 'build' < <( echo 'dlw_apache.build : dlw_parent.build' )
      elif [ "$commandName" == 'run' ]; then
        # establish run dependency
        $3 'run' < <( echo 'dlw_apache.run : dlw_mysql.run' )
      fi
      ;;
    *) ScriptUnwind $LINENO "Unknown method specified: '$methodName'" ;;
  esac
  return 0
}

###############################################################################
#
#  Purpose:
#    Output one or more tokens to SYSOUT representing ones that violated
#    the scan operator's constraint.
#
#  Input:
#    $1 - Include/Exclude operator:
#           I - All specified tokens must appear.
#           E - All specified tokens must be absent
#    $2 - name of array recording the existance/absence of a given token
#    $3 - list of N tokens provided to the scan operaton.
#    SYSIN - Stream to inspect.
#
#  Return:
#    SYSERR - Each variable responsible for the violation of scan operator.
#
###############################################################################
function TokensCausingViolation () {
  local searchOper
  if   [ "$1" == 'I' ]; then
    searchOper='!='
  elif [ "$1" == 'E' ]; then
    searchOper='=='
  else
    ScriptUnwind $LINENO "Scan operator: '$1' invalid."
  fi
  local arrayDeref
  arrayDeref=`echo \$\{#$2[\@]\}`
  local -i arraySize
  eval arraySize=$arrayDeref
  local -i iter
  for (( iter=0; iter < $arraySize; iter++ )); do
    local arrayCell
    arrayDeref=`echo \$\{\$2\[$iter\]\}`
    eval arrayCell=$arrayDeref
    if [ "$arrayCell" $searchOper 'X' ]; then
      local -i paramPos
      let paramPos=3+iter
      echo "${!paramPos}" >&2
    fi
  done
  return 0;
}
###############################################################################
#
#  Purpose:
#    Playback an in memory cache of a SYSOUT.  A bash array implements the cache.
#
#  Input:
#    $1 - Array name to contain cache.
#
#  Output:
#    SYSOUT - Reflects output generated by echoing each array element.
#
###############################################################################
function SYSOUTcachePlayback () {
  local -i lineCnt
  local -i iter
  local arrayDeref
  arrayDeref=`echo \$\{#$1[\@]\}`
  eval lineCnt=$arrayDeref
  for (( iter=0; iter < lineCnt; iter++ )); do
    arrayDeref=`echo \$\{$1[\$iter\]\}`
    eval echo "$arrayDeref"
  done
}
###############################################################################
#
#  Purpose:
#    Create an in memory cache of a SYSOUT.  A bash array implements the cache.
#
#  Assumption:
#    This function must execute within the same shell instance that declared
#    the provided array, otherwise, it cannot update this same reference 
#    with the output of SYSOUT.
#
#  Input:
#    $1 - Array name to contain cache.
#    $2 - The name of a function/command sequence generating output to SYSOUT
#
###############################################################################
function SYSOUTcacheRecord () {
  declare -i iter
  local line
  local arrayDeref
  iter=0
  while read line; do
    arrayDeref=`echo $1\[$iter\]=\'$line\'`
    eval $arrayDeref
    iter+=1;
  done < <( $2 )
  return 0;	
}
##############################################################################
#
#  Purpose:
#    Scan environment looking for remnants and possible image name clashes
#    with images stored in the local Docker Repository.
#
#  Input:
#    $1 - "All" to remo.
#
#  Return:
#    0 - Check complete - no clashes or remnants.
#    Othewise Abort because the request failed.
#
##############################################################################
function TestEnvironmentAssert () {
  local errorInd='false'
  if ! TestFileScanPass;  then errorInd='true'; fi
  if ! SampleProjectPass; then errorInd='true'; fi
  if tmux_context_set "tmux has-session" >/dev/null 2>/dev/null; then
    ScriptError "tmux sessions exists which you may want to preserve."
    errorInd='true'
  fi
  if ! ImageNameLocalOverlapPass $TEST_COMPONENT_LIST; then errorInd='true'; fi
  if $errorInd; then
    ScriptError "Determine if reported errors refer to remnants of a prior test"
    ScriptError "or indicate an overlap with pre-existing Docker repository images."
    ScriptError "If all detected artifacts are remnants, specify '--no-check' option"
    ScriptError "to ignore and destructively overwrite them."
    ScriptUnwind $LINENO "Detected remnants/potential overlap."
  fi
  return 0
}
##############################################################################
#
#  Purpose:
#    Removes any remnants from prior testing failures or end user tutorial
#    sessions applied to the sample project.
#    Remnants being:
#    1. Any temporary files generated by a prior, failed execution of
#       the test script.
#    2. Local Docker container and image objects for sample project.
#    3. Image GUID List(s),
#    4. Sample Project Component Catalog.
#    5. tmux 'sample' session.
#
#  Input:
#    $1  - Line number calling assert.
#    $2  - Keep Project level script directory:
#          'true' - keep
#          otherwise - remove it if present.
#    TEST_COMPONENT_LIST - Environment variable listing all component names
#        defined in sample project.
#    TEST_FILE_PREFIX - The shared namespace assigned to all temporary files
#        generated by this test script.
#
#  Return:
#    0 - Remnants removed or didn't exist.
#    Othewise Abort, as the request unexpectedly failed.
#
##############################################################################
function TestEnvironmentCleanAssert () {
  local -r lineNo="$1"
  local -r keepScript="$2"
  if ls ${TEST_FILE_PREFIX}* > /dev/null 2>/dev/null; then TestFileDeleteAssert $LINENO All; fi
  if ! dlw.sh rmi --dlwrm --dlwcomp-ver=all -- all > /dev/null; then
    ScriptUnwind "lineNo" "Failed to remove all project images from local Docker Repository."
  fi
  local compName
  for compName in $TEST_COMPONENT_LIST
  do
    ImageGUIDListAssert  "$LineNo" "$compName" '0'
  done
  SampleProjectObliterateAssert "$LineNo" "$keepScript"
  tmux_context_set "tmux kill-server" >/dev/null 2>/dev/null

  return 0;
}
###############################################################################
#
#  Purpose:
#    Clean and initialize the test environment.  The clean process removes
#    any Docker images and containers mentioned in the 
#
#  Input:
#    $1  - LINENO initiating assert.
#    COMPONENT_CAT_DIR - Variable set to Project's Component Catalog.
#    COMPONENT_CAT_DEPENDENCY - Variable that resolves to the Project's
#          Dependency file.
#    COMPONENT_NAME_SPACE - Variable establishing name space that prefixes
#          every function that defines a Component for the sample Project.
#    TEST_COMPONENT_LIST - Variable enumerating all Components specified
#          with in this script for the Sample Project.
#
#  Return:
#    0 -  cleaned 
#    Othewise Abort because the request failed.
#
###############################################################################
function TestEnvironmentCleanInitialize () {
  local -r lineNo="$1"
  ScriptInform "Cleaning Test Environment."       
  # clean the test environment.
  TestEnvironmentCleanAssert "$lineNo" "$keepScript"
  ScriptInform "Initializing Component Catalog."       
  # establish initial project state.
  ComponentCatalogCreateAssert "$lineNo" "$COMPONENT_CAT_DIR" "$COMPONENT_CAT_DEPENDENCY" "$COMPONENT_NAME_SPACE" $TEST_COMPONENT_LIST
}
##############################################################################
#
#  Purpose:
#    Remove a range of temporary test files.
#
#  Input:
#    $1  - LINENO of calling statement.
#    $2  - "All" to remove every file or a regex expression to delete
#                the desired one(s).
#
#  Return:
#    0 - Removed at least one file.
#    Othewise Abort because the request failed.
#
##############################################################################
function TestFileDeleteAssert (){
  local rangeDelete="$2"
  if [ "$2" == "All" ]; then rangeDelete='*'; fi
  if ! rm "${TEST_FILE_PREFIX}"${rangeDelete}; then
    ScriptUnwind "$1" "Request to delete temporary test files failed.";
    return 1
  fi
  return 0
}
##############################################################################
#
#  Purpose:
#    Remove a range of temporary test files.
#
#  Input:
#    $1 - "All" to remove every file.
#
#  Return:
#    0 - No pre-existing test files.
#    1 - One or more test files exist. 
#
##############################################################################
function TestFileScanPass () {
  if ls ${TEST_FILE_PREFIX}* > /dev/null  2>/dev/null; then
    ScriptError "Temporary test files with prefix of: '$TEST_FILE_PREFIX' already exist."
    return 1
  fi
  return 0
}
##############################################################################
#
#  Purpose:
#    Provide proper execution context to run independent (non-dlw) tmux
#    commands that can connect to the same socke as dependent tmux commands.
#
#  Input:
#    $1 - tmux command to execute.
#
##############################################################################
function tmux_context_set() {
  local TMPDIR="$TERM_MULTI_SOCKET"
  eval $1    
}
##############################################################################
##
##  Purpose:
##    Run test suite against sample target project.
##
##  Assumption:
##    Since bash variable names are passed to this routine, these names
##    cannot overlap the variable names locally declared within the
##    scope of this routine or its decendents.
##
##  Input:
##    $1 - Variable name to an array whose values contain the label names
##         of the options and agruments appearing on the command line in the
##         order specified by it.
##    $2 - Variable name to an associative array whose key is either the
##         option or argument label and whose value represents the value
##         associated to that label.
## 
##  Output:
##    When failure:
##      SYSERR - Reflects error message.
##
###############################################################################
function VirtCmmdExecute (){
  local argOptListNm="$1"
  local argOptMapNm="$2"
  export -f ContainerExist
  local -r ignoreCheck="`AssociativeMapAssignIndirect "$argOptMapNm" '--no-check'`"
  local -r ignoreClean="`AssociativeMapAssignIndirect "$argOptMapNm" '--no-clean'`"
  local -r keepScript="`AssociativeMapAssignIndirect "$argOptMapNm" '--keep-script'`"
  if ! $ignoreCheck; then
    ScriptInform "Scanning Test Environment for remnants."       
    TestEnvironmentAssert;
  fi
  local -r ignoreClean
  if ! $ignoreClean; then
    TestEnvironmentCleanInitialize $LINENO
  fi
  local -a regexList
  local -A regexExpressMap
  if ! OptionsArgsFilter "$argOptListNm" "$argOptMapNm" 'regexList' 'regexExpressMap' '[[ "$optArg" =~ Arg[0-9][0-9]* ]]' 'true'; then
    ScriptUnwind $LINENO "Unexpectd return code."
  fi
  local regexArgList="`OptionsArgsGen 'regexList' 'regexExpressMap'`"
  regexArgList=`eval echo $regexArgList`
  regexArgList="${regexArgList:2}"
  TestExecuteAssert $regexArgList
  # maintain test environment state after successfully running tests if 
  # directed to when command was initiated.
  if ! $ignoreClean; then
    TestEnvironmentCleanInitialize $LINENO
  fi   
  ScriptInform "Testing Complete & Successful!"
  return 0
}
###############################################################################
#
#  Purpose:
#   Execute the selected tests and assert successful completion.
#
#  Input:
#    $1-$N  - Regex compliant expressions identifying the test(s) to be 
#             selected (included) for execution.
#
###############################################################################
function TestExecuteAssert () {
  local -i testNumStartPos=${#TEST_NAME_SPACE}+1
  while [ "$#" -gt '0' ]; do
    local regexpress="$1"
    local testFunctionName
    while read testFunctionName; do
      $testFunctionName
      ScriptInform "Test: '$testFunctionName' Desc: `${testFunctionName}_Desc`"       
      if ! ${testFunctionName}_Run; then ScriptUnwind $LINENO "Unexpected failure detected."; fi
      ScriptInform "Test: '$testFunctionName' Successful.'"       
    done < <( TestSelectSpecificationApply "$regexpress" | sort -k1.${testNumStartPos}n )
    shift
  done
  return 0
}
###############################################################################
#
#  Depends on:
#    Initialized 'sample' project with 'dlw_sshserver' Component.
#
###############################################################################
function dlw_Test_1 () {

  function dlw_Test_1_Desc () {
    echo "Build 'dlw_sshserver' and create a container."
  }
  function dlw_Test_1_Run () {
    ImageCreate $LINENO '' 'dlw_sshserver' 1
    dlw_sshserverID_1=`DockerRepositoryImageAssign $LINENO "dlw_sshserver"`
    ReportRun $LINENO 'dlw.sh images -a --dlwcomp-ver=all -- all'
    ReportScanTokenIncludeAssert $LINENO 'COMPONENT' 'REPOSITORY' 'VIRTUAL' `ReportGUIDformat "$dlw_sshserverID_1"`
    ReportLineCntAssert $LINENO 2
    ContainerCreateAssert $LINENO 'dlw_sshserver' 1 1
    ReportRun $LINENO 'dlw.sh ps -a --dlwcomp-ver=all -- all'
    ReportScanTokenIncludeAssert $LINENO 'CONTAINER' 'IMAGE'
    ReportLineCntAssert $LINENO 2
  }
}
###############################################################################
#
#  Depends on:
#    Test 1
#
###############################################################################
function dlw_Test_2 () {
  function dlw_Test_2_Desc () { 
    echo "Remove container created in: 'dlw_Test_1' for 'dlw_sshserver'."
  }
  function dlw_Test_2_Run () {
    ContainerRemoveAssert $LINENO '--dlwcomp-ver=cur dlw_sshserver' 1 1
    TestFileDeleteAssert $LINENO All
    ImageGUIDListAssert $LINENO "dlw_sshserver" 1 
    ReportRun $LINENO 'dlw.sh ps -a --dlwcomp-ver=cur all'
    ReportLineCntAssert $LINENO 1
    ReportScanTokenIncludeAssert $LINENO 'CONTAINER' 'IMAGE'
    ReportScanTokenExcludeAssert $LINENO 'dlw_sshserver:latest'
    ReportRun $LINENO 'dlw.sh images'
    ReportLineCntAssert $LINENO 2
    ReportScanTokenIncludeAssert $LINENO 'REPOSITORY' 'VIRTUAL' "`ReportGUIDformat "$dlw_sshserverID_1"`"
  }
}
###############################################################################
#
#  Depends on:
#    Test 2
#
###############################################################################
function dlw_Test_3 () {
  function dlw_Test_3_Desc () { 
    echo "Remove the only image version of: 'dlw_sshserver'."
  }
  function dlw_Test_3_Run () {
    DockerRepositoryImageExistsAssert $LINENO "$dlw_sshserverID_1"
    ImageContainerRemove $LINENO '--dlwcomp-ver=cur -- dlw_sshserver'
    ImageGUIDListAssert $LINENO "dlw_sshserver" 0
    DockerRepositoryImageDeleteAssert $LINENO "$dlw_sshserverID_1"
    ReportRun $LINENO 'dlw.sh ps -a --dlwcomp-ver=all -- all'
    ReportLineCntAssert $LINENO 1
  }
}
###############################################################################
#
#  Depends on:
#    Initialized 'sample' project with 'dlw_sshserver' Component.
#
###############################################################################
function dlw_Test_4 () {
  function dlw_Test_4_Desc () { 
    echo "Create two versions of: 'dlw_sshserver' and two containers for each version."
  }
  function dlw_Test_4_Run () {
    ImageCreate $LINENO '' 'dlw_sshserver' 1
    dlw_sshserverID_1="`DockerRepositoryImageAssign $LINENO 'dlw_sshserver'`"
    ContainerCreateAssert $LINENO 'dlw_sshserver' 2 1
    ImageChangeVersion 'dlw_sshserver'
    ImageCreate $LINENO '' 'dlw_sshserver' 2
    dlw_sshserverID_2="`DockerRepositoryImageAssign $LINENO 'dlw_sshserver'`"
    ContainerCreateAssert $LINENO 'dlw_sshserver' 2 3
    ReportRun $LINENO 'dlw.sh ps -a --dlwcomp-ver=all -- all'
    ReportLineCntAssert $LINENO 5
    ReportScanTokenIncludeAssert $LINENO 'CONTAINER' 'IMAGE' 'dlw_sshserver:latest'
    ReportRun $LINENO 'dlw.sh ps -a --dlwcomp-ver=allButCur -- all'
    ReportLineCntAssert $LINENO 3
    ReportScanTokenIncludeAssert $LINENO 'CONTAINER' 'IMAGE'
    ReportScanTokenExcludeAssert $LINENO 'dlw_sshserver:latest'
    ReportRun $LINENO 'dlw.sh images --dlwcomp-ver=all -- all'
    ReportLineCntAssert $LINENO 3
    ReportScanTokenIncludeAssert $LINENO 'REPOSITORY' 'VIRTUAL' "`ReportGUIDformat "$dlw_sshserverID_1"`" "`ReportGUIDformat "$dlw_sshserverID_2"`"
    ReportRun $LINENO 'dlw.sh images --dlwcomp-ver=cur -- dlw_sshserver'
    ReportLineCntAssert $LINENO 2
    ReportScanTokenIncludeAssert $LINENO 'REPOSITORY' 'VIRTUAL' "`ReportGUIDformat "$dlw_sshserverID_2"`"
    ReportScanTokenExcludeAssert $LINENO "`ReportGUIDformat "$dlw_sshserverID_1"`"
  }
}
###############################################################################
#
#  Depends on:
#    Test 4
#
###############################################################################
function dlw_Test_5 () {
  function dlw_Test_5_Desc () { 
    echo "Delete the two containers associated to the oldest image versions of: 'dlw_sshserver.' of test: 'dlw_Test_4'."
  }
  function dlw_Test_5_Run () {
    ContainerRemoveAssert $LINENO '--dlwcomp-ver=allButCur -- dlw_sshserver' 2 1
    DockerRepositoryImageExistsAssert $LINENO "$dlw_sshserverID_1"
    DockerRepositoryImageExistsAssert $LINENO "$dlw_sshserverID_2"
    ImageGUIDListAssert $LINENO "dlw_sshserver" 2
    ContainerExistAssert $LINENO 2 3
  }
}
###############################################################################
#
#  Depends on:
#    Test 5
#
###############################################################################
function dlw_Test_6 () {
  function dlw_Test_6_Desc () { 
    echo "Delete the oldest image version of: 'dlw_sshserver' but keep most recent image and its containers of test: 'dlw_Test_5'."
  }
  function dlw_Test_6_Run () {
    ImageRemoveAssert $LINENO '--dlwcomp-ver=allButCur -- dlw_sshserver'
    ImageGUIDListAssert $LINENO "dlw_sshserver" 1
    DockerRepositoryImageDeleteAssert $LINENO "$dlw_sshserverID_1"
    ContainerExistAssert $LINENO 2 3
    ReportRun $LINENO 'dlw.sh ps -aq --dlwcomp-ver=all --dlwno-hdr -- all'
    ReportLineCntAssert $LINENO 2
    ReportScanTokenExcludeAssert $LINENO 'CONTAINER' 'COMPONENT' 'IMAGE' 'dlw_sshserver:latest'
  }
}
###############################################################################
#
#  Depends on:
#    Test 6
#
###############################################################################
function dlw_Test_7 () {
  function dlw_Test_7_Desc () {
    echo "Delete the current version of: 'dlw_sshserver' and its containers of test: 'dlw_Test_6'."
  }
  function dlw_Test_7_Run () {
    ImageContainerRemove $LINENO '--dlwcomp-ver=cur -- dlw_sshserver'
    DockerRepositoryImageDeleteAssert $LINENO "$dlw_sshserverID_2"
    ImageGUIDListAssert $LINENO "dlw_sshserver" 0
    ContainerDeleteAssert $LINENO 2 3
    TestFileDeleteAssert $LINENO All
    ReportRun $LINENO 'dlw.sh ps -a --dlwcomp-ver=all all'
    ReportLineCntAssert $LINENO 1
    ReportScanTokenIncludeAssert $LINENO 'CONTAINER' 'COMPONENT' 'IMAGE'
    ReportRun $LINENO 'dlw.sh images -a --dlwcomp-ver=all all'
    ReportLineCntAssert $LINENO 1
    ReportScanTokenIncludeAssert $LINENO 'REPOSITORY' 'COMPONENT' 'TAG'
  }
}
###############################################################################
#
#  Depends on:
#    Initialized 'sample' project with 'dlw_sshserver' Component.
#
###############################################################################
function dlw_Test_8 () {
  function dlw_Test_8_Desc () {
    echo "Create two versions of: 'dlw_sshserver' and two containers for each version. Then completely delete all image versions and associated containers."
  }
  function dlw_Test_8_Run () {
    ImageCreate $LINENO '' "dlw_sshserver" 1
    dlw_sshserverID_1=`DockerRepositoryImageAssign $LINENO "dlw_sshserver"`
    ContainerCreateAssert $LINENO 'dlw_sshserver' 2 1
    ImageChangeVersion "dlw_sshserver"
    ImageCreate $LINENO '' "dlw_sshserver" 2
    dlw_sshserverID_2=`DockerRepositoryImageAssign $LINENO "dlw_sshserver"`
    ContainerCreateAssert $LINENO 'dlw_sshserver' 2 3
    ImageContainerRemove $LINENO '--dlwcomp-ver=all -- dlw_sshserver'
    DockerRepositoryImageDeleteAssert $LINENO "$dlw_sshserverID_1" "$dlw_sshserverID_2"
    ImageGUIDListAssert $LINENO "dlw_sshserver" 0
    ContainerDeleteAssert $LINENO 4 1
    TestFileDeleteAssert $LINENO All
  }
}
###############################################################################
#
#  Depends on:
#    Initialized 'sample' project with 'dlw_mysql' and 'dlw_parent' Components.
#
###############################################################################
function dlw_Test_9 () {
  function dlw_Test_9_Desc () {
    echo "Create derived image: 'dlw_mysql' that relies on: 'dlw_parent'. Then delete each image in turn."
  }
  function dlw_Test_9_Run () {
    ImageCreate $LINENO '' "dlw_mysql" 1
    local dlw_mysqlID_1="`DockerRepositoryImageAssign $LINENO "dlw_mysql"`"
    local dlw_parentID_1="`DockerRepositoryImageAssign $LINENO "dlw_parent"`"
    ImageGUIDListAssert $LINENO "dlw_mysql" 1
    ImageGUIDListAssert $LINENO "dlw_parent" 1
    ReportRun $LINENO 'dlw.sh ps -a --dlwcomp-ver=all -- dlw_mysql'
    ReportLineCntAssert $LINENO 1
    ReportScanTokenIncludeAssert $LINENO 'CONTAINER' 'IMAGE'
    ReportRun $LINENO 'dlw.sh images --dlwcomp-ver=all -- all'
    ReportLineCntAssert $LINENO 3
    ReportScanTokenIncludeAssert $LINENO 'REPOSITORY' 'VIRTUAL' "`ReportGUIDformat "$dlw_parentID_1"`" "`ReportGUIDformat "$dlw_mysqlID_1"`"
    ReportRun $LINENO 'dlw.sh images --dlwcomp-ver=all -- dlw_mysql'
    ReportLineCntAssert $LINENO 2
    ReportScanTokenIncludeAssert $LINENO 'REPOSITORY' 'VIRTUAL' "`ReportGUIDformat "$dlw_mysqlID_1"`"
    ReportScanTokenExcludeAssert $LINENO "`ReportGUIDformat "$dlw_parentID_1"`"
    if ! dlw.sh rmi --dlwcomp-ver=all -- dlw_mysql dlw_parent >/dev/null 2>/dev/null;
      then ScriptUnwind $LINENO "Remove failed for: 'dlw_mysql dlw_parent'"; fi
    DockerRepositoryImageDeleteAssert $LINENO "$dlw_mysqlID_1" "$dlw_parentID_1"
    ImageGUIDListAssert $LINENO "dlw_mysql" 0
    ImageGUIDListAssert $LINENO "dlw_parent" 0
  }
}
###############################################################################
#
#  Depends on:
#    Initialized 'sample' project with 'dlw_apache', 'dlw_mysql' 
#    and 'dlw_parent' Components.
#
###############################################################################
function dlw_Test_10 () {
  function dlw_Test_10_Desc () {
    echo "Execute default 'build all' request to construct: 'dlw_sshserver', 'dlw_parent', 'dlw_mysql', and 'dlw_apache'. Then Remove all images."
  }
  function dlw_Test_10_Run () {
    if ! dlw.sh build >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Build all failed."; fi
    local dlw_apacheID_1=`DockerRepositoryImageAssign $LINENO 'dlw_apache'`
    local dlw_mysqlID_1=`DockerRepositoryImageAssign $LINENO 'dlw_mysql'`
    local dlw_sshserverID_1=`DockerRepositoryImageAssign $LINENO 'dlw_sshserver'`
    local dlw_parentID_1=`DockerRepositoryImageAssign $LINENO 'dlw_parent'`
    ImageGUIDListAssert $LINENO 'dlw_apache' 1
    ImageGUIDListAssert $LINENO 'dlw_mysql' 1
    ImageGUIDListAssert $LINENO 'dlw_sshserver' 1
    ImageGUIDListAssert $LINENO 'dlw_parent' 1
    ImageRemoveAssert $LINENO '--dlwcomp-ver=cur -- all'
    DockerRepositoryImageDeleteAssert $LINENO "$dlw_apacheID_1" "$dlw_mysqlID_1" "$dlw_sshserverID_1" "$dlw_sshserverID_1"
    ImageGUIDListAssert $LINENO 'dlw_mysql' 0
    ImageGUIDListAssert $LINENO 'dlw_sshserver' 0
    ImageGUIDListAssert $LINENO 'dlw_parent' 0
  }
}
###############################################################################
#
#  Depends on:
#    Initialized 'sample' project with 'dlw_apache', 'dlw_mysql' 
#    and 'dlw_parent' Components.
#
###############################################################################
function dlw_Test_11 () {
  function dlw_Test_11_Desc () {
    echo "Build dlw_mysql & dlw_appache, run them as linked containers, stop each one individually, then delete the containers, preserving the images."
  }
  function dlw_Test_11_Run () {
    ImageCreate $LINENO '' 'dlw_mysql' 1
    local dlw_mysqlID_1=`DockerRepositoryImageAssign $LINENO 'dlw_mysql'`
    dlw_parentID_1=`DockerRepositoryImageAssign $LINENO 'dlw_parent'`
    ImageGUIDListAssert $LINENO 'dlw_parent' 1
    ImageCreate $LINENO '' 'dlw_apache' 1
    ImageGUIDListAssert $LINENO "dlw_sshserver" 0
    local dlw_apacheID_1=`DockerRepositoryImageAssign $LINENO 'dlw_apache'`
    if ! dlw.sh run -d -- dlw_apache >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Run of: 'dlw_apache' failed."; fi
    ImageGUIDListAssert $LINENO 'dlw_parent' 1
    ReportRun $LINENO 'dlw.sh ps --dlwcomp-ver=cur -- dlw_mysql dlw_apache'
    ReportLineCntAssert $LINENO 3
    ReportScanTokenIncludeAssert $LINENO 'CONTAINER' 'IMAGE' 'dlw_mysql' 'dlw_apache'
    if ! dlw.sh stop --dlwcomp-ver=cur -- dlw_apache >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Stop of: 'dlw_apache' failed."; fi
    ReportRun $LINENO 'dlw.sh ps'
    ReportLineCntAssert $LINENO 2
    if ! dlw.sh stop dlw_mysql >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Stop of: 'dlw_mysql' failed."; fi
    ReportRun $LINENO 'dlw.sh ps'
    ReportLineCntAssert $LINENO 1
    if ! dlw.sh rm --dlwcomp-ver=cur -- dlw_mysql dlw_apache >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "remove of: 'dlw_mysql' and 'dlw_apache' failed."; fi
  }
}
###############################################################################
#
#  Depends on:
#    Test 11
#
###############################################################################
function dlw_Test_12 () {
  function dlw_Test_12_Desc () {
    echo "Ensure the implicit removal of a dangling: 'dlw_parent' image, buy Docker, is properly removed from the Image GUID list when its child images: 'dlw_mysql' and 'dlw_apache' are removed."
  }
  function dlw_Test_12_Run () {
    ImageChangeVersion 'dlw_parent'
    ImageCreate $LINENO '' 'dlw_mysql' 2
    ImageCreate $LINENO '' 'dlw_apache' 2
    ImageGUIDListAssert $LINENO 'dlw_parent' 2
    local dlw_parentID_2=`DockerRepositoryImageAssign $LINENO 'dlw_parent'`
    ReportRun $LINENO 'dlw.sh images -a --dlwcomp-ver=all -- dlw_parent'
    ReportLineCntAssert $LINENO 3
    ReportScanTokenIncludeAssert $LINENO 'REPOSITORY' 'VIRTUAL' "`ReportGUIDformat "$dlw_parentID_1"`" "`ReportGUIDformat "$dlw_parentID_2"`"
    ImageRemoveAssert $LINENO '--dlwcomp-ver=allButCur -- dlw_mysql dlw_apache'
    ReportRun $LINENO 'dlw.sh images -a --dlwcomp-ver=all -- dlw_parent'
    ReportLineCntAssert $LINENO 2
    ReportScanTokenIncludeAssert $LINENO 'REPOSITORY' 'VIRTUAL' "`ReportGUIDformat "$dlw_parentID_2"`"
    ReportScanTokenExcludeAssert $LINENO "`ReportGUIDformat "$dlw_parentID_1"`"
    ImageGUIDListAssert $LINENO 'dlw_parent' 1
    ImageGUIDListAssert $LINENO 'dlw_mysql' 1
    ImageGUIDListAssert $LINENO 'dlw_apache' 1
  }
}
###############################################################################
#
#  Depends on:
#    Test 12
#
###############################################################################
function dlw_Test_13 () {
  function dlw_Test_13_Desc () {
    echo "Run current versions of: 'dlw_sshserver', 'dlw_mysql', and 'dlw_apache'. Execute restart for all. Stop all"
  }
  function dlw_Test_13_Run () {
    ImageCreate $LINENO '' 'dlw_sshserver' 1    
    ReportRun $LINENO 'dlw.sh images -a --dlwcomp-ver=all'
    ReportLineCntAssert $LINENO 5
    if ! dlw.sh run -i -d >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Run of: 'all' failed."; fi
    ReportRun $LINENO 'dlw.sh ps --dlwcomp-ver=cur'
    ReportLineCntAssert $LINENO 4
    ReportScanTokenIncludeAssert $LINENO 'CONTAINER' 'IMAGE' 'dlw_sshserver' 'dlw_apache' 'dlw_mysql'
    ReportScanTokenExcludeAssert $LINENO 'dlw_parent'
    if ! dlw.sh restart all >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Restart of: 'all' failed."; fi
    ReportRun $LINENO 'dlw.sh ps --dlwcomp-ver=cur'
    ReportLineCntAssert $LINENO 4
    ReportScanTokenIncludeAssert $LINENO 'CONTAINER' 'IMAGE' 'dlw_sshserver' 'dlw_apache' 'dlw_mysql'
    ReportScanTokenExcludeAssert $LINENO 'dlw_parent'
    if ! dlw.sh stop all >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Stop of: 'all' failed."; fi
    ReportRun $LINENO 'dlw.sh ps'
    ReportLineCntAssert $LINENO 1
  }
}
###############################################################################
#
#  Depends on:
#    Test 12
#
###############################################################################
function dlw_Test_13 () {
  function dlw_Test_13_Desc () {
    echo "Run current versions of: 'dlw_sshserver', 'dlw_mysql', and 'dlw_apache'. Execute restart for all. Stop all"
  }
  function dlw_Test_13_Run () {
    ImageCreate $LINENO '' 'dlw_sshserver' 1    
    ReportRun $LINENO 'dlw.sh images -a --dlwcomp-ver=all'
    ReportLineCntAssert $LINENO 5
    if ! dlw.sh run -i -d >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Run of: 'all' failed."; fi
    ReportRun $LINENO 'dlw.sh ps --dlwcomp-ver=cur'
    ReportLineCntAssert $LINENO 4
    ReportScanTokenIncludeAssert $LINENO 'CONTAINER' 'IMAGE' 'dlw_sshserver' 'dlw_apache' 'dlw_mysql'
    ReportScanTokenExcludeAssert $LINENO 'dlw_parent'
    if ! dlw.sh restart all >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Restart of: 'all' failed."; fi
    ReportRun $LINENO 'dlw.sh ps --dlwcomp-ver=cur'
    ReportLineCntAssert $LINENO 4
    ReportScanTokenIncludeAssert $LINENO 'CONTAINER' 'IMAGE' 'dlw_sshserver' 'dlw_apache' 'dlw_mysql'
    ReportScanTokenExcludeAssert $LINENO 'dlw_parent'
    if ! dlw.sh stop all >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Stop of: 'all' failed."; fi
    ReportRun $LINENO 'dlw.sh ps'
    ReportLineCntAssert $LINENO 1
  }
}
###############################################################################
#
#  Depends on:
#    Initialized 'sample' project with 'dlw_apache', 'dlw_mysql' 
#    and 'dlw_parent' Components.
#
###############################################################################
function dlw_Test_14 () {
  function dlw_Test_14_Desc () {
    echo "Run current versions of: 'dlw_sshserver', 'dlw_mysql', and 'dlw_apache'. Execute pause for all, unpause all, then stop"
  }
  function dlw_Test_14_Run () {
    ImageContainerRemove $LINENO '--dlwcomp-ver=all -- all'
    ReportRun $LINENO 'dlw.sh ps'
    ReportLineCntAssert $LINENO 1
    ReportRun $LINENO 'dlw.sh images'
    ReportLineCntAssert $LINENO 1
    ImageCreate $LINENO '' 'dlw_mysql' 1
    ImageCreate $LINENO '' 'dlw_apache' 1
    ImageCreate $LINENO '' 'dlw_sshserver' 1
    ReportRun $LINENO 'dlw.sh images -a --dlwcomp-ver=all'
    ReportLineCntAssert $LINENO 5
    if ! dlw.sh run -i -d >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Run of: 'all' failed."; fi
    ReportRun $LINENO 'dlw.sh ps --dlwcomp-ver=cur'
    ReportLineCntAssert $LINENO 4
    ReportScanTokenIncludeAssert $LINENO 'CONTAINER' 'IMAGE' 'dlw_sshserver' 'dlw_apache' 'dlw_mysql'
    ReportScanTokenExcludeAssert $LINENO 'dlw_parent'
    if ! dlw.sh pause all >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Pause of: 'all' failed."; fi
    ReportRun $LINENO 'dlw.sh ps --dlwcomp-ver=cur'
    ReportLineCntAssert $LINENO 4
    ReportScanTokenIncludeAssert $LINENO 'CONTAINER' 'IMAGE' 'dlw_sshserver' 'dlw_apache' 'dlw_mysql' '(Paused)'
    ReportScanTokenExcludeAssert $LINENO 'dlw_parent'
    if ! dlw.sh unpause all >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Pause of: 'all' failed."; fi
    ReportRun $LINENO 'dlw.sh ps'
    ReportLineCntAssert $LINENO 4
    ReportScanTokenIncludeAssert $LINENO 'CONTAINER' 'IMAGE' 'dlw_sshserver' 'dlw_apache' 'dlw_mysql'
    ReportScanTokenExcludeAssert $LINENO '(Paused)'
    if ! dlw.sh stop all >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Stop of: 'all' failed."; fi
    ReportRun $LINENO 'dlw.sh ps'
    ReportLineCntAssert $LINENO 1
  }
}
###############################################################################
#
#  Depends on:
#    Initialized 'sample' project with 'dlw_apache', 'dlw_mysql' 
#    and 'dlw_parent' Components.
#
###############################################################################
function dlw_Test_15 () {
  function dlw_Test_15_Desc () {
    echo "Run current versions of: 'dlw_sshserver', 'dlw_mysql', and 'dlw_apache'. Execute top for all, execute top for only sshserver and remove COMPONENT & CONTAINER ID columns."
  }
  function dlw_Test_15_Run () {
    ImageContainerRemove $LINENO '--dlwcomp-ver=all -- all'
    ReportRun $LINENO 'dlw.sh ps'
    ReportLineCntAssert $LINENO 1
    ReportRun $LINENO 'dlw.sh images'
    ReportLineCntAssert $LINENO 1
    ImageCreate $LINENO '' 'dlw_mysql' 1
    ImageCreate $LINENO '' 'dlw_apache' 1
    ImageCreate $LINENO '' 'dlw_sshserver' 1
    ReportRun $LINENO 'dlw.sh images -a --dlwcomp-ver=all'
    ReportLineCntAssert $LINENO 5
    if ! dlw.sh run -i -d >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Run of: 'all' failed."; fi
    ReportRun $LINENO 'dlw.sh ps --dlwcomp-ver=cur'
    ReportLineCntAssert $LINENO 4
    ReportScanTokenIncludeAssert $LINENO 'CONTAINER' 'IMAGE' 'dlw_sshserver' 'dlw_apache' 'dlw_mysql'
    ReportScanTokenExcludeAssert $LINENO 'dlw_parent'
    ReportRun $LINENO 'dlw.sh top'
    ReportLineCntAssert $LINENO 7
    ReportScanTokenIncludeAssert $LINENO 'COMPONENT' 'CONTAINER ID' 'PID' 'PPID' 'dlw_sshserver' 'dlw_apache' 'dlw_sshserver'
    ReportScanTokenExcludeAssert $LINENO 'dlw_parent'
    ReportRun $LINENO 'dlw.sh top --dlwcol=ComponentName/COMPONENT -- dlw_sshserver'
    ReportLineCntAssert $LINENO 3
    ReportScanTokenIncludeAssert $LINENO 'COMPONENT' 'PID' 'PPID' 'dlw_sshserver'
    ReportScanTokenExcludeAssert $LINENO 'CONTAINER ID' 'dlw_parent' 'dlw_apache'
    ReportRun $LINENO 'dlw.sh top --dlwno-prereq false dlw_apache'
    ReportLineCntAssert $LINENO 5
    ReportScanTokenIncludeAssert $LINENO 'COMPONENT' 'CONTAINER ID' 'PID' 'PPID' 'dlw_apache' 'dlw_mysql'
    ReportScanTokenExcludeAssert $LINENO  'dlw_parent' 'dlw_sshserver' 
    if ! dlw.sh kill all >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Kill of: 'all' failed."; fi
    ReportRun $LINENO 'dlw.sh ps'
    ReportLineCntAssert $LINENO 1
  }
}
###############################################################################
#
#  Depends on:
#    Initialized 'sample' project with 'dlw_apache', 'dlw_mysql' 
#    and 'dlw_parent' Components.
#
###############################################################################
function dlw_Test_16 () {
  function dlw_Test_16_Desc () {
    echo "Run current versions of: 'dlw_sshserver', 'dlw_mysql', and 'dlw_apache'. Expose port 3030 for all."
  }
  function dlw_Test_16_Run () {
    ImageContainerRemove $LINENO '--dlwcomp-ver=all -- all'
    ReportRun $LINENO 'dlw.sh ps'
    ReportLineCntAssert $LINENO 1
    ReportRun $LINENO 'dlw.sh images'
    ReportLineCntAssert $LINENO 1
    ImageCreate $LINENO '' 'dlw_mysql' 1
    ImageCreate $LINENO '' 'dlw_apache' 1
    ImageCreate $LINENO '' 'dlw_sshserver' 1
    ReportRun $LINENO 'dlw.sh images -a --dlwcomp-ver=all'
    ReportLineCntAssert $LINENO 5
    if ! dlw.sh run -i -d >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Run of: 'all' failed."; fi
    ReportRun $LINENO 'dlw.sh ps --dlwcomp-ver=cur'
    ReportLineCntAssert $LINENO 4
    ReportScanTokenIncludeAssert $LINENO 'CONTAINER' 'IMAGE' 'dlw_sshserver' 'dlw_apache' 'dlw_mysql'
    ReportScanTokenExcludeAssert $LINENO 'dlw_parent'
    ReportRun $LINENO 'dlw.sh port'
    # since no ports were open don't expect any report lines.
    ReportLineCntAssert $LINENO 0
    if ! dlw.sh rm -f --dlwcomp-ver=cur -- all >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Remove all containers failed."; fi
    # Expose and open port 3030 for all components.
    if ! dlw.sh run -i -d --expose 3030 -p 3030 >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Run exposing port 3030 failed."; fi
    ReportRun $LINENO 'dlw.sh port'
    ReportLineCntAssert $LINENO 4
    ReportScanTokenIncludeAssert $LINENO 'COMPONENT' 'CONTAINER ID' 'PORT' 'MAP' '3030' 'dlw_apache' 'dlw_mysql' 'dlw_sshserver'
    ReportScanTokenExcludeAssert $LINENO 'dlw_parent'
    ReportRun $LINENO 'dlw.sh port dlw_apache'
    ReportLineCntAssert $LINENO 2
    ReportScanTokenIncludeAssert $LINENO 'COMPONENT' 'CONTAINER ID' 'PORT' 'MAP' '3030' 'dlw_apache' 
    ReportScanTokenExcludeAssert $LINENO 'dlw_parent' 'dlw_mysql' 'dlw_sshserver'
    ReportRun $LINENO 'dlw.sh port --dlwno-prereq=false dlw_apache'
    ReportLineCntAssert $LINENO 3
    ReportScanTokenIncludeAssert $LINENO 'COMPONENT' 'CONTAINER ID' 'PORT' 'MAP' '3030' 'dlw_mysql' 'dlw_apache' 
    ReportScanTokenExcludeAssert $LINENO 'dlw_parent' 'dlw_sshserver'
    ReportRun $LINENO 'dlw.sh port  --dlwno-hdr --dlwno-prereq=false dlw_apache'
    ReportLineCntAssert $LINENO 2
    ReportScanTokenIncludeAssert $LINENO 'dlw_mysql' 'dlw_apache' 
    ReportScanTokenExcludeAssert $LINENO 'COMPONENT' 'CONTAINER ID' 'dlw_parent' 'dlw_sshserver'
    ReportRun $LINENO 'dlw.sh port  --dlwcol=none --dlwno-hdr --dlwno-prereq=false dlw_apache'
    ReportLineCntAssert $LINENO 2
    ReportScanTokenIncludeAssert $LINENO '3030' 
    ReportScanTokenExcludeAssert $LINENO 'dlw_parent' 'dlw_sshserver' 'dlw_mysql' 'dlw_apache'
  }
}
###############################################################################
#
#  Depends on:
#    Initialized 'sample' project with 'dlw_apache', 'dlw_mysql' 
#    and 'dlw_parent' Components.
#
###############################################################################
function dlw_Test_17 () {
  function dlw_Test_17_Desc () {
    echo "Run current versions of: 'dlw_sshserver', 'dlw_mysql', and 'dlw_apache'. Generate Docker attach commands for all. Create tmux session.  Eliminate containers closing their tmux windows."
  }
  function dlw_Test_17_Run () {
    ImageContainerRemove $LINENO '--dlwcomp-ver=all -- all'
    ReportRun $LINENO 'dlw.sh ps'
    ReportLineCntAssert $LINENO 1
    ReportRun $LINENO 'dlw.sh images'
    ReportLineCntAssert $LINENO 1
    ImageCreate $LINENO '' 'dlw_mysql' 1
    ImageCreate $LINENO '' 'dlw_apache' 1
    ImageCreate $LINENO '' 'dlw_sshserver' 1
    ReportRun $LINENO 'dlw.sh images -a --dlwcomp-ver=all'
    ReportLineCntAssert $LINENO 5
    if ! dlw.sh run -i -d >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Run of: 'all' failed."; fi
    # Expect 3 'Docker attach' commands.
    ReportRun $LINENO 'dlw.sh attach'
    ReportLineCntAssert $LINENO 3
    ReportScanTokenIncludeAssert $LINENO 'docker' 'attach' 
    if ! dlw.sh tmux ; then ScriptUnwind $LINENO "tmux terminal multiplexer failed."; fi
    tmux_context_set "ReportRun $LINENO 'tmux ls'"
    ReportLineCntAssert $LINENO 1
    ReportScanTokenIncludeAssert $LINENO 'sample: 4 windows (created'
    if ! dlw.sh rm -f --dlwcomp-ver=all all >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Remove all containers failed."; fi
    ReportRun $LINENO 'dlw.sh ps'
    ReportLineCntAssert $LINENO 1
    tmux_context_set "ReportRun $LINENO 'tmux ls'"
    ReportLineCntAssert $LINENO 1
    ReportScanTokenIncludeAssert $LINENO 'sample: 1 windows (created'
    if ! tmux_context_set "tmux kill-session -t sample"; then ScriptUnwind $LINENO "tmux kill session failed."; fi
  }
}
###############################################################################
#
#  Depends on:
#    Initialized 'sample' project with 'dlw_apache', 'dlw_mysql' 
#    and 'dlw_parent' Components.
#
###############################################################################
function dlw_Test_18 () {
  function dlw_Test_18_Desc () {
    echo "Run current versions of: 'dlw_sshserver', 'dlw_mysql', and 'dlw_apache'. Generate dlw logs commands for all and corresponding tmux session.  Eliminate containers which inturn closes their logs and tmux windows."
  }
  function dlw_Test_18_Run () {
    ImageContainerRemove $LINENO '--dlwcomp-ver=all -- all'
    ReportRun $LINENO 'dlw.sh ps'
    ReportLineCntAssert $LINENO 1
    ReportRun $LINENO 'dlw.sh images'
    ReportLineCntAssert $LINENO 1
    ImageCreate $LINENO '' 'dlw_mysql' 1
    ImageCreate $LINENO '' 'dlw_apache' 1
    ImageCreate $LINENO '' 'dlw_sshserver' 1
    ReportRun $LINENO 'dlw.sh images -a --dlwcomp-ver=all'
    ReportLineCntAssert $LINENO 5
    if ! dlw.sh run -i -d >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Run of: 'all' failed."; fi
    # Expect 3 'docker logs' commands.
    ReportRun $LINENO 'dlw.sh logs'
    ReportLineCntAssert $LINENO 3
    ReportScanTokenIncludeAssert $LINENO 'docker' 'logs' 
    if ! dlw.sh tmux ; then ScriptUnwind $LINENO "tmux terminal multiplexer failed."; fi
    if ! dlw.sh tmux --dlwc 'logs -f'; then ScriptUnwind $LINENO "tmux terminal multiplexer for logs failed."; fi
    tmux_context_set "ReportRun $LINENO 'tmux ls'"
    ReportLineCntAssert $LINENO 1
    ReportScanTokenIncludeAssert $LINENO 'sample: 7 windows (created'
    if ! dlw.sh rm -f --dlwcomp-ver=cur all >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Remove all containers failed."; fi
    ReportRun $LINENO 'dlw.sh ps'
    ReportLineCntAssert $LINENO 1
    tmux_context_set "ReportRun $LINENO 'tmux ls'"
    ReportLineCntAssert $LINENO 1
    ReportScanTokenIncludeAssert $LINENO 'sample: 1 windows (created'
    if ! tmux_context_set "tmux kill-session -t sample"; then ScriptUnwind $LINENO "tmux kill session failed."; fi
  }
}
###############################################################################
#
#  Depends on:
#    Initialized 'sample' project with 'dlw_apache', 'dlw_mysql' 
#    and 'dlw_parent' Components.
#
###############################################################################
function dlw_Test_19 () {
  function dlw_Test_19_Desc () {
    echo "Create and start current versions of: 'dlw_sshserver', 'dlw_mysql', and 'dlw_apache'."
  }
  function dlw_Test_19_Run () {
    ImageContainerRemove $LINENO '--dlwcomp-ver=all -- all'
    ReportRun $LINENO 'dlw.sh ps'
    ReportLineCntAssert $LINENO 1
    ReportRun $LINENO 'dlw.sh images'
    ReportLineCntAssert $LINENO 1
    if ! dlw.sh build >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "dlw build of Component: 'all' failed."; fi
    ReportRun $LINENO 'dlw.sh images --dlwcomp-ver=all'
    ReportScanTokenIncludeAssert $LINENO 'REPOSITORY' 'TAG' 'dlw_sshserver' 'dlw_apache' 'dlw_mysql' 'dlw_parent'
    ReportLineCntAssert $LINENO 5
    if ! dlw.sh create -i >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "dlw create of Component: 'all' failed."; fi
    ReportRun $LINENO 'dlw.sh ps -a --dlwcomp-ver=all'
    ReportLineCntAssert $LINENO 4
    ReportScanTokenIncludeAssert $LINENO 'CONTAINER' 'IMAGE' 'dlw_sshserver' 'dlw_apache' 'dlw_mysql'
    ReportScanTokenExcludeAssert $LINENO 'dlw_parent'
    #TODO: when docker fixes bug #8796 enable this portion of the test.
    #if ! dlw.sh start >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Start of: 'all' failed."; fi
    #ReportRun $LINENO 'dlw.sh ps'
    #ReportLineCntAssert $LINENO 4
    #ReportScanTokenIncludeAssert $LINENO 'CONTAINER' 'IMAGE' 'dlw_sshserver' 'dlw_apache' 'dlw_mysql'
    #ReportScanTokenExcludeAssert $LINENO 'dlw_parent'
    if ! dlw.sh rm -f --dlwcomp-ver=cur all >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "Remove all containers failed."; fi
    ReportRun $LINENO 'dlw.sh ps'
    ReportLineCntAssert $LINENO 1
  }
}
###############################################################################
#
#  Depends on:
#    Initialized 'sample' project with 'dlw_apache', 'dlw_mysql' 
#    and 'dlw_parent' Components.
#
###############################################################################
function dlw_Test_20 () {
  function dlw_Test_20_Desc () {
    echo "Create current versions of: 'dlw_sshserver', 'dlw_mysql', and 'dlw_apache'. Verify behavior of: --no-trunc, -q, --dlwcol=none, and --dlwparent."
  }
  function dlw_Test_20_Run () {
    ImageContainerRemove $LINENO '--dlwcomp-ver=all -- all'
    ReportRun $LINENO 'dlw.sh ps'
    ReportLineCntAssert $LINENO 1
    ReportRun $LINENO 'dlw.sh images'
    ReportLineCntAssert $LINENO 1
    if ! dlw.sh build >/dev/null 2>/dev/null; then ScriptUnwind $LINENO "dlw build of Component: 'all' failed."; fi
    ReportRun $LINENO 'dlw.sh images --dlwcomp-ver=all'
    ReportLineCntAssert $LINENO 5
    ReportScanTokenIncludeAssert $LINENO 'REPOSITORY' 'TAG' 'dlw_sshserver' 'dlw_apache' 'dlw_mysql' 'dlw_parent'
    ReportRun $LINENO 'dlw.sh images -q --no-trunc --dlwcol=none'
    ReportLineCntAssert $LINENO 4
    ReportScanTokenExcludeAssert $LINENO 'REPOSITORY' 'TAG' 'COMPONENT' 'DESCRIPTION'
    ReportRun $LINENO 'dlw.sh images --dlwparent -- dlw_apache'
    ReportLineCntAssert $LINENO 3
    ReportScanTokenIncludeAssert $LINENO 'REPOSITORY' 'TAG' 'dlw_parent' 'dlw_apache'
    ReportScanTokenExcludeAssert $LINENO  'dlw_sshserver' 'dlw_mysql'
  }
}
FunctionOverrideCommandGet
source "ArgumentsMainInclude.sh";
###############################################################################
# 
# The MIT License (MIT)
# Copyright (c) 2014-2015 Richard Moyse License@Moyse.US
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
###############################################################################
#
# Docker and the Docker logo are trademarks or registered trademarks of Docker, Inc.
# in the United States and/or other countries. Docker, Inc. and other parties
# may also have trademark rights in other terms used herein.
#
###############################################################################
