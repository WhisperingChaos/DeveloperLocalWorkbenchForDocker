###############################################################################
#
#  Purpose
#    Automate the construction, update, and removal of statically dependent
#    docker images, including their associated containers, within the scope
#    of a local docker daemon.  A statically dependent docker image relies
#    on components (packages/features) provided by a base image during its
#    construction via a docker build command ([see FROM](http://docs.docker.io/reference/builder/#from)).
#    A dependent image is analogous to a derived class, in languages such
#    as C++, Java, ... which inherits from a particular base class. 
#
#  Reasoning
#    Although docker provides a Trusted Build system and GitHub integration
#    that conceptually provide this functionality, some may adopt this makefile
#    approach to:
#    > Maintain a level of privacy, as Trusted Builds currently operate on
#      docker's public index/repository.
#    > Avoid implementing a private registry and Trusted Build cluster, especially
#      for small projects.
#    > Potentially improve the responsiveness of the development cycle, as the
#      build process runs locally,  especially, in situations when the public
#      Trusted Build cluster performance slows due to congestion of build
#      requests or network connectivity issues.
#    > Verify the successful construction of statically dependent containers
#      before committing them to the public index/registry.
#    > Easily delete all the containers associated to a given image version.
#    > Delete all docker image versions for a given image name.
#
#  Additional information can be found in the README.md file.
#
###############################################################################
# Ensure that the shell has been defined as bash, as a number of
# bash only shell scrit features are empolyed.
SHELL := /bin/bash
# Assert Project Directory context has been specified.  The Project Directory
# generally encapsulates all the various objects required by this makefile.  
ifndef PROJECT_DIR
  $(error Command context did not specify PROJECT_DIR)
endif
# Assert Image Catalog context has been specified.  The Image Catalog contains
# all the Image GUID Lists for every Component known to the project.
ifndef IMAGE_CAT_DIR
  $(error Command context did not specify IMAGE_CAT_DIR)
endif
# Assert Image Build Timestamp context has been specified.  The Image Catalog contains
# all the Image GUID Lists for every Component known to the project.
ifndef IMAGE_BUILD_TIMESTAMP_DIR
  $(error Command context did not specify IMAGE_BUILD_TIMESTAMP_DIR)
endif
# Assert the Component Catalog context has been specified.  This Catalog
# implemented as a directory encapsulates all Project's Components,
# including their resources and specific command context information.
ifndef COMPONENT_CAT_DIR
  $(error Command context did not specify COMPONENT_CAT_DIR)
endif
# Assert the current command has been specified.  It identifies the
# context directory that should be used when assembling the docker command.
ifndef COMMAND_CURRENT
  $(error Must specify current command when running make: COMMAND_CURRENT=[images|build|run|...])
endif
# Implement mechanism to map one command context onto another.  The create create & run
# commands examplify a situation where one command is really an aggregrate of another,
# in this situation 'run' executes both a 'create' and 'start' operation, therefore,
# 'create' & 'run' share nearly the same set of options. 
# TODO: at some point suport a 'merge' of contexts instead of a simple
# replacement of them.

# Assert the current command has been specified.  It identifies the
# context directory that should be used when assembling the docker command.
ifdef COMMAND_CURRENT_MAP
  $(error Command mapping will fail because variable name:COMMAND_CURRENT_MAP is probably read only as it was externally defined in another shell.)
endif
ifeq ($(COMMAND_CURRENT),create)
  COMMAND_CURRENT_MAP := run
else
  COMMAND_CURRENT_MAP := $(COMMAND_CURRENT)
endif
# Assert the Dependency file name has been specified.  It may or may not exist
# as a file in the file system.  It describes the Component dependency graph
# to be used by each command.
ifndef COMPONENT_CAT_DEPENDENCY
  $(error Command context did not specify COMPONENT_CAT_DEPENDENCY)
