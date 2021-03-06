###############################################################################
##
##    Section: Abstract Interface:
##      Defines an abstract interface for the compliation of a command
##      that isn't specialized by a Target.
##
###############################################################################
##
###############################################################################
##
##  Purpose:
##    Produce command text for a dlw command, like 'images' that generates
##    a single resulting command that isn't differenciated by any targets.
##
##  Assume:
##    Since bash variable names are passed to this routine, these names
##    cannot overlap the variable names locally declared within the
##    scope of this routine or its decendents.
##
##  Input:
##    $1  - Variable name to an associative array whose key is either the
##          option or argument label and whose value represents the value
##          associated to that label.
##    $2  - Command name.
##    $3  - Command's optional arguments.
##
##  Output:
##    SYSOUT - The entire properly formatted command
##
###############################################################################
function VirtDockerCmmdAssembleSingle () {
  ScriptUnwind $LINENO "Please override: $FUNCNAME".
}
###############################################################################
##
##    Section: Implementation:
##      Defines common implementation for functions required by all
##      non specific commands.
##
###############################################################################
##
###############################################################################
##
##  Purpose:
##    When generating command options, only include those specified by
##    command line, as options, specified for specific target, are irrational.
##
###############################################################################
function VirtDockerCmmdAssemble () {
  local optsArgListNm="$1"
  local optsArgMapNm="$2"
  local commandNm="$3"
  # forward all SYSOUT generated so far to next pipeline step.
  PipeForwarder
  local -a optDockerList
  local -A optDockerMap
  local -r DOCKER_FILE_NAMESPACE='$DOCKER_CMMDLINE_'
  if ! OptionsArgsFilter "$optsArgListNm" "$optsArgMapNm" 'optDockerList' 'optDockerMap'  '( [[ "$optArg"  =~ ^-[^-].*$ ]] || [[ "$optArg"  =~ ^--.*$ ]] ) && ! [[ "$optArg"  =~ ^--dlw.*$ ]]' 'true'; then
    ScriptUnwind $LINENO "Failure while extracting Docker command line options."
  fi
  local temp="`OptionsArgsGen 'optDockerList' 'optDockerMap'`"
  eval local ${DOCKER_FILE_NAMESPACE:1}OPTION\=\"\`OptionsArgsGen \'optDockerList\'\ \'optDockerMap\'\`\"
  local dockerCmmd="`VirtDockerCmmdAssembleSingle  "$optsArgMapNm" "$commandNm" "$DOCKER_CMMDLINE_OPTION"`"
  local packetCmmd
  PacketCreateFromStrings 'DockerCommand' "$dockerCmmd" 'packetCmmd'
  echo "$packetCmmd"
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
