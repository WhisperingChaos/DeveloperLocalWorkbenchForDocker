#!/bin/bash
###############################################################################
#
#  Purpose: 
#    Download and install the image to the Docker Daemon's local repository.
#
#  Assumes:
#    1.  Local Docker Daemon accessible via its usual socket.
#    2.  Created container tty will attach to current CLI terminal.
#    
#  Input:
#    $1 - dlw image tag name of desired dlw version.
#    $2 - Optional Daemon host directory that will 
#
#  Output:
#    When failure:
#      Either the error code from failed install process or rm failure code
#
###############################################################################
function helpText () {
cat <<COMMAND_HELP

Pull, create and run a new dlw container and connect it to Project files located
on the current host's file system. Pull occurs iff dlw isn't cached.

Usage: dlwRun.sh <HubTagName> [<ProjectDirectory>]

OPTIONS:
    <HubTagName>        Docker Hub Tag associated to desired dlw image.
                        dlw tag name concatenates: <dlw-version>_<DockerDaemon-version>
                        see: https://registry.hub.docker.com/u/whisperingchaos/dlw/tags/manage/
    <ProjectDirectory>  Existing host directory containing one or more
                        dlw Projects as subdirectories.

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
if [ -z "$1" ] || [ "$1" == "--help" ]; then helpText; exit 0; fi
if [ -z "$2" ]; then
  hostDirWarningText
  read -p "Confirm: Project files are local to the started container (Y/n):" -N 1 -- Yn
  if [ "$Yn" != 'Y' ]; then
    echo
    echo "Abort: Please specify an existing host directory as second argument.">&2
    exit 1;
  fi
  echo
  unset HOST_PROJECT_DIR
elif ! [ -d "$2" ]; then
  echo "Abort: Second argument doesn't resolve to an existing host directory: '$2'.">&2
  exit 1;
else
  HOST_PROJECT_DIR="-v $2:/home/dlw/project"
fi
# create a container to run dlw.  Container will attach to command line of current terminal's
docker run -i -t -v /var/run/docker.sock:/var/run/docker.sock $HOST_PROJECT_DIR -- whisperingchaos/dlw:$1
