#!/bin/bash
###############################################################################
#
#  Purpose: 
#    Download and install the desired 'dlw' image to the Docker Daemon's
#    local repository and bind host project and tmux configuration directories
#    to container when desired.
#
#  Assumes:
#    1.  Local Docker Daemon accessible via its usual socket.
#    2.  Created container tty will attach to current CLI terminal.
#    
###############################################################################
function helpText () {
cat <<COMMAND_HELP

Pull, create and run a new dlw container and connect it to Project files located
on the current host's file system. Pull occurs iff dlw isn't cached.

Usage: dlwRun.sh [OPTIONS] [HUB_TAG_NAME]


    HUB_TAG_NAME   Docker Hub Tag associated to desired dlw image.
                   dlw tag name concatenates: <dlw-version>_<DockerDaemon-version>.
                   If omitted, tag name assigned 'latest_latest'
                   see: https://registry.hub.docker.com/u/whisperingchaos/dlw/tags/manage/
                    
OPTIONS:

    -p             Existing host directory containing one or more dlw Projects as
                   subdirectories.  If omitted, Projects are stored in container.

    -t             Existing host directory containing the '.tmux.conf' file. If omitted
                   tmux provides its own default settings.

    -u {'ASSUME'|<UID>|'CONTAIN'}
                   External account UID that will replace the container's 'dlw'
                   account's UID.  This permits processes within the container
                   to access host directories/files mounted using 'docker run|create'
                   volume (-v) option, using rudementary Linux DAC.
                     'ASSUME'  - Use the UID that started this script. (default)
                     <UID>     - Numeric linux User Identifer.
                     'CONTAIN' - Don't alter 'dlw' container UID.

    -g {'ASSUME'|'<GID> ...'|'CONTAIN'}
                   GID list that will augment the container's 'dlw' account's GID list.
                   This permits processes within the container to access host
                   directories/files mounted using 'docker run|create' 
                   volume (-v) option, using rudementary Linux DAC.  The first GID becomes
                   the 'dlw' account's primary GID.
                     'ASSUME'  - Use the GID list associated to the UID that started this script. (default)
                     <GID>     - Numeric linux Group Identifer.
                     'CONTAIN' - Don't alter 'dlw' container account GID list.
    
    -l             Treat HUB_TAG_NAME as complete local repository image name.

For more help: https://github.com/WhisperingChaos/DeveloperLocalWorkbenchForDocker#ToC

COMMAND_HELP
}
###############################################################################
function hostDirWarningText () {
cat <<HOST_DIR_WARN

  Warning!

  Host directory unspecified.  All project files will be located within the started container.
  To continue developing Projects within this container, you must find and restart it.
  This script doesn't restart an existing container, it only creates new ones from
  the downloaded dlw image.
  
HOST_DIR_WARN
}
###############################################################################
#
#  Purpose:
#    Generate GID list for user running this script.
# 
#  Outputs:
#    STDOUT - Space separated list of GIDs assigned to account running this script.
#
###############################################################################
function GID_list_gen (){
  declare GID_name
  declare GID_list
  for GID_name in $( groups )
  do
    GID="`getent group "$GID_name" | cut -d: -f3`"
    if [ -z "$GID" ]; then Abort "$LINENO" "Failed to generate GID for group name: '$GID_name' associated to: '$USER'."; fi
    GID_list+="$GID "
  done
  echo "$GID_list"
}
###############################################################################
#
#  Purpose:
#    Verify value of UID/GID options.
# 
#  Inputs:
#    1.  $1 - UID/GID option value.
#
###############################################################################
function ID_verify () {
  if [ "$1" != 'ASSUME' ] && ! [[ $1 =~ ^[0-9\ ]+$ ]] && [ "$1" != 'CONTAIN' ]; then
    return 1
  fi
  return 0
}
###############################################################################
# main
###############################################################################
  OPTIND=1
  unset HOST_PROJECT_DIR
  unset HOST_TMUX_DIR
  declare ASSUME_UID='ASSUME'
  declare ASSUME_GID_LIST='ASSUME'
  declare TREAT_LOCAL_REPOSITORY_NAME='false'
  while getopts 'h?p:t:u:g:l' opt; do
      case "$opt" in
      h|\?)
          helpText
          exit 0
          ;;
      p)  declare HOST_PROJECT_DIR="$OPTARG"
          if ! [ -d "$HOST_PROJECT_DIR" ]; then
            echo "Abort: -p option doesn't resolve to an existing host directory: '$HOST_PROJECT_DIR'.">&2
            exit 1
          fi
          HOST_PROJECT_DIR="-v '$HOST_PROJECT_DIR:/home/dlw/project'"
          ;;
      t)  declare HOST_TMUX_DIR="$OPTARG"
          if ! [ -d "$HOST_TMUX_DIR" ]; then
            echo "Abort: -t option doesn't resolve to an existing host directory: '$HOST_TMUX_DIR'.">&2
            exit 1
          fi
          if ! [ -e "$HOST_TMUX_DIR/.tmux.conf" ]; then
            echo "Abort: -t option host directory: '$HOST_TMUX_DIR', doesn't contain: '.tmux.conf'.">&2
            exit 1
          fi
          HOST_TMUX_DIR="-v '$HOST_TMUX_DIR:/home/dlw/.tmuxconfdir'"
          ;;
      u)  ASSUME_UID="$OPTARG"
          ;;
      g)  ASSUME_GID_LIST="$OPTARG"
          ;;
      l)  TREAT_LOCAL_REPOSITORY_NAME='true'
          ;;
      esac
  done

  if ! ID_verify "$ASSUME_UID"; then
    echo "Abort: Specified -u option value invalid: '$ASSUME_UID'.">&2
    exit 1
  fi

  if [ "$ASSUME_UID" == 'ASSUME' ]; then
    ASSUME_UID="--env \"ASSUME_UID=`id -u`\""
  elif [ "$ASSUME_UID" == 'CONTAIN' ]; then
    unset ASSUME_UID
  else
    ASSUME_UID="-e \"ASSUME_UID=$ASSUME_UID\""
  fi

  if ! ID_verify "$ASSUME_GID_LIST"; then
    echo "Abort: Specified -g option value invalid: '$ASSUME_GID_LIST'.">&2
    exit 1
  fi

  if [ "$ASSUME_GID_LIST" == 'ASSUME' ]; then
    ASSUME_GID_LIST="--env \"ASSUME_GID_LIST=`GID_list_gen`\""
  elif [ "$ASSUME_GID_LIST" == 'CONTAIN' ]; then
    unset ASSUME_GID_LIST
  else
    ASSUME_GID_LIST="-e \"ASSUME_GID_LIST=$ASSUME_GID_LIST\""
  fi

  shift $((OPTIND-1))
  declare DLW_TAG='latest_latest'
  if [ -n "$1" ]; then
   DLW_TAG="$1"
  fi
  if ! $TREAT_LOCAL_REPOSITORY_NAME; then
    DLW_TAG="whisperingchaos/dlw:$DLW_TAG"
  fi

  if [ -z "$HOST_PROJECT_DIR" ]; then
    hostDirWarningText
    read -p "Confirm: Project files are local to the started container (Y/n):" -N 1 -- Yn
    if [ "$Yn" != 'Y' ]; then
      echo
      echo "Abort: Please specify an existing host directory as second argument.">&2
      exit 1;
    fi
    echo
  fi
  # create a container to run dlw.  Container will attach to current terminal
  eval docker run \-\i \-\t \-\v \'/var/run/docker.sock:/var/run/docker.sock\' $HOST_PROJECT_DIR $HOST_TMUX_DIR $ASSUME_UID $ASSUME_GID_LIST -- $DLW_TAG
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