endif
###############################################################################
##
##    Section: 'build' Command Adhering to Dependency Processing
##
###############################################################################
#
# This section encompasses makefile rules that process targets (Components)
# according to the dependency tree specified in the "Dependency" file.
# A reference to include "Dependency" appears near the bottom of this makefile.
#
# The macro below automatically computes the list of Components belonging
# to the current Project in order to facilitate a 'build' request.  A
# Component must exist as a visible (not hidden) subdirectory and a
# specific Component must have a corresponding 'build' subdirectory.
# This subdirectory must contain all the resources required by the
# Dockerfile to construct the Component. 
COMPONENT_BUILD_LST:=$(shell 'makefileFunExtend.sh' 'ContextTargetGen' "$(COMPONENT_CAT_DIR)" "$(COMPONENT_CAT_DIR)/<ComponentName>/context/build" '.build' )
componentBuildLst: $(COMPONENT_BUILD_LST)
# Direct make to search for files implementing Image BUILD Timestamps.
vpath %.build $(IMAGE_BUILD_TIMESTAMP_DIR)
# The following rule determines if the static context for a Component is newer than
# its Image build file.  If so, it generates a packet of data used to
# manage the Image GUID List, identify the Component, and the Component's command
# context needed by other routines that generate docker command(s) and update the
# Image GUID List when appropriate.
# NOTE - Besides 'build' all other commands that currently employ a build
# dependency tree, like 'ps', 'images', rmi, ... also use this rule.  For these other
# rules, the '--always-build' make option is specified to produce the dependency list
# regardless of the date/time stamp of files in the Command's context directory.
# Finally, defining 'COMP_NAME_ONLY' bypasses packet generation
# and simply writes the Component names to SYSOUT.
#
# Note - secondary expansion of the rule is required in order to substitute '%' below
# for its, stem, component name, within the shell call.  It's necessary to
# call the DirectoryRecurse function so all files in the build context are included
# as prerequsites for the component's build.
# 
.SECONDEXPANSION:
%.build: $$(shell 'makefileFunExtend.sh' 'DirectoryRecurse' "$$(COMPONENT_CAT_DIR)/%/context/build" )
ifndef COMP_NAME_ONLY
	@source 'PacketIncludeMakefile.sh'; \
	PacketCreateFromStrings 'ComponentContextPath' "$(COMPONENT_CAT_DIR)/$*/context/$(COMMAND_CURRENT_MAP)" 'ComponentName' "$*" 'ImageGUIDFileName' "$(IMAGE_CAT_DIR)/$*.GUIDlist" 'packet'; \
	echo "$$packet"
else
	echo "$*"
endif

# As above, this translates the pseudo target '<command>', so it
# iterates over every known Component in order of their
# build dependencies.  This list is used in conjunction with 
# COMP_NAME_ONLY to generate a list of only Component names
# so command line arguments can be verified.
#
build diff images ps rm rmi: componentBuildLst
	@
# These commands: 'rm', 'ps', 'rmi', and 'images' currently share
# build dependencies of the 'build' command.  The next three sets of 
# rules simply translate targets for these commands to the appropriate
# build target.
#
# Translate the pseudo target of 'all.build', so it iterates over every
# known Component in order of their build dependencies.
all.build: componentBuildLst
	@
# The rules below translate a specifically targeted Component (including 'all') to 
# its corresponding build target.
%.diff  : %.build
	@
%.images: %.build
	@
%.ps:     %.build
	@
%.rm:     %.build
	@
%.rmi:    %.build
	@

# The rule below provides a target that terminates the any %.build when the build
# context directory is empty.  This is needed during prerequiste generation 
# in order to issue a failure as a non zero return code by this process doesn't
# result in a make failure that stops the build or any other command mapped to
# build from executing.
BuildContextEmpty :
	@exit 1
	
###############################################################################
##
##    Section: 'build' Command Ignoring Dependency Processing
##
###############################################################################
#
# This section encompasses makefile rules that process targets (Components)
# ignoring/without their dependency tree.  These rules are not expected to
# be very helpful for specifically 'build'.  However, the other commands that
# rely on build's dependency tree, like 'image' will, by default, ignore
# dependencies.  Also, in the specific case of build, the rule processing
# below can be used to identify only those Components whose docker
# build context have actually changed.
# 
# The macro below automatically computes the list of Components belonging
# to the current Project in order to facilitate a 'build' no dependency
# request.  Analogous to COMPONENT_BUILD_LST.
COMPONENT_BUILD_NODEP_LST:=$(shell 'makefileFunExtend.sh' 'ContextTargetGen' "$(COMPONENT_CAT_DIR)" "$(COMPONENT_CAT_DIR)/<ComponentName>/context/build" '.build.nodep' )
componentBuildNodepLst: $(COMPONENT_BUILD_NODEP_LST)
# For all command requests escewing a specific Component's (runtime, build, ...)
# dependency tree, generate a packet for only the identified Component.
ifeq ($(BUILD_FORCED),false)
define testPrecondition
'makefileFunExtend.sh' 'TimeStampTripIs' "$(IMAGE_CAT_DIR)/$*.build" "$(COMPONENT_CAT_DIR)/$*/context/build"; echo $$?;
endef
else
define testPrecondition
echo 1;
endef
endif

define makeTargetNoDepGeneric
@if [ "$(BUILD_FORCED)" == 'false' ] && [ "$(TRIPPED)" -eq '0' ]; then echo "make: \`$@\' is up to date."; exit 0; fi;\
source 'PacketIncludeMakefile.sh';\
COMPONENT_NAME="$*";\
PacketCreateFromStrings 'ComponentContextPath' "$(COMPONENT_CAT_DIR)/$$COMPONENT_NAME/context/$(COMMAND_CURRENT_MAP)" 'ComponentName' "$$COMPONENT_NAME" 'ImageGUIDFileName' "$(IMAGE_CAT_DIR)/$${COMPONENT_NAME}.GUIDlist" 'packet';\
echo "$$packet"
endef
# Processes a given specific Component escewing a specific Component's
# dependency tree.
%.build.nodep: TRIPPED = $(shell $(testPrecondition))
%.build.nodep:
	$(makeTargetNoDepGeneric)

