#!/bin/bash
###############################################################################
##
##    Section: Abstract Interface:
##      Defines an abstract interface for the compliation, execution and 
##      postprocessing of SYSOUT for a Docker command.
##
###############################################################################
##
###############################################################################
##
##  Purpose:
##    Define set of options/arguments specific to a given command.
##
##  See: VirtCmmdOptionsArgsDef
##
##  Output:
##    SYSOUT - Entries defining how to process arguments and options.
##
###############################################################################
function VirtDockerCmmdOptionsArgsDef () {
  ScriptUnwind $LINENO "Please override: $FUNCNAME".
}
###############################################################################
##
##  Purpose:
##    Define the abstract pipeline that will identify Docker Targets,
##    assemble/compile and execute one or more fully formed Docker commands,
##    and enables inspection and alteration of SYSOUT generated during the
##    execution of the Docker command(s).
##    
##  Assume:
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
##    $3 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
##
##  Output:
##    SYSOUT - Messages returned by the Docker daemon or by other pipline
##        processes.
##
###############################################################################
function VirtDockerMain () {
  local optArgListNm="$1"
  local optArgMapNm="$2"
  local commandNm="$3"

  VirtDockerScriptUnwindDef
  VirtDockerTargetGenerate      "$optArgListNm" "$optArgMapNm" "$commandNm" \
  | VirtDockerCmmdAssemble      "$optArgListNm" "$optArgMapNm" "$commandNm" \
  | DockerCmmdExecute           "$optArgListNm" "$optArgMapNm" "$commandNm" \
  | DockerCmmdProcessOutput     "$optArgListNm" "$optArgMapNm" "$commandNm"
}
###############################################################################
##
##  Purpose:
##    Redefines the implementation of 'ScriptUnwind' to generate a 'signal'
##    when an unwind event occurs that requests subsequent pipeline processes
##    to terminate.
##
##  Note:
##    'ScriptUnwind' terminates execution of current shell.
##
##  Input:
##    $1 - LINENO of calling location: 
##    $2 - Optional message text.
##
##  Output:
##    SYSERR - Writes a message, prefixed by "Abort: '.
## 
###############################################################################
function VirtDockerScriptUnwindDef () {
  ScriptUnwind $LINENO "Please override: $FUNCNAME".
}
###############################################################################
##
##  Purpose:
##    Given one or more Component names, version, and the desired 
##    command to be executed against these Component(s), map each
##    Component to the command's required Docker Target.  A Docker Target can
##    either be a Repository:tag (Image Name), Image GUID, or 
##    Container GUID.
##
##  Assume:
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
##    $3 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
##
##  Output:
##    SYSOUT - Packets containing attributes specific to a given Docker Target.
##         For example, docker commands that operate on containers require a
##         Container GUID. In this situation, the packet will contain a
##         Container GUID field.
## 
###############################################################################
function VirtDockerTargetGenerate (){
  ScriptUnwind $LINENO "Please override: $FUNCNAME".
}
###############################################################################
##
##  Purpose:
##    Assemble a Docker command using a template mechanism inspired by
##    environment variable substitution to construct the desired 
##    Docker operation.
##
##    There are two general classes of Docker commands.  One being
##    a targeted command, like rmi, which operates on a specific image GUID,
##    while the second type is untargeted and generally refers to either all
##    containers or images, for example, ps.  For targeted commands, each packet
##    generates a specific Docker command and its command text is added to 
##    the given packet. However, when producing untargeted, nonspecific
##    commands, the first detected packet will generate anrestrictToCompListother packet
##    containing the Docker command.
##
##  See:
##    'function DockerCmmdAssemble' for more detailed explaination of
##     template substitution.
##    
##  Assume:
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
##    $3 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
##    SYSIN - one or more formatted packets or "unrecognized messages" written
##            by an upstream process to this one's SYSIN.  "unrecognized messages"
##            are simply forwarded to SYSOUT.
## 
##  Output:     
##    SYSOUT - A field named 'DockerCommand' is added to either every packet or
##       the first detected packet of a non specific Docker command packet
##       that contains the assembled Docker command.
##
###############################################################################
function VirtDockerCmmdAssemble () {
  ScriptUnwind $LINENO "Please override: $FUNCNAME".
}
###############################################################################
##
##  Purpose:
##    Defines a "template" of a docker command's options and argument values.
##    The template consists of bash variables that are resolved during the
##    command assembly process.  
##
##  See:
##    'function DockerCmmdAssemble' for more detailed explaination of
##     template substitution.
##    
##  Input:
##    $1 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
## 
##  Output:   
##    SYSOUT - A single record whose format reflects the option and argument
##         values and placement needed by the Docker command.  The dynamic
##         option/argument values are defined using bash variable names while
##         static ones, can simply appear in the template's body.
##
###############################################################################
function VirtDockerCmmdAssembleTemplate () {
  ScriptUnwind $LINENO "Please override: $FUNCNAME".
}
###############################################################################
##
##  Purpose:
##    Provides a means of extending the bash variable name-value pairs 
##    defined during template substitution.  These name-value pairs are
##    specific to the "packet" context. 
##
##  See:
##    'function DockerCmmdAssemble' for more detailed explaination of
##     template substitution.
##    
##  Input:
##    $1 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
## 
##  Output:   
##    SYSOUT - Each record contains the desired bash varialble name
##         seperated by whitespace from the packet field name that
##         refers to the desired field value to be assigned to the 
##         bash variable name.
##
###############################################################################
function VirtDockerCmmdAssembleTemplateResolvePacketField () {
  ScriptUnwind $LINENO "Please override: $FUNCNAME".
}
###############################################################################
##
##  Purpose:
##    Permits 'primary' commands other than Docker to utilize template 
##    assembly process.  For example, in addition to the 'Docker' primary
##    command, the template assembly process can also generate 
##    linux screen commands. 
##
##  Input:
##    None
## 
##  Output:   
##    SYSOUT - The primary command name that's invoked on a linux command line.
##
###############################################################################
function VirtDockerCmmdExecPrimaryName () {
  ScriptUnwind $LINENO "Please override: $FUNCNAME".
}
###############################################################################
##
##  Purpose:
##    Executes a fully formed docker command.  Allows isolated inspection of
##    SYSOUT/SYSERR for each docker command and provides a means to affect
##    the Image GUID List when executing certain commands, like build and rmi. 
##    
##  Assume:
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
##    $3 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
##    $4 - Variable name to an associative array.  The key/value pairs of the
##         array differ depending on the type of Docker Target.
##    $5 - A fully formed Docker command.
##
##  Output:
##    SYSOUT - Messages returned by the Docker daemon 
##
###############################################################################
function VirtDockerCmmdExecute () {
  ScriptUnwind $LINENO "Please override: $FUNCNAME".
}
###############################################################################
##
##  Purpose:
##    Certain commands, like reporting ones, require that the image/container
##    packets used to generate the command, be forwarded to the next
##    pipeline process after the execute one.  This virtual function
##    determines 
##
##  Input:
##    none
## 
##  Output:
##    'true'  - forward command packet
##    'false' - do not forward command packet
## 
###############################################################################
function VirtDockerCmmdExecutePacketForward () {
  ScriptUnwind $LINENO "Please override: $FUNCNAME".
}
###############################################################################
##
##  Purpose:
##    Execute a procedure after all the Docker file commands have been
##    successfully executed.  This procedure will typically modify the 
##    one or more Components' Image GUID List(s).  For example, after 
##    successfully deleting images from the local Docker repository,
##    the corresponding GUIDs maintained in Image GUID List(s) must be 
##    removed from the list. 
##    
##  Assume:
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
##    $3 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
## 
###############################################################################
function VirtDockerCmmdExecuteAtCompletion () {
  ScriptUnwind $LINENO "Please override: $FUNCNAME".
}
###############################################################################
##
##  Purpose:
##    Allows inspection/alteration of SYSOUT from all Docker commands executed
##    by the pipeline.
##    
##  Assume:
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
##    $3 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
##
##  Output:
##    SYSOUT - Potentially altered/filtered SYSOUT returned by the Docker daemon. 
##
###############################################################################
function VirtDockerCmmdProcessOutput () {
  ScriptUnwind $LINENO "Please override: $FUNCNAME".
}
###############################################################################
##
##    Section: Implementation:
##      Defines common implementation for functions required by all commands.
##
###############################################################################
##
###############################################################################
##
##  Purpose:
##    Examine command line options/arguments to ensure reasonable values
##    were provided.
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
##    'VirtCmmdOptionsArgsDef' - A callback function that supplies a table
##         containing constraint information used, for example, to
##         verify the values of the arguments/options.
## 
##  Output:
##    When Successful:
##      All the arguments/options passes a "sniff' test.
##    When Failure: 
##      SYSERR - Contains a message that specifically indicates why the
##               option/argument failed its verification.
##
###############################################################################
function VirtCmmdOptionsArgsVerify () {
  # COMPONENT_CAT_DIR is considered an "argument".  At this point, immediately
  # before validating options/argurment, it must point to a valid Component
  # directory, otherwise, certain validation functions will fail.
  if ! [ -d  "$COMPONENT_CAT_DIR" ]; then
    ScriptUnwind $LINENO "Missing Component directory: '$COMPONENT_CAT_DIR'."
  fi
  OptionsArgsVerify  'VirtCmmdOptionsArgsDef' "$1" "$2"
}
###############################################################################
##
##  Purpose:
##    Define set of options/arguments common to all commands and a means to
##    to include those specific to a given one.
##
##  Input:
##    VirtDockerCmmdOptionsArgsDef - Virtual callback function that provides
##         command specific options/arguments that either supplement or
##         replace the common ones.
##
##  Output:
##    SYSOUT - Entries defining how to process arguments and options.
##
###############################################################################
function VirtCmmdOptionsArgsDef (){
# optArgName cardinality default verifyFunction presence
cat <<OPTIONARGS
--dlwno-exec single false=EXIST=true "OptionsArgsBooleanVerify \\<--dlwno-exec\\>" required ""
--dlwshow single false=EXIST=true "ShowOptionVerify \\<--dlwshow\\>" required ""
--Ignore-Unknown-OptArgs single --Ignore-Unknown-OptArgs "" optional ""
OPTIONARGS
VirtDockerCmmdOptionsArgsDef
return 0
}
##############################################################################
function VirtCmmdConfigSetDefault () {
  return 0
}
###############################################################################
##
##  Purpose:
##    Redefines the implementation of 'ScriptUnwind' to generate a 'signal'
##    when an unwind event occurs that causes subsequent pipeline processes to 
##    terminate.
##
##  Input:
##    $1 - LINENO of calling location: 
##    $2 - Optional message text.
##
##  Ouptut:
##    Writes a message, prefixed by "Abort: ' to SYSERR.
##
##
##  Output:
##    SYSOUT - Packets containing attributes specific to a given Docker Target.
##         For example, Docker commands that operate on containers require a
##         Container GUID. In this situation, the packet will contain a
##         Container GUID field.
## 
###############################################################################
function VirtDockerScriptUnwindDef () {
    function ScriptUnwind (){
      ScriptUnwindImplPipe "$1" "$2"
    }
}
###############################################################################
##
##  Purpose:
##    Convert --dlwno-prereq setting into control that governs if 
##    prerequisites are included in command generation, mearly affect
##    the ordering of commands, or have no effect at all.
##    
##  Assumption:
##    Since bash variable names are passed to this routine, these names
##    cannot overlap the variable names locally declared within the
##    scope of this routine or its decendents.
##
##  Inputs:
##    $1 - value of no-prerequisite setting:
##           'true'  - Don't include nor order generated commands using
##                     the command's dependency graph.
##           'order' - Don't include prerequisite Components when generating
##                     commands but order specified targets using dependency graph.
##           'false' - Include prerequisite Components when generating
##                     commands and order specified targets according
##                     to dependency graph.
##    $2 - a valure representing the dependency 'prespective':
##          'true'    - Interperet dependency order as defined.
##          'reverse' - Interperet dependency in reverse order as defined.
##          'false'   - Do not consider dependencies.
##    $3 - A variable name reflecting the output value of $2.
##    $4 - A variable name whose value determines the exclude prerequisite
##         setting:
##          'true'    - exclude prerequisites
##          'false'   - include prerequisites
## 
##  Return Code:
##    When Success:
##      $3 & $4 variable names are appropriately set.
##    When Failure: 
##      Terminates the process running this script.
##
###############################################################################
function NoPrereqSetting () {
  local -r noPrereq="$1"
  local -r dependPerspect="$2"
  local -r dependGraphNM="$3"
  local -r excludePrereqNM="$4"

  if [ "$noPrereq" == 'false' ]; then 
    # include prerequisites
    eval $dependGraphNM=\'$dependPerspect\'
    eval $excludePrereqNM=\'false\'
  elif [ "$noPrereq" == 'order' ]; then
    # exclude prerequisites but sequence by dependency order
    eval $dependGraphNM=\'$dependPerspect\'
    eval $excludePrereqNM=\'true\'
  elif  [ "$noPrereq" == 'true' ]; then
    # exclude prerequisites but sequence by target ordering
    eval $dependGraphNM=\'false\'
    eval $excludePrereqNM=\'true\'
  else
    ScriptUnwind $LINENO "Invalid --dlwno-prereq value: '$noPrereq'."
  fi
  return 0
}
###############################################################################
##
##  Purpose:
##    Produce a series of packets, in appropriate dependency graph order,
##    that serialize a Component's: name, command context directory, and
##    file name of its Image GUID List for the specified Compontent(s).  This
##    request will typically include their statically dependent parent
##    (ancestor) ones. Therefore, more packets are generally produced
##    than the number of Component names provided to this routine.
##
##    Note, although not necessary, each command can maintain its own
##    dependency list.  This can be accomplished in the makefile layer.
##    However, most divergent dependency graphs reflect the contrast
##    between build and run time dependencies.  Therefore, so far,
##    all commands are classified as belonging to one of these types.
##    
##  Assume:
##    Since bash variable names are passed to this routine, these names
##    cannot overlap the variable names locally declared within the
##    scope of this routine or its decendents.
##
##  Input:
##    $1 - Variable name to an array whose values contain the label names
##         of the options and agruments appearing on the command line in the
##         order specified by it.  The arguments reflect the names of the
##         components targeted by the dlw command. 
##    $2 - Variable name to an associative array whose key is either the
##         option or argument label and whose value represents the value
##         associated to that label.
##    $3 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
##    $4 - Compute Component prerequisites:
##           'true'    - Yes - According to the "standard" ordering.
##           'false'   - No  - Treat as independent Component.
##           'reverse' - Yes - Reverse the "standard" ordering.
## 
##  Output:
##    SYSOUT - One or more serialized "packets" containing 
##
###############################################################################
function DockerTargetImageGUIDlistNameGet (){
  local optsArgListNm="$1"
  local optsArgMapNm="$2"
  local commandNm="$3"
  local -r computePrereqs="$4"
  local -a targetArgList
  local -A targetArgMap
  if ! OptionsArgsFilter "$optsArgListNm" "$optsArgMapNm" 'targetArgList' 'targetArgMap' '[[ "$optArg" =~ Arg[0-9][0-9]* ]]' 'true'; then  ScriptUnwind $LINENO "Unexpectd return code."; fi
  local targetNoDepndSuffix=
  if [ "$computePrereqs" == 'false' ]; then targetNoDepndSuffix='.nodep'; fi
  local forceBuildInd='true'
  if [ "$3" == 'build' ]; then
    # The option to force or rely on resource timestamps to dictate what 
    # will be compiled, is limited to only the build command.  All other
    # commands force the generation of a full dependency tree within the
    # context of the Component specified.
    AssociativeMapAssignIndirect "$optsArgMapNm" '--dlwforce' 'forceBuildInd'
  fi
  local makeForce=
  if $forceBuildInd; then makeForce="--always-make"; fi
  local makeList
  for argTarget in "${targetArgList[@]}"
  do
    makeList="$makeList ${targetArgMap["$argTarget"]}.${commandNm}${targetNoDepndSuffix}"
  done
  local reverseFun='';
  if [ "$computePrereqs" == 'reverse' ]; then
     reverseFun='| tac'
  fi
  eval make \-\-no\-print-directory \-\-directory\=\"\$MAKEFILE_DIR\" \$makeForce COMMAND_CURRENT=\"\$commandNm\" BUILD_FORCED=\"\$forceBuildInd\" \$makeList  $reverseFun
  return ${PIPESTATUS[0]}
}
###############################################################################
##
##  Purpose:
##    Specializes non-image specific Component packets by generating one or 
##    more packets that include the Image GUIDs defined by the Component
##    version specifier.  Essentially augments packets produced by
##    'DockerTargetImageGUIDlistNameGet' with an Image GUID.
##    
##  Assume:
##    Since bash variable names are passed to this routine, these names
##    cannot overlap the variable names locally declared within the
##    scope of this routine or its decendents.
##
##  Input:
##    $1 - Variable name to an array whose values contain the label names
##         of the options and agruments appearing on the command line in the
##         order specified by it.  The arguments reflect the names of the
##         components targeted by the dlw command. 
##    $2 - Variable name to an associative array whose key is either the
##         option or argument label and whose value represents the value
##         associated to that label.
##    $3 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
##    $4 - Compute Component prerequisites:
##           'true'    - Yes - According to the "standard" ordering.
##           'false'   - No  - Treat as independent Component.
##           'reverse' - Yes - Reverse the "standard" ordering.
##    $5 - Determine size of GUIDs inserted in Packets:
##           'true' - Truncate to 12.
##           otherwise, use 64 character long version.
##    $6 - Restrict packet generation to only those explicitly specified
##         by the command being processed.  In other words, remove the 
##         implicit parent Components included by the dependency graph.
##         Essentially, permits ordering of the packets by command's
##         dependency graph and then removes any implicit parent Components.
##           'true' - Exclude Component ancestors. 
##           otherwise - Include Component ancestors.
##    SYSIN - Non specific Component packets in dependency graph order.
## 
##  Output:
##    SYSOUT - Augmented packet, containing Image GUID, in dependency graph order.
##
###############################################################################
function DockerTargetImageGUIDGenerate (){
  function ImageGUIDtruncate () {
    local imageGUID
    while read imageGUID; do
      echo "${imageGUID:0:12}${imageGUID:64}"
    done
    return 0
  }
  local -r optsArgListNm="$1"
  local -r optsArgMapNm="$2"
  local -r commandNm="$3"
  local -r componentPrereq="$4"
  local -r truncGUID="$5"
  local -r restrictToCompList="$6"
  local -r allTargets="`AssociativeMapAssignIndirect "$optsArgMapNm" 'Arg1'`"
  local -r limitToCompList="`if [ "$allTargets" == 'all' ]; then echo 'false'; else echo "$restrictToCompList"; fi`"
  local -A compMap
  if [ "$limitToCompList" == 'true' ]; then
    # selective deletion, filter out component not mentioned in the command
    # create an associative map to join
    CompNameMapGen "$optsArgListNm" "$optsArgMapNm" 'compMap'
  fi
  # Optionally include a truncation operation in the stream.
  # Image GUID list contains only long image ids.
  local truncateFun='PipeForwarder'
  if [ "$truncGUID" == 'true' ]; then 
    truncateFun='ImageGUIDtruncate'
  fi
  # determine the desired Component version
  local -r componentVerDesired="`AssociativeMapAssignIndirect "$optsArgMapNm" '--dlwcomp-ver'`"
  local packet
  while read packet; do
    PipeScriptNotifyAbort "$packet"
    if ! PacketPreambleMatch "$packet"; then     
      echo "$packet"
      continue
    fi
    # Unpack packet to get necessary data
    local -A packetMap
    PacketConvertToAssociativeMap "$packet" 'packetMap'
    local imageGUIDfileNm
    AssociativeMapAssignIndirect 'packetMap' 'ImageGUIDFileName' 'imageGUIDfileNm'
    # Determine if Image GUID List exists for component, as component may have been
    # completely deleted or not yet built.
    if [ ! -f "$imageGUIDfileNm" ]; then continue; fi
    local componentName
    AssociativeMapAssignIndirect 'packetMap' 'ComponentName' 'componentName'
    if [ "$limitToCompList" == 'true' ]; then
      # using dependency graph to order component processing, but if the component 
      # isn't mentioned in the argurment list, remove it.
      if [ "${compMap["$componentName"]}" != 'true' ]; then continue; fi
    fi
    # create one or more packets for each Component containing an Image GUID
    # and any attributes associated to the Image GUID.
    # More than one packet will be created for a version request that refers
    # to more than one version.  Also, additional packets are created for 
    # a GUID that's associated to a Repository:tag name.
    "ImageGUIDlist.sh" "$componentVerDesired" "$imageGUIDfileNm" \
    | $truncateFun \
    | PacketImageGUID "$packet" "$truncGUID"
    if [ ${PIPESTATUS[0]} -ne 0 ]; then 
      ScriptUnwind $LINENO "Image GUID list acquisition failed for: '$imageGUIDfileNm'"
    fi
  done < <(DockerTargetImageGUIDlistNameGet "$optsArgListNm" "$optsArgMapNm" "$commandNm" "$componentPrereq")
  return 0
}
###############################################################################
##
##  Purpose:
##    Extract and add Image GUID and its extended attributes to the 
##    non specific Component Packet.  The addition of the Image GUID transforms
##    the non specific one into one targeted to a particular Docker image.
##    
##  Input:
##    $1 - Packet data provided so far.
##    $2 - GUID length indicator:
##         'true' - GUID 12 characters.
##         otherwise - GUID 64 characters.
##    SYSYIN - Non specific Component packets in dependency graph order.
## 
##  Output:
##    SYSOUT - Augmented packet, containing Image GUID and extended attributes
##             in dependency graph order.
##
###############################################################################
function PacketImageGUID () {
   local -r truncGUID="$2"
   local packet="$1"
   if [ "$truncGUID" == 'true' ]; then local -r -i startBagOffset=$(( 12 + 1)); else local -r -i startBagOffset=$(( 64 +1 )); fi
   local -r componentPropBagLit='componentPropBag='
   local imageGUIDentry
   while read imageGUIDentry; do
     local compPropBagInst="${imageGUIDentry:$startBagOffset}"
     unset componentPropBag
     if [ "${compPropBagInst:0:${#componentPropBagLit}}" == "$componentPropBagLit" ]; then
       if ! eval declare \-\A $compPropBagInst; then
         ScriptUnwind $LINENO "Syntax of Component property bag incorrect: '$compPropBagInst'. Won't properly deserialize."
       fi
       PacketCreateFromAssociativeMap 'componentPropBag' 'compPropBagInst'
     fi
     PacketCat "$packet" "$compPropBagInst" 'packet'
     PacketAddFromStrings "$packet" 'ImageGUID' "${imageGUIDentry:0:$startBagOffset-1}" 'packet'
     echo "$packet"
   done
  return 0
}
###############################################################################
##
##  Purpose:
##    Update an associative map to contain only those Component names that
##    appear in the argument list of the provided command.
##
##    Note - The target of 'all' will be included in this list and will
##    most probably be the only one in the list.  This permits the following
##    logic when testing a Component name for inclusion:
##    "if [ "${compTargetMap["$currentComponentName"]}" == 'true'] || [ "${compTargetMap['all']}" == 'true']; then..."
##    
##  Assume:
##    Since bash variable names are passed to this routine, these names
##    cannot overlap the variable names locally declared within the
##    scope of this routine or its decendents.
##
##  Input:
##    $1 - Variable name to an array whose values contain the label names
##         of the options and agruments appearing on the command line in the
##         order specified by it.  The arguments reflect the names of the
##         components targeted by the dlw command. 
##    $2 - Variable name to an associative array whose key is either the
##         option or argument label and whose value represents the value
##         associated to that label.
##    $3 - Variable name to an associative array whose key is a targeted 
##         component name and whose value is 'true'.  If there is something
##         in this array when passed to this routine, it will remain in the
##         array.
## 
##  Output:
##    $3 - Component names are added to this associative array.
##
###############################################################################
function CompNameMapGen () {
  local -r optsArgListNm="$1"
  local -r optsArgMapNm="$2"
  local -r compMapNm="$3"
  local -a ArgList
  local -A ArgMap
  if ! OptionsArgsFilter "$optsArgListNm" "$optsArgMapNm" 'ArgList' 'ArgMap' '[[ "$optArg" =~ Arg[1-9][0-9]* ]]' \
      'true'; then  ScriptUnwind $LINENO "Unexpectd return code."; fi
  local compName
  for compName in "${ArgMap[@]}"
  do
    eval $compMapNm\[\"\$compName\"\]\=\'true\'
  done
  return 0
}
###############################################################################
##
##  Purpose:
##    Identify the containers derived from Components targeted by a given
##    command and generate Container GUID packets by differienciating its 
##    parent Image GUID packet with offspring Container GUIDS.
##    
##    Essentially, perform a join operation between the Container list
##    generated by the 'docker ps' command and the Image GUIDs associated to the
##    targeted Components.  This stream is needed by Docker commands 
##    implementing Container operators, like 'Stop'.
##    
##  Assume:
##    Since bash variable names are passed to this routine, these names
##    cannot overlap the variable names locally declared within the
##    scope of this routine or its decendents.
##
##  Input:
##    $1 - Variable name to an array whose values contain the label names
##         of the options and agruments appearing on the command line in the
##         order specified by it.  The arguments reflect the names of the
##         components targeted by the dlw command. 
##    $2 - Variable name to an associative array whose key is either the
##         option or argument label and whose value represents the value
##         associated to that label.
##    $3 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
##    $4 - Compute Component prerequisites:
##           'true'    - Yes - According to the "standard" ordering.
##           'false'   - No  - Treat as independent Component.
##           'reverse' - Yes - Reverse the "standard" ordering.
##    $5 - Determine size of GUIDs inserted in Packets:
##           'true' - Truncate to 12.
##           otherwise, use 64 character long version.
##    $6 - Restrict packet generation to only those explicitly specified
##         by the command being processed.  In other words, remove the 
##         implicit parent Components included by the dependency graph.
##         Essentially, permits ordering of the packets by command's
##         dependency graph and then removes any implicit parent Components.
##           'true' - restrict to only those specified as targets
##           otherwise, include prerequisites with targets.
##    $7 - Apply state filtering when considering which container(s) as targets.
##           'true'  - filter container(s) based on current state.
##           'false' - state doesn't matter, include as target.
##    SYSYIN - Component packets containing Image GUID in dependency graph order.
## 
##  Output:
##    SYSOUT - Component packets that are now specific to an associated Container
##             in dependency graph order.
##
###############################################################################
function DockerTargetContainerGUIDGenerate (){
  local -r optsArgListNm="$1"
  local -r optsArgMapNm="$2"
  local -r commandNm="$3"
  local -r componentPrereq="$4"
  local -r truncGUID="$5"
  local -r restrictToCompList="$6"
  local -r stateFilterApply="$7"
  local -A imageGUIDreposTag
  #  Image GUID when it appears in ps command is always truncated
  ImageGUIDReproTagMapCreate 'true' 'imageGUIDreposTag'
  function DependencyOrderPreambleRemove () {
    local packet
    while read packet; do
      echo "${packet#[^ ]*[ ]}"
    done
    return 0
  }
  local -A imageGUIDfilterMap
  local -A imageGUIDmap
  local packet
  local -i packetOrder=0
  while read packet; do
    PipeScriptNotifyAbort "$packet"
    # foward anything not a packet
    if ! PacketPreambleMatch "$packet"; then 
      echo "$packet"
      continue
    fi
    # Does packet contain ImageGUID requiring transform
    PacketConvertToAssociativeMap "$packet" 'imageGUIDmap'
    local imageGUID="${imageGUIDmap['ImageGUID']}"
    if [ -z "$imageGUID" ]; then
      # Forward packet not interested in processing
      echo "$packet"
      continue;
    fi
    # Docker prefers displaying Repository:Tag instead of Image GUID
    local imageReposTagName="${imageGUIDreposTag["$imageGUID"]}"
    if [ -n "$imageReposTagName" ]; then
      # treat Repository:Tag as Image GUID
      imageGUID="$imageReposTagName"
    fi
    (( ++packetOrder ))
    PacketAddFromStrings "$packet"  'DependencyOrder' "$packetOrder" 'packet'
    imageGUIDfilterMap["$imageGUID"]="$packet"
  done < <( DockerTargetImageGUIDGenerate "$optsArgListNm" "$optsArgMapNm" "$commandNm" "$componentPrereq" 'true' "$restrictToCompList" )

  function ExtractToFirstWhiteSpace () {
    eval $1=\"\$2\"
  }
  local dockerNoTruncOpt
  if [ "$truncGUID" != 'true' ]; then
    dockerNoTruncOpt='--no-trunc'
    local -r -i GUIDlen='64'
  else
    local -r -i GUIDlen='12'
  fi
  local hdrPsProcessInd='false'
  local containerGUIDColOff
  local imageGUIDcolOff
  local containerStatusColOff
  local psReport
  while read psReport; do
    if ! $hdrPsProcessInd; then
      hdrPsProcessInd='true'
      # determine start location of desired column 
      ReportColumnOffset 'ps' "$psReport" 'CONTAINER ID' 'containerGUIDColOff'
      ReportColumnOffset 'ps' "$psReport" 'IMAGE' 'imageGUIDcolOff'
      ReportColumnOffset 'ps' "$psReport" 'STATUS' 'containerStatusColOff'
      continue
    fi
    # extract Image GUID/Repository:Tag
    local possibleImageGUID="${psReport:$imageGUIDcolOff}"
    ExtractToFirstWhiteSpace 'possibleImageGUID' $possibleImageGUID
    # remove blank lines - shouldn't be there.
    if [ -z "$possibleImageGUID" ]; then continue; fi
    # might be heading or unwanted image GUID
    packet="${imageGUIDfilterMap["$possibleImageGUID"]}"
    if [ -z "$packet" ]; then continue; fi
    # does container pass status filter
    $stateFilterApply && if ! VirtContainerStateFilterApply "${psReport:$containerStatusColOff}"; then continue; fi
    # add the container GUID to the packet then forward it.
    local -A imageGUIDmap
    unset imageGUIDmap
    local -A imageGUIDmap
    PacketConvertToAssociativeMap "$packet" 'imageGUIDmap'
    imageGUIDmap['ImageGUID']="$possibleImageGUID"
    PacketCreateFromAssociativeMap 'imageGUIDmap' 'packet'
    PacketAddFromStrings "$packet" 'ContainerGUID' "${psReport:$containerGUIDColOff:$GUIDlen}" 'packet'
    local dependencyOrder="${imageGUIDmap['DependencyOrder']}"
    echo "$dependencyOrder $packet"
  done < <( docker ps -a $dockerNoTruncOpt) > >( sort -k1.1n | DependencyOrderPreambleRemove; )
  return 0
}
###############################################################################
##
##  Purpose:
##    Docker supports image idenity through the use of a short GUID, long GUID
##    and Repository[:tag] name.  This routine creates an associative 
##    array that maps either a short or long GUID to its corresponding
##    Repository[:tag] name.
##
##  Assume:
##    - Docker images output format displays the following columns in the
##      order presented: Repository Name, Tag, and Image ID.
##    - The Repository Name and Tag cannot contain spaces.
##    - Since bash variable names are passed to this routine, these names
##      cannot overlap the variable names locally declared within the
##      scope of this routine or its decendents.
##
##  Input:
##    $1 - Determines if long GUID should be truncated into small one.
##           'true' - truncate GUID.
##    $2 - Variable name to an associative array whose key is either a
##         long or short GUID and whose value will contain its associated
##         Repository:tag name.
##
##  Output:
##    $2 - An associative array correlating all the Repository:tag
##         image names known to local Docker Daemon to their GUID.
## 
##  Return Code:
##    When Failure: 
##      Indicates format of report columns differs from what's expected.
##
###############################################################################
function ImageGUIDReproTagMapCreate () {
  local -r imageGUIDtrunc="$1"
  local -r GUIDReproTagMapNM="$2"
  local dockerNoTruncOpt
  if [ "$imageGUIDtrunc" != 'true' ]; then
    dockerNoTruncOpt='--no-trunc'
  fi
  local firstEntry='true'
  local imageRptEntry
  while read imageRptEntry; do
    if $firstEntry; then
      firstEntry='false'
      local -r rptHeading="`echo "$imageRptEntry" | awk '{ print $1 $2 $3 $4 }'`"
      if [ "$rptHeading" != "REPOSITORYTAGIMAGEID" ]; then
        ScriptUnwind $LINENO "Unexpected image report heading: '$rptHeading'"
      fi
      continue
    fi
    local repositoryName="`echo "$imageRptEntry" | awk '{ print $1 }'`"
    if [ "$repositoryName" == '<none>' ]; then continue; fi
    local tagName="`echo "$imageRptEntry" | awk '{ print $2 }'`"
    local imageGUID="`echo "$imageRptEntry" | awk '{ print $3 }'`"
    if [ -z "$imageGUID" ]; then 
      ScriptUnwind $LINENO "Image GUID should not be empty: '$imageGUID'"
    fi
    eval $GUIDReproTagMapNM\[\"\$imageGUID\"\]\=\"\$\{repositoryName\}\:\$\{tagName\}\"
  done < <(docker images $dockerNoTruncOpt)
  return 0
}
###############################################################################
##
##  Purpose:
##    Extract important column offsets from the metadata tags (column headings)
##    generated by a Docker report.  If the report no longer provides
##    the data or it's column heading has changed, then this routine will
##    potentially identify this issue and unwind this process.
##
##  Assume:
##    - Since bash variable names are passed to this routine, these names
##      cannot overlap the variable names locally declared within the
##      scope of this routine or its decendents.
##
##  Input:
##    $1 - Header type.
##    $2 - Header for Docker command.
##    $3 - Column name to locate in the Docker header.
##    $4 - Variable name to contain the column offset.
##
##  Output:
##    $4 - Column offset.
## 
##  Return Code:
##    When Failure: 
##      SYSERR - message problem & unwind script.
##
###############################################################################
function ReportColumnOffset () {
  local -r rptHdrType="$1"
  local rptHdr="$2"
  local -r -i rptHdrLen="${#rptHdr}"
  local -r columnName="$3"
  local -r columnNameNm="$4"
  rptHdr="${rptHdr%%$columnName*}"
  if ! [ "${#rptHdr}" -lt "$rptHdrLen" ]; then 
    ScriptUnwind $LINENO "Docker '$rptHdrType' header doesn't match what's expected.  Missing column: '$columnName'.  See: '$rptHdr'"
  fi
  eval $columnNameNm=\"\$\{\#rptHdr\}\"
  return 0
}
###############################################################################
##
##  Purpose:
##    Filter container targets so they match appropriate state: 'UP', 
##    'Paused',... required to execute the yet to be generated Docker
##    container command.
##
##  Input:
##    $1 - Status string displayed by the 'docker ps -a' command report..
##
##  Return Code:
##    When Success:
##      Accept container.
##    When Failure: 
##      Reject container.
##
###############################################################################
function VirtContainerStateFilterApply () {
  # default implementation is to accept all containers.
  return 0
}
###############################################################################
##
##  Purpose:
##    This default implementation generates a Docker command packet for 
##    each input packet it consumes.  In general, Docker commands require either
##    a container or image reference (GUID, name...) be specified 
##    in order to apply the desired operation.  However, there are some
##    reporting commands, like ps/images that either don't accept targets or
##    they're optional.
##    
##  See:
##    'function VirtDockerCmmdAssemble' declaration.
##
###############################################################################
function VirtDockerCmmdAssemble () {
  local -r optsArgListNm="$1"
  local -r optsArgMapNm="$2"
  local -r commandName="$3"

  DockerCmmdAssemble "$optsArgListNm" "$optsArgMapNm" "$commandName"
}
###############################################################################
##
##  Purpose:
##    Assemble the Docker command to perform the desired function.  Assembly
##    cobbles together Docker options, its command target(s), and additional
##    arguments to form an executable Docker command.  This function also
##    provides a context for resolving variables defined in a template.  A 
##    template reflects the form of a Docker command's arguments.
##    A context merges:
##      1. The command option and arguments supplied by the user.  These values
##         (context) don't change at all during the execution of the particular
##         command, like build, ps, rm....  
##      2. Data elements encapsulated within a packet processed by this routine. The
##         data values of these elements change with every new packet processed.
##      3. The contents of one or more files maintained by the "context" directory
##         specific to a given command associated to a particular component.
##         The file names and their contents potentially change for each component/command.
##    In general data elements provided by these differing import mechanisms, don't
##    overlap.  However, if they do, items of "3", should supersede items of "2"
##    which supersede/overide items defined by "1".  The data elements are
##    are ultimately implemented as bash variables.
##   
##    A template describes the Docker option/argument syntax for a given Docker
##    command. It consists of potentially constant Docker argument value(s),
##    those that never change, as well as variable argument values, those
##    that change from component to component or one Docker command invocation
##    to another.  The variable arguments are encoded as bash variable names
##    and must appear in their substitution
##    form: $VARIABLE_NAME or ${VARIABLE_NAME}.
##
##    Each context can be thought of as a namespace.  For context 1 and 2 defined
##    above, there's no specific namespace name that must currently be adhered to for
##    these data items.  However, the 3 context, the one which maps file names to
##    a command-target directory, must prefix its bash names with a namespace.  The
##    name of the namespace is maintained by the bash variable: DOCKER_FILE_NAMESPACE.
##    This namespace both prefixes files within the command's context directory to
##    isolate them from the other resources and permits dynamic extension of
##    options/arguments processed in this manner, as this namespace name is 
##    coupled to behavior that will automatically read files in the context
##    directory that begin with the same prefix and that are mentioned in the
##    template.
##    
##  Assume:
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
##    $3 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
##    SYSIN - one or more formatted packets or "unrecognized messages" written
##            by an upstream process to this one's SYSIN.  "unrecognized messages"
##            are simply forwarded to SYSOUT.
## 
##  Return Code:     
##    When Success:
##       A field named 'DockerCommand' is appended to the current packet
##       containing the compiled Docker command.  The updated packet is then
##       written to SYSOUT.
##    When Failure: 
##      Issues a notify message to SYSOUT with error messages written
##      to SYSERR, then terminate the process.
##
###############################################################################
function DockerCmmdAssemble () {
  local optsArgListNm="$1"
  local optsArgMapNm="$2"
  local commandNm="$3"
  local -a optDockerList
  local -A optDockerMap
  local -r DOCKER_FILE_NAMESPACE='$DOCKER_CMMDLINE_'
  OptionsArgsFilter "$optsArgListNm" "$optsArgMapNm" 'optDockerList' 'optDockerMap'  '( [[ "$optArg"  =~ ^-[^-].*$ ]] || [[ "$optArg"  =~ ^--.*$ ]] ) && ! [[ "$optArg"  =~ ^--dlw.*$ ]]' 'true'
  eval local ${DOCKER_FILE_NAMESPACE:1}OPTION\=\"\`OptionsArgsGen \'optDockerList\'\ \'optDockerMap\'\`\"
  local target
  while read target; do
    PipeScriptNotifyAbort "$target"
    if PacketPreambleMatch "$target"; then     
      if ! dockerCmmd=`DockerCmmdAssembleTemplateResolve "$commandNm" "$target"`; then
        ScriptUnwind $LINENO "Docker command template resolution failed."
      fi
      PacketAddFromStrings "$target" 'DockerCommand' "$dockerCmmd" 'target'
    fi
    echo "$target"
  done 
  return 0
}
###############################################################################
##
##  Purpose:
##    Exposes the context information encapsulated by a packet (type "2",
##    mentioned above) and those represented as a file within a component's
##    command context directory (type "3").  Currently type 2 and 3 contexts
##    don't overlap, and are unlikely to do so, so they are maintained in the
##    same function.  If this should change, then the type three code must
##    be refactored into a child function so it may leverage the bash 
##    variable scoping rules to ensure the primancy of the type "3" context
##    over "2".
##
##  Assume:
##    This function inherits the bash variables declared by its ancestor
##    function(s) potentially overriding those ancestor variables declared
##    within its scope.
##
##  Input:
##    $1 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
##    $2 - A valid packet containing data items used either directly or
##         indirectory to resolve the bash variables that appear in the
##         template.
##    VirtDockerCmmdAssembleTemplate - A callback routine that provides the
##         template.
## 
##  Return Code:     
##    When Success:
##       SYSOUT - Reveals a fully resolved Docker command.
##    When Failure: 
##      Issues a notify message to SYSOUT with error messages written
##      to SYSERR, then terminate the process.
##
###############################################################################
function DockerCmmdAssembleTemplateResolve () {
  local commandNm="$1"
  declare -A targetMap
  PacketConvertToAssociativeMap "$2" 'targetMap'
  local -r template="`VirtDockerCmmdAssembleTemplate`"
  local -r DOCKER_FILE_NAMESPACE_LEN=${#DOCKER_FILE_NAMESPACE}
  local localVarPacketValue
  while read localVarPacketValue; do
    eval set -- $localVarPacketValue
    local -r $1="${targetMap["$2"]}"
  done < <( DockerCmmdAssembleTemplateResolvePacketField "$commandNm" )
  local dockerArgInstance
  local -r commandPrimaryName="`VirtDockerCmmdExecPrimaryName`"
  for dockerArgInstance in $template
  do
    if ! [ "${dockerArgInstance:0:DOCKER_FILE_NAMESPACE_LEN}" == "$DOCKER_FILE_NAMESPACE" ]; then continue; fi
    if [ -f "$PACKET_COMPONENT_PATH/${dockerArgInstance:1}" ]; then
      local dockerArgName="${dockerArgInstance:1}"
      eval $dockerArgName=\"\$$dockerArgName \`\c\a\t\ \<\ \"$PACKET_COMPONENT_PATH/$dockerArgName\"\`\"
    fi
  done
  local cmmdArgList
  eval cmmdArgList\=\"$template\"
  local dockerCmmd
  dockerCmmd="$commandPrimaryName $commandNm $cmmdArgList"
  echo "$dockerCmmd"
  return 0
}
###############################################################################
##
##  Purpose:
##    Exposes context information common to nearly all commands 
##    encapsulated by a packet (type "2", mentioned above) and provides a
##    virtual callback mechanism to define command specific ones.  
##
##  Input:
##    $1 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
##    VirtDockerCmmdAssembleTemplateResolvePacketField - A virtual callback
##         routine which when overriden defines additional command specific
##         bash variable name-value pairs for template resolution.
## 
##  Output:   
##    When Success:
##       SYSOUT - Each record contains the desired bash varialble name
##         seperated by whitespace from the packet field name that
##         refers to the desired field value to be assigned to the 
##         bash variable name.
##    When Failure: 
##      Issues an error messages written to SYSERR, then terminate the process.
##
###############################################################################
function DockerCmmdAssembleTemplateResolvePacketField () {
  local commandName="$1"
  echo 'PACKET_COMPONENT_PATH ComponentContextPath'
  echo 'PACKET_COMPONENT_NAME ComponentName'
  VirtDockerCmmdAssembleTemplateResolvePacketField "$commandName"
}
###############################################################################
VirtDockerCmmdAssembleTemplateResolvePacketField () {
  return 0
}
###############################################################################
##
##  Purpose:
##    Manages the execution of one or more fully formed Docker commands.  It
##    implements semantics common to all commands, such as the 'show' feature
##    that writes the Docker command to SYSOUT before its execution, and when
##    directed, performs a virtual function that's responsible to submit
##    the command to Docker Daemon.  Finally, once all the Docker commands have
##    been submitted and successfully executed, another virtual function 
##    is called to perform other clean up actions, like updating the 
##    Image GUID catalog after deleting Images from the
##    local Docker Repository.
##    
##  Assume:
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
##    $3 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
##    SYSIN - one or more formatted packets or "unrecognized messages" written
##         by an upstream process to this one's SYSIN.  "unrecognized messages"
##         are simply forwarded to SYSOUT.
## 
##  Output:
##    SYSOUT - Can represent the command itself and/or the SYSOUT messages 
##         generated by Docker Daemon while executing it.
##
###############################################################################
function DockerCmmdExecute () {
  local optsArgListNm="$1"
  local optsArgMapNm="$2"
  local commandNm="$3"
  local -r noExecuteCmmd="`AssociativeMapAssignIndirect "$optsArgMapNm" '--dlwno-exec'`"
  local -r showCmmd="`AssociativeMapAssignIndirect "$optsArgMapNm" '--dlwshow'`"
  local -r cmmdPacketFwd="`VirtDockerCmmdExecutePacketForward`"
  local target
  while read target; do
    PipeScriptNotifyAbort "$target"
    if ! PacketPreambleMatch "$target"; then
      echo "$target"
      continue
    fi
    declare -A targetMap
    PacketConvertToAssociativeMap "$target" 'targetMap'
    local dockerCmmd="${targetMap['DockerCommand']}"
    if [ -z "$dockerCmmd" ]; then
      # packet doesn't contain a Docker command :: forward it.
      echo "$target"
      continue
    fi
    if [ "$showCmmd" == 'true' ]; then
      # show requested :: print it to SYSOUT.
      echo "$dockerCmmd"
    elif [ "$showCmmd" == 'packet' ]; then
      # asking to see packet :: print it to SYSOUT.
      echo "$target"
    fi
    if ! $noExecuteCmmd; then
      # command execution requested.
      if $cmmdPacketFwd; then
        # Post processing of executed command requires command packet data
        echo "$target"
      fi
      if ! VirtDockerCmmdExecute "$optsArgListNm" "$optsArgMapNm" "$commandNm" 'targetMap' "$dockerCmmd"; then
        ScriptUnwind $LINENO "Command error for request: '$dockerCmmd', terminating execution of this and remaining commands."
      fi
    fi
  done
  # all Docker commands successfully executed, trigger any termination tasks.
  if ! VirtDockerCmmdExecuteAtCompletion "$optsArgListNm" "$optsArgMapNm" "$commandNm"; then
    ScriptUnwind $LINENO "Command completion function failed terminating execution of remaining pipeline."
  fi
  return 0
}
###############################################################################
function VirtDockerCmmdExecPrimaryName () {
  echo "docker"
  return 0
}
###############################################################################
function VirtDockerCmmdExecute () {
  local -r dockerCmmd="$5"
  # default implementation simply runs the Docker command and relies on Docker
  # Daemon to provide a meaningful message when the command fails.  Use eval to
  # properly parse command options.
  eval $dockerCmmd
  if [ "$?" -ne '0' ]; then return 1; fi
}
###############################################################################
function VirtDockerCmmdExecuteAtCompletion () {
  # default implementation simply does nothing.
  return 0;
}
###############################################################################
##
##  Purpose:
##    Certain Docker commands, like ps and image, require filtering
##    their captured output in order to limit their reporting scope.
##
##    This routine implements semantics common to all commands, as it simply
##    forwards output, for no execution requests.  In this situation,
##    there's no Docker command output to process.  However, important
##    content may still flow through the pipeline, like one or more
##    fully formed Docker commands.
##
##  Assume:
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
##    $3 - dlw command to execute. Maps 1 to 1 onto with Docker command line.
##    SYSIN - Output from the upstream pipeline.
## 
##  Output:     
##    SYSOUT - Potentially altered output form an executed Docker command.
##
###############################################################################
function DockerCmmdProcessOutput () {
  local optsArgListNm="$1"
  local optsArgMapNm="$2"
  local commandNm="$3"
  # only the commands themselves may flow through the pipe - there's no output to process
  local -r noExecDocker="`AssociativeMapAssignIndirect "$optsArgMapNm" '--dlwno-exec'`"
  if $noExecDocker; then
    PipeForwarder
  else
    VirtDockerCmmdProcessOutput "$optsArgListNm" "$optsArgMapNm" "$commandNm"
  fi
}
###############################################################################
function VirtDockerCmmdProcessOutput () {
  PipeForwarder
}
###############################################################################
##
##  Purpose:
##    Simply read SYSIN and forward to SYSOUT.
##
##  Input:
##    SYSIN - Anything piped to this routine
##
##  Output:
##    SYSOUT - Aything piped to this routine.
##
###############################################################################
function PipeForwarder (){
  local target
  while read target; do
    PipeScriptNotifyAbort "$target"
    echo "$target"
  done 
  return 0
}
FunctionOverrideIncludeGet
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
