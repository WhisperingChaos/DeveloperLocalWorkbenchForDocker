#!/bin/bash
source "MessageInclude.sh";
source "ArgumentsGetInclude.sh";
source "ArrayMapTestInclude.sh";
source "ComponentListVerifyInclude.sh";
source "ArgumentsDockerVerifyInclude.sh";
source "VirtCmmdInterface.sh";
source "VirtDockerInterface.sh";
source "PacketInclude.sh";
###############################################################################
##
##  Purpose:
##    Define both the options and arguments accepted by the 'build' command.
##
###############################################################################
function VirtDockerCmmdOptionsArgsDef () {
# optArgName cardinality default verifyFunction presence
cat <<OPTIONARGS
--dlwno-parent single false=EXIST=true  "OptionsArgsBooleanVerify \\<--dlwno-parent\\>" required ""
--dlwforce single false=EXIST=true  "OptionsArgsBooleanVerify \\<--dlwforce\\>" required ""
OPTIONARGS
ComponentNmListArgument 'build' 'all'
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
cat <<COMMAND_HELP_Purpose

Create image file for targeted Components.  Wraps docker build command.

Usage: dlw build [OPTIONS] TARGET 
COMMAND_HELP_Purpose
  HelpCommandTarget
  HelpOptionHeading
  echo '    --dlwno-parent=false  Build only the targeted Component(s). Exclude prerequisite parent one(s).'
  echo "    --dlwforce=false      Force build even when Component Resources haven't changed." 
  HelpNoExecuteDocker 'false'
  HelpShowDocker 'false'
  HelpHelpDisplay 'false'

  DockerOptionsFormat 'build'
return 0
}
###############################################################################
##
##  Purpose:
##    Given one or more Component names, version scope and the desired 
##    command/operation to be executed against these Component(s), map each
##    Component to a Docker Target Concept.  A Docker Target Concept can
##    either be a Repository:tag (Image Name), Image GUID, or 
##    Container GUID.
##
##    Essentially this function converts the Docker Local Workbench
##    (dlw) Component concept into is associated docker image or container
##    objects.  A dlw Component is a analogous to class/type definition
##    that can be instantiated as an executable object.  Given this definition,
##    a Component can be directly mapped to a Docker image (class/type)
##    and a Docker container (executable object).
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
##    $3 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
## 
##  Return Code:     
##    When Failure: 
##      Indicates unknown parse state or token type.
##
###############################################################################
function VirtDockerTargetGenerate (){
  local -r optsArgListNm="$1"
  local -r optsArgMapNm="$2"
  local -r commandNm="$3"
  local computePrereqs="`AssociativeMapAssignIndirect "$optsArgMapNm" '--dlwno-parent'`"
  computePrereqs=$( [ "$computePrereqs" == 'true' ] && echo 'false' || echo 'true' )
  if ! DockerTargetImageGUIDlistNameGet "$1" "$2" "$3" "$computePrereqs"; then
    ScriptUnwind "$LINENO" "Unexpected problem while generating target list."
  fi
}
###############################################################################
##
##  Purpose:
##    When building, make dependency graph determines targets to be 
##    included/excluded, therefore, simply forward SYSOUT.
##
###############################################################################
function VirtDockerTargetExclude (){
 PipeForwarder
}
###############################################################################
##
##  Purpose:
##    Define build command template.  The 'build' type supported creates an
##    image with whose name is identical to the component name and whose tag
##    is defined as ":latest".  The build context is defined as the component's
##    local build context directory.
##
###############################################################################
function VirtDockerCmmdAssembleTemplate () {
  echo '$DOCKER_CMMDLINE_OPTION -t \"$PACKET_COMPONENT_NAME\" \"$PACKET_COMPONENT_PATH\" $DOCKER_CMMDLINE_COMMAND $DOCKER_CMMDLINE_ARG'
  return 0
}
###############################################################################
##
##  Purpose:
##    Given a docker build, update the just built component's ImageGUIDlist
##    to add its image GUID as the "current" version.  
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
##    $3 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
##    $4 - Variable name to an associative array containing other component 
##         specific attributes.
##    $5 - Return code of the executed docker command. 
##
###############################################################################
function VirtDockerCmmdExecute () {
  local -r optsArgListNm="$1"
  local -r optsArgMapNm="$2"
  local -r commandNm="$3"
  local -r targetMapNm="$4"
  local -r dockerCmmd="$5"
  # integrate the SYSOUT & SYSERR so it can be examined 
  eval $dockerCmmd
  if [ $? -ne 0 ]; then return 1; fi

  eval local \-\r imageGUIDfilename\=\$\{$targetMapNm\[\'ImageGUIDFileName\'\]\}
  eval local \-\r componentName\=\$\{$targetMapNm\[\'ComponentName\'\]\}
  if ! "ImageGUIDlist.sh" 'Add' "$imageGUIDfilename" "$componentName"; then return 1; fi
}
function VirtDockerCmmdExecutePacketForward () {
  echo 'false'
}
###############################################################################
##
##  Purpose:
##    Implements the dlw build command. dlw build command is a wrapper that
##    calls the docker build command.  dlw assembles command line options
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
##    $3 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
##    
##  Outputs:
##    When Successful:
##      SYSOUT - Indicates build operation completed successfully.
##    When Failure: 
##      SYSERR - Displays informative error message.
##
###############################################################################
function VirtCmmdExecute (){
  VirtDockerMain "$1" "$2" 'build'
}
FunctionOverrideCommandGet
source "ArgumentsMainInclude.sh";
