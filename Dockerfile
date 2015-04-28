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
# Install desired installation packages.
RUN /usr/bin/scriptInstall/installPackages.sh 'lxc-docker' 'make' 'screen' \
    # Create the dlw non-root user to provide another level of isolation
    # within the containers spawned from this image.  Permit log in without
    # password.
    && adduser --disabled-password --gecos -- dlw \
    && passwd -d dlw  \
    # Associate dlw to docker group to enable dlw execution without specifying 'sudo'.
    && gpasswd -a dlw docker
# Install the dlw scripts into user level bin.
ADD ./script /usr/bin/dlw/
# Login
USER dlw
# Create a project directory for the dlw user to group projects and add
# the 'sample' project to aid users in understanding dlw as well as
# provide test scrpts
RUN mkdir -p '/home/dlw/project/sample/component'
# Copy files as root user because secondary account, in this case dlw, lacks
# permissions needed to access the source files in the build context copied
# and provided to docker's build command.
# Also, an attempt to execute the login proces via the ENTRYPOINT defined
# below will fail if the container is started by a non-root account.
USER root
# Incorporate dlw command alias to avoid typing '.sh' file file suffix and altering
# PATH variable.
ADD .bash_aliases /home/dlw/
# Establish dlw account as owner if its own aliases
RUN chown    dlw /home/dlw/.bash_aliases \
    # modify user's home directory to point to project area.
    && usermod --home /home/dlw/project -- dlw
# Create an entry point to automatically login dlw user.
# Login properly establishes /dev permissions and 
# sets correct home directory. 
ENTRYPOINT login dlw
