#!/bin/bash
source "MessageInclude.sh";
source "ArgumentsGetInclude.sh";
source "ArrayMapTestInclude.sh";
source "ComponentListVerifyInclude.sh";
source "ArgumentsDockerVerifyInclude.sh";
source "VirtCmmdInterface.sh";
source "VirtDockerInterface.sh";
source "VirtDockerContainerInterface.sh";
source "PacketInclude.sh";
###############################################################################
##
##  Purpose:
##    Configure container virtual functions to implement 'stop' command.
##
###############################################################################
##
function VirtDockerContainerCommandNameGet () {
  echo 'rm'
}
##############################################################################
##
##  Purpose:
##    Configure container virtual functions to implement 'rm' command.
##
#################################################################################
##
function VirtDockerCmmdOptionsArgsDef () {
  ComponentNmListArgument 'rm' ''
  ComponentVersionArgument
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

Remove containers for targeted components.  Wraps docker 'rm' command.

Usage: dlw rm [OPTIONS] TARGET 
COMMAND_HELP_Purpose
  HelpCommandTarget "Caution!"
  HelpOptionHeading
  HelpComponentVersion
  HelpNoExecuteDocker 'false'
  HelpShowDocker 'false'
  HelpHelpDisplay 'false'
  DockerOptionsFormat 'rm'
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
  if ! DockerTargetContainerGUIDGenerate "$1" "$2" "$3" 'false' 'true' 'true' 'false'; then ScriptUnwind $LINENO "Unexpectd return code."; fi
}
FunctionOverrideCommandGet
source "ArgumentsMainInclude.sh";