# Iterates over all Components escewing each Component's
# dependency tree.
all.build.nodep: componentBuildNodepLst
	@
%.attach.nodep:  %.build.nodep
	@
%.create.nodep:  %.build.nodep
	@
%.diff.nodep:    %.build.nodep
	@
%.images.nodep:  %.build.nodep
	@
%.kill.nodep:    %.build.nodep
	@
%.pause.nodep:   %.build.nodep
	@
%.port.nodep:    %.build.nodep
	@
%.ps.nodep:      %.build.nodep
	@
%.restart.nodep: %.build.nodep
	@
%.rm.nodep:      %.build.nodep
	@
%.rmi.nodep:     %.build.nodep
	@
%.run.nodep:     %.build.nodep
	@
%.start.nodep:   %.build.nodep
	@
%.stop.nodep:    %.build.nodep
	@
%.top.nodep:     %.build.nodep
	@
%.unpause.nodep: %.build.nodep
	@

###############################################################################
##
##    Section: 'run' Command Adhering to Dependency Processing
##
###############################################################################
#
# This section encompasses makefile rules that process targets (Components)
# according to the dependency tree specified in the "Dependency" file.
# A reference to include "Dependency" appears near the bottom of this makefile.
#
#
# The macro below automatically computes the list of Components belonging
# to the current Project in order to facilitate a 'run' request.  A
# Component must exist as a visible (not hidden) subdirectory and a
# specific Component must have a corresponding 'build' subdirectory.
# This subdirectory must contain all the resources required by the
# Dockerfile to construct the Component. 
COMPONENT_RUN_LST:=$(shell 'makefileFunExtend.sh' 'ContextTargetGen' "$(COMPONENT_CAT_DIR)" "$(COMPONENT_CAT_DIR)/<ComponentName>/context/run" '.run' )
componentRunLst: $(COMPONENT_RUN_LST)
%.run:
ifndef COMP_NAME_ONLY
	@source 'PacketIncludeMakefile.sh'; \
	PacketCreateFromStrings 'ComponentContextPath' "$(COMPONENT_CAT_DIR)/$(*F)/context/$(COMMAND_CURRENT_MAP)" 'ComponentName' "$*" 'ImageGUIDFileName' "$(IMAGE_CAT_DIR)/$*.GUIDlist" 'packet'; \
	echo "$$packet"
else
	@echo "$*"
endif
 
attach create kill pause port restart run start stop top unpause: componentRunLst
	@

# These commands (start, stop, restart,...) share runtime dependencies of the '%.run' command.
all.run: componentRunLst
	@
%.attach:  %.run
	@
%.create:  %.run
	@
%.kill:    %.run
	@
%.pause:   %.run
	@
%.port:    %.run
	@
%.restart: %.run
	@
%.start:   %.run
	@
%.stop:    %.run
	@
%.top:     %.run
	@
%.unpause: %.run
	@

###############################################################################
##
##    Section: 'build' Command Ignoring Dependency Processing
##
###############################################################################
#
# The macro below automatically computes the list of Components belonging
# to the current Project in order to facilitate a 'run' no dependency
# request.  Analogous to COMPONENT_BUILD_NODEP_LST.
COMPONENT_RUN_NODEP_LST:=$(shell 'makefileFunExtend.sh' 'ContextTargetGen' "$(COMPONENT_CAT_DIR)" "$(COMPONENT_CAT_DIR)/<ComponentName>/context/run" '.run.nodep' )
componentRunNodepLst: $(COMPONENT_RUN_NODEP_LST)
# These commands (start, stop, restart,...) share runtime dependencies of the '%.run' command.
# Translate a request to perform a command over all Components
# without regarding dependencies into one that uses the dependency list and
# notion of a 'forced' make to generate this list
all.run.nodep: componentRunNodepLst
	@
all.attach.nodep:  all.run.nodep
	@
all.create.nodep:  all.run.nodep 
	@
all.kill.nodep:    all.run.nodep
	@
all.pause.nodep:   all.run.nodep
	@
all.port.nodep:    all.run.nodep
	@
all.restart.nodep: all.run.nodep
	@
all.start.nodep:   all.run.nodep
	@
all.stop.nodep:    all.run.nodep
	@
all.top.nodep:     all.run.nodep
	@
all.upause.nodep:  all.run.nodep
	@
# Customize this makefile by placing all rules defining prerequisites 
# in a file named "Dependency".  This "Dependency" file separates the
# configurable concerns of defining the dependencies from this makefile
# which contains typically static rules and supporting macros/functions.
-include $(COMPONENT_CAT_DEPENDENCY)
###############################################################################
#
# The MIT License (MIT)
# Copyright (c) 2014 Richard Moyse License@Moyse.US
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
