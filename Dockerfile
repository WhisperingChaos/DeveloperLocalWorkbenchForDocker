###############################################################################
#
# Purpose: Construct a debug version of the Basic Interface so we can
# interact with it while debugging.
#
##############################################################################

FROM	   ubuntu:12.04
MAINTAINER Richard Moyse <Rich@Moyse.US>

RUN apt-get update; \
    # Install secure protocol to enable secure package updates.
    apt-get install -y apt-transport-https; \
    # Install docker package key and distribution directory.
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9; \
    sh -c "echo deb https://get.docker.com/ubuntu docker main > /etc/apt/sources.list.d/docker.list"; \
    apt-get update; \
    # Load specific version of docker client.  When docker client connects to its server
    # both client and server rest protocol versions must be identical.
    apt-get install -y lxc-docker-1.3.3; \
    # Load make version required by dlw to manage component dependencies.
    apt-get install -y make=3.81-8.1ubuntu1.1; \
    # Load screen version required by dlw to manage windowing and simultaneously attaching
    # to container ttys.
    apt-get install -y screen=4.0.3-14ubuntu8; \
    # Create the dlw non-root user to provide another level of isolation
    # within the containers spawned from this image.  Permit log in without
    # password.
    adduser --disabled-password --gecos -- dlw; \
    passwd -d dlw; \
    # Associate dlw to docker group to enable dlw execution without specifying 'sudo'.
    gpasswd -a dlw docker;
# Install the dlw scripts into user level bin.
ADD ./script /usr/bin/dlw/
# Login
USER dlw
# Create a project directory for the dlw user to group projects and add
# the 'sample' project to aid users in understanding dlw as well as
# provide test scrpts  
RUN mkdir -p '/home/dlw/project/sample/component' ;
# Copy files as root user because secondary account, in this case dlw, lacks
# permissions needed to access the source files in the build context copied
# and provided to docker's build command.
# Also, an attempt to execute the login proces via the ENTRYPOINT defined
# below will fail if the container is started by a non-root account.
USER root
# Incorporate dlw command alias to avoid typing '.sh' file file suffix and altering
# PATH variable.
ADD .bash_aliases /home/dlw/

RUN chown    dlw /home/dlw/.bash_aliases;
# Create an entry point to automatically login dlw user.
# Login properly establishes /dev permissions and 
# sets correct home directory. 
ENTRYPOINT login dlw
