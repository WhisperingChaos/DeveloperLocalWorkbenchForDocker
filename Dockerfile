###############################################################################
#
# Purpose: Construct an image containing the Docker Local Workbench (dlw)
#          and its dependent tools.
#
##############################################################################
FROM	   ubuntu:12.04
MAINTAINER Richard Moyse <Rich@Moyse.US>
# Install helper scripts to improve declarative benefit of package installs.
ADD ./scriptInstall/* /usr/bin/scriptInstall/
# Incorporate dlw command alias to avoid typing '.sh' file suffix and altering
# PATH variable.
ADD .bash_aliases /usr/bin/scriptInstall/
# Install desired packages.
RUN /usr/bin/scriptInstall/installPackages.sh 'lxc-docker' 'make' 'tmux' \
    # Create the dlw non-root user to provide another level of isolation
    # within the containers spawned from this image.
    && /usr/bin/scriptInstall/installUsers.sh 'dlw' \
    # Patch login process so dlw account can assume an external 
    # account's UID and GID list.
    && mv /usr/bin/scriptInstall/dlwLogin.sh /usr/sbin/ \
    && mv /usr/bin/scriptInstall/userUID_GID_Reassign.sh /usr/sbin/ \
    # Create a project directory for the dlw user to group projects and add
    # the 'sample' Project Catalog structure to provide testbed. 
    && mkdir -p '/home/dlw/project/sample/component' \
    # Create a link spot for the tmux.conf file.  The file is empty so it
    # assumes the tmux defaults.  This empty file can be overridden using
    # volume option (-v) to incorporate desired tmux.conf from host. 
    && mkdir '/home/dlw/.tmuxconfdir' \
    && touch '/home/dlw/.tmuxconfdir/.tmux.conf' \
    && ln -s '/home/dlw/.tmuxconfdir/.tmux.conf' '/home/dlw/.tmux.conf' \
    && mv /usr/bin/scriptInstall/.bash_aliases /home/dlw/ \
    # Establish dlw account as owner if its own files. This avoids creating
    # additional layers in order to set USER.
    && chown -R dlw /home/dlw/* \ 
    # make install helper scripts invisible from this layer forward
    && rm -f -r "/usr/bin/scriptInstall"
# Create an entry point to automatically login dlw user.
# Login properly establishes /dev permissions and 
# sets correct home directory. 
# Also, must use root level priviledges when establishing login proces
# via the ENTRYPOINT command. 'login' below will fail if the container
# is started by a non-root account.
ENTRYPOINT dlwLogin.sh
# Install the dlw scripts into user level bin.  Located here, at the end,
# as these frequently change during development.
ADD ./script /usr/bin/dlw/
# Provide a means to debug socket assignments if necessary
# RUN apt-get install -y lsof
