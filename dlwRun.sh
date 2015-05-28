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

For more help: https://github.com/WhisperingChaos/DockerLocalWorkbench#ToC

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
OPTIND=1
unset HOST_PROJECT_DIR
unset HOST_TMUX_DIR
while getopts 'h?p:t:' opt; do
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
        HOST_PROJECT_DIR="-v $HOST_PROJECT_DIR:/home/dlw/project"
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
        HOST_TMUX_DIR="-v $HOST_TMUX_DIR:/home/dlw/.tmuxconfdir"
        ;;
    esac
done

shift $((OPTIND-1))

declare DLW_TAG='latest_latest'
if [ -n "$1" ]; then
  DLW_TAG="$1"
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
docker run -i -t -v /var/run/docker.sock:/var/run/docker.sock $HOST_PROJECT_DIR $HOST_TMUX_DIR -- dlw:$DLW_TAG # whisperingchaos/dlw:$DLW_TAG
