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
if [ -z "$1" ]; then
  echo "Abort: must specify desired dlw Docker Hub tag name.">&2
  exit 1;
fi
if [ -z "$2" ]; then
  echo
  echo  'Warning!'
  echo
  echo "Host directory unspecified.  All project files will be located within the started container."
  echo "To continue developing code projects within this container, you must find and start"
  echo "this container. This script cannot start an existing container, it only creates a"
  echo "new one from the downloaded dlw image."
  echo
  read -p "Confirm: Project files are local to the started container (Y/n):" -N 1 -- Yn
  if [ "$Yn" != 'Y' ]; then
    echo
    echo "Abort: Please specify an existing host directory as second argument.">&2
    exit 1;
  fi
  unset HOST_PROJECT_DIR
elif ! [ -d "$2" ]; then
  echo "Abort: Second argument doesn't resolve to an existing host directory: '$2'.">&2
  exit 1;
else
  HOST_PROJECT_DIR="-v $2:/home/dlw/project"
fi
# create a container to run dlw.  Container will attach to command line of current terminal's
docker run -i -t -v /var/run/docker.sock:/var/run/docker.sock $HOST_PROJECT_DIR -- whisperingchaos/dlw:$1
