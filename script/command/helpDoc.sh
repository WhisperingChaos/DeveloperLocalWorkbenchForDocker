#!/bin/bash
source "MessageInclude.sh";
###############################################################################
##
##  Purpose:
##    Defines the list of commands supported by the dlw and provides a 
##    short description explaining the purpose for each one.  
##
##    Commands are classified as either: dlw specific ones, that is, dlw commands 
##    that have no Docker equivalent and dlw commands that wrap existing Docker
##    commands.   
##
##    The metadata encoded in this list, essentially the command name, is
##    queried by other scripts to, for example, verify user input.
##
##    Providing this help text as a separate file permits others to
##    easily replace or augment its contents.
##
##  Constraint:
##    The list of commands is immediately preceeded, without whitespace, by the
##    word "COMMAND:", starting in the first column and followed by End Of Line.
##    Each line of the command list begins with a command name, separated by
##    whitespace from its short description.  There are no empty lines
##    separating commands.  As mentioned above, there are two classes of 
##    commands and their order within this list determines their class. The
##    wrapped docker commands appear in the list before the dlw specific
##    commands and the dlw specific commands must follow the "section" labeled
##   'dlw specific:'.
##
##    Finally, the first detected blank line or no more lines signals the
##    termination of the entire command list.
## 
##  Input:
##    none
## 
##  Output:
##    SYSOUT - The command list with descriptions.
##
###############################################################################
function main () {
  cat <<COMMAND_HELP

Docker Local Workbench extends specific Docker commands incorporating
"Project" and "Component" abstractions within the local Docker environment.
Many dlw commands wrap existing Docker ones while some are dlw specific.

Usage: dlw COMMAND [ARG...]
 
COMMAND:
    attach    Using 'screen' command below, connect to an interactive container(s) derived from specified Component(s) & version.
    build     Compile a new version of a Component(s) from the resources located in its build context directory.
    create    Produce a container for the specified Component(s) but don't run it.
    diff      Inspect changes applied to container(s) derived from specified Component(s) & version.
    images    Generate a docker images report limited to the specified Component(s) & version.
    kill      Send a termination signal to containers derived from specified Component(s) & version.
    pause     Quiesce the running processes within container(s) derived from specified Component(s) & version.
    port      Generate the port mappings exposed by container(s) derived from specified Component(s) & version.
    ps        Generate a docker ps report limited to only the specified Component(s) & version.
    restart   Send the restart signal to container(s) derived from specified Component(s) & version.
    rm        Remove container(s) derived from specified Component(s) & version.
    rmi       Remove image(s) associated to specified Component(s) & version including their associated containers.
    run       Create & run a image(s) associated to specified Component(s) & version.
    start     Start a stopped container derived from specified Component(s) & version. 
    stop      Start a stopped container derived from specified Component(s) & version.
    top       Display running process of a container derived from specified Component(s) & version.
    unpause   Resume paused container(s) derived from specified Component(s) & version.
dlw specific:
    help      Display a list of commands or the command syntax of a specific command
    itest     Run dlw integration tests using 'sample' project.
    screen    Redirect each generated Docker command to its own terminal window.
    version   Display the version of this command processor.
    watch     Execute a dlw command in a linux watch terminal.

Specify: 'help COMMAND' to display [ARG...] help for that command.

For more help: https://github.com/WhisperingChaos/DockerLocalWorkbench#toc

COMMAND_HELP
  return 0
}
FunctionOverrideCommandGet
main
