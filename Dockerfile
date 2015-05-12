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
# Install desired packages.
RUN /usr/bin/scriptInstall/installPackages.sh 'lxc-docker' 'make' 'tmux' \
    # Create the dlw non-root user to provide another level of isolation
    # within the containers spawned from this image.
    && /usr/bin/scriptInstall/installUsers.sh 'dlw' \
    # make install helper scripts invisible from this layer forward
    && rm -f -r "/usr/bin/scriptInstall"
# Install the dlw scripts into user level bin.
ADD ./script /usr/bin/dlw/
# Copy files as root user because secondary account, in this case dlw, lacks
# permissions needed to access the source files in the build context copied
# and provided to docker's build command.
# Also, an attempt to execute the login proces via the ENTRYPOINT defined
# below will fail if the container is started by a non-root account.
# Incorporate dlw command alias to avoid typing '.sh' file suffix and altering
# PATH variable.
ADD .bash_aliases /home/dlw/
# Create a project directory for the dlw user to group projects and add
# the 'sample' Project to provide testbed. 
# Establish dlw account as owner if its own files.
RUN mkdir -p '/home/dlw/project/sample/component' \
    && chown -R dlw /home/dlw   \
    && chown -R dlw /home/dlw/* 
# Create an entry point to automatically login dlw user.
# Login properly establishes /dev permissions and 
# sets correct home directory. 
ENTRYPOINT login dlw
# Provide a means to debug socket assignments if necessary
# RUN apt-get install -y lsof
