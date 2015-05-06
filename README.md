### Building, Running, & Reporting on Image/Container Pods

##### ToC  

[Purpose](#purpose)  
[How Does It Work](#how-does-it-work)  
[Features](#features)  
[Installing](#installing)  
&nbsp;&nbsp;&nbsp;&nbsp;[Pulling Image](#installing-pulling-image)  
&nbsp;&nbsp;&nbsp;&nbsp;[Sample Project & Testing](#installing-sample-project--testing)  
[Project Tutorial](#project-tutorial)  
[Exploring Commands](#exploring-commands)  
[Declaring Dependencies](#declaring-dependencies)  
[Concepts](#concepts)  
[What's Provided](#whats-provided)  
[License](#license)  

### Purpose

To facilitate the development of cooperative multicontainer services by extending core Docker CLI commands to operate on related groups of images/containers managed by the local Docker Daemon.  Facilitation embodies a desire to accelerate the iterative development loop through the efficiency of local file and computing resources, thereby, avoiding the network and service contention delays inherent to remote web interfaces.

Although docker provides [Compose](https://docs.docker.com/compose/), a Trusted Build cluster, and GitHub integration that conceptually provide this functionality, some may adopt this tool to:
+ Avoid implementing a private registry and Trusted Build cluster, especially for small projects.
+ Potentially improve the responsiveness of the development cycle, as all Docker commands are executed by the local Docker Daemon, especially, in situations when the public Trusted Build cluster performance slows due to congestion of build requests or network connectivity issues.
+ Verify the construction of statically dependent images and execution of cooperative containers before committing them to the public index/registry.
+ Maintain a level of "free privacy", as Trusted Builds currently operate on docker's public index/repository and multiple private repositories incurr a monthly fee.

### Features

+ Use simple commands like ```dlw build```,```dlw run```, and ```dlw images``` to manage and report on an service composed from multiple cooperating containers.
+ Launch and concurrently attach to the terminal interfaces of multiple containers using the terminal multiplex feature of [GNU screen](http://www.gnu.org/software/screen/).
+ Combined GNU screen, [linux watch](http://en.wikipedia.org/wiki/Watch_%28Unix%29) and reporting commands like 'top' and 'ps' to actively monitor the status of multiple containers.
+ Generate Docker CLI stream from command line arguments stored in a file, using a rudimentry command template.
+ Enhance report generation by associating custom properties to a docker image. 
+ Track previous versions of docker images and with single command remove all prior versions and their associated containers, ordering their removal to avoid "Conflict" errors issued by the Docker Daemon.
+ Enjoy the benefits of delivering and running this tool within a container.   
+ Add custom dlw extensions and repair code without changing existing script source.

### How Does It Work

In a nutshell, most dlw commands [wrap](http://en.wikipedia.org/wiki/Adapter_pattern) a corresponding Docker CLI command.  The wrapper transforms the dlw <a href=#ConceptsComponent>Component</a> and <a href=#ConceptsProject>Project</a> abstractions to an equivalent list of targeted images/containers.  These image/container lists are then used, along with a rudimentry command template, to generate a Docker CLI stream consisting of one or more individual Docker commands which implement the original dlw command.  Besides its template generation feature, the dlw, through a <a href=#ConceptsDependencySpecification>Dependency Specification</a>, applies a directed graph to order the individual Docker commands within the CLI stream to better ensure the successful execution of the entire stream.

For example, suppose a Project labeled 'sample' contains four Components: dlw_parent, dlw_sshserver, dlw_mysql, and dlw_apache.  Furthermore, the Components: dlw_sshserver, dlw_mysql, and dlw_apache lexically include dlw_parent.  In this situation, executing ```dlw build```will generate the following Docker CLI stream:
```
docker build  -t "dlw_parent" "/home/dlw/project/sample/component/dlw_parent/context/build"
docker build  -t "dlw_apache" "/home/dlw/project/sample/component/dlw_apache/context/build"
docker build  -t "dlw_mysql" "/home/dlw/project/sample/component/dlw_mysql/context/build"
docker build  -t "dlw_sshserver" "/home/dlw/project/sample/component/dlw_sshserver/context/build"
```
Notice, the placement of the Docker dlw_parent build request before the other build requests, as dlw_parent must exist/be current to correctly build the deriviative Components. 

### Installing

#### Installing: Pulling Image

+ <a href="#InstallingTagVersionPull">Determine dlw tagged version to pull.</a>  View avaliable [dlw Docker Hub tags](https://registry.hub.docker.com/u/whisperingchaos/dlw/tags/manage/).
+ <a href="#InstallingDownloaddlwRunsh">Download dlwRun.sh and make it runnable.</a>
+ <a href="#InstallingCreateHostProjectDirectory">Create dlw host Project directory.</a>
+ Open command terminal accessing appropriate Docker Daemon.
+ Execute ```dlwRun.sh``` specifying the desired Tag and host Project directory arguments.  
  + Ex: ```> dlwRun.sh '0.50_1.3.3' ~/Desktop/projects```
    Once dlwRun.sh completes, an active dlw terminal session should appear:
```
    Welcome to Ubuntu 12.04.5 LTS (GNU/Linux 3.8.0-37-generic x86_64)

     * Documentation:  https://help.ubuntu.com/

    The programs included with the Ubuntu system are free software;
    the exact distribution terms for each program are described in the
    individual files in /usr/share/doc/*/copyright.

    Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
    applicable law.

    dlw@a1d8390a5a8d:~$ 
```
##### Determine Docker Tag <a id="InstallingTagVersionPull"></a>
Since the dlw issues Docker CLI commands, its image contains a copy of Docker.  This embedded Docker instance acts as a client to communicate with the locally running Docker Daemon by forwarding, [via socket](https://docs.docker.com/articles/basics/#bind-docker-to-another-hostport-or-a-unix-socket), Docker CLI commands generated by dlw.  Therefore, the embedded Docker instance version must be compatible with the locally running Docker Daemon.  To facilitate selecting the correct dlw version, its [image tag](https://docs.docker.com/userguide/dockerimages/#setting-tags-on-an-image) consists of two version numbers.  The first one represents the dlw version, while the second specifies the Docker Daemon version.  Tag generation appends the first version to an underscore ('_') then appends the second one.  For example, a dlw version of 0.50 and Docker Daemon version of 1.3.3 produces an image tag of '0.50_1.3.3'.

##### Download dlwRun.sh <a id="InstallingDownloaddlwRunsh"></a>
dlwRun.sh wraps Docker CLI requests to pull and then run a newly created container from the desired dlw image.  It also mounts a host directory to store dlw <a href="#ConceptsProject">Projects</a> to the appropriate mount point within the newly created dlw container.
+ Start terminal session on host.
+ 'cd' to appropriate directory to contain the download of dlwRun.sh.
+ Enter either ```curl``` or ```wget``` specifying ```https://github.com/WhisperingChaos/DockerLocalWorkbench/raw/<branch>/dlwRun.sh``` replacing \<branch\> with the appropriate <a href="#InstallingTagVersionPull">Tag name</a>.
  + Ex: ```wget https://github.com/WhisperingChaos/DockerLocalWorkbench/raw/master/dlwRun.sh``` downloads current development version.
+ Issue ```chmod +x dlwRun.sh```.

Other methods to download dlwRun.sh exist [see stackoverflow.com](http://stackoverflow.com/questions/4604663/download-single-files-from-github).

##### Create Host Project Directory <a id="InstallingCreateHostProjectDirectory"></a>
Most likely, dlw <a href="#ConceptsProject">Projects</a>, which consist of source artifacts to construct <a href="#ConceptsComponent">Component(s)</a>, will reside in the host's more "permanent" file system.  Although Projects can be encapsulated within a container running the dlw or stored in an associated [Docker Data Volume](http://docs.docker.com/userguide/dockervolumes/), at this time, it just feels "safer" for Projects to exist within a "traditional" file system, as opposed to a cellular one. Given this guidance, create a subdirectory to group one or more Projects within it.  Mounting this directory into the dlw container will omit the group directory name from the running dlw container, however, its contents will be accessible.  The absolute path to this directory must not contain spaces or colons (':') in any directory name.

#### Installing: Sample Project & Testing

+ Assumes successful completion of: [Installing: Pulling Image](#installing-pulling-image) and current terminal session connected to running dlw container.
+ ```mkdir -p ~/project/sample/component``` Ensure existence of 'sample''s <a href="#ConceptsProject">Project,</a> directory and <a href="#ConceptsComponentCatalog">Component Catalog</a>.
+ ```cd ~/project/sample``` Establish 'sample' as target Project directory for dlw commands.
+ ```dlw itest``` Installs a Project called 'sample' and performs integration tests.

Once testing successfully completes, a Project called 'sample' will exist in the <a href="#InstallingCreateHostProjectDirectory">host directory</a> specified by the ```dlwRun.sh``` script.  The Project provides examples demonstrating various aspects of the dlw.  For example, specifying a Component's command line arguments for a particular command like build or run to avoid having to constantly repeat static argument values on the dlw command line (see: "../sample/component/dlw_apache/context/run")

+ Use 'sample' as a sandbox to expolore various dlw options and their effects before applying these options to your own Project's Components.
+ The contents of the 'sample' project and local [Docker Registry](https://docs.docker.com/registry/) can be reverted at any time by running ```dlw itest```.

### Project Tutorial

##### Project Turorial: Creation

Create a minimal viable Project that builds a single Component.  

+ Assumes successful completion of: [Installing: Pulling Image](#installing-pulling-image) and current terminal session connected to running dlw container.
+ Create a <a href="#ConceptsProject">Project</a> directory assigning it the desired Project's name.
  + Ex: ```mkdir ~/project/xproject``` given Project name of 'xproject'. 
+ Create the <a href="#ConceptsComponentCatalog">Component Catalog</a> directory named "component" to manage a Project's  <a href="#ConceptsComponent">Components</a>.
  + Ex: ```mkdir ~/project/xproject/component```
+ Create one or more <a id="ConceptsComponent">Component</a> instance directories with the desired Component's name.
  + Ex: ```mkdir ~/project/xproject/component/ycomponent``` given Component name of 'ycomponent'.
+ Create a Component's "context' directory.
  + Ex: ```mkdir ~/project/xproject/component/ycomponent/context``` given Component name of 'ycomponent'.
+ Create a Component's build context directory directory.  A build context directory encapsulates all the resources required to successfully build a Docker image.
  + Ex: ```mkdir ~/project/xproject/component/ycomponent/context/build```
+ Create and save a Dockerfile to a Component's build context directory.
  + Ex: Produces a Component that's slightly different from ubuntu:12:04.

        ```
        echo 'FROM ubuntu:12.04'        > ~/project/xproject/component/ycomponent/context/build/Dockerfile
        echo "ENV DIFF 'MakeItUnique'" >> ~/project/xproject/component/ycomponent/context/build/Dockerfile
        echo 'ENTRYPOINT [/bin/bash]'  >> ~/project/xproject/component/ycomponent/context/build/Dockerfile
        ```

##### Project Turorial: Build

+ Build all Components associated to the Project.
  + Ex:

        ```
        cd ~/project/xproject
        dlw build
        ```

##### Project Turorial: Report

+ Report on a Project's related images:
  + Ex: ```dlw images``` Should return an extended form of the ```docker images``` report with only a single row of 'ycomponent' information.

##### Project Turorial: Run

Create new containers for all Components then run and attach to their ttys.

+ Add the 'run' 'context' directory to the Component's definition.
  + Ex: ```mkdir ~/project/xproject/component/ycomponent/context/run```
+ Create the file named DOCKER_CMMDLINE_OPTION and populate it with run options of '-i --tty'.  This file preserves these options to ensure a terminal can be attached to the Component's derivative container and reflect a tty interface without having to specify them on every ```dlw run``` command.
  + Ex: ```echo '-i --tty' > ~/project/xproject/component/ycomponent/context/run/DOCKER_CMMDLINE_OPTION```
+ Create containers for all Components and run them deferring terminal attachment.
  + Ex: ```dlw run -d``` Constructs a container from the ycomponent image and runs it.  Should output the Docker GUID for the newly constructed and running container.
+ Attach a Project's active container terminal instances to either a new or an existing screen session.
  + Ex: ```dlw screen``` Creates a screen session named 'xproject' with a single active tty session for container derived from 'ycomponent'.
+ Use [GNU screen](http://www.gnu.org/software/screen/) command to screen
  + Ex: ```screen -r``` Attaches the current GNU screen session named ```<PID>.xproject```.

##### Project Turorial: Remove Images

Removes all Images and derivative Containers associated to a Project from the Local Docker Registry. However, data maintained in the Project's Component Catalog remains untouched.

+ ```dlw rmi -f --dlwrm --dlwcomp-ver=all all```

### Exploring Commands

+ Assumes successful completion of: [Installing: Pulling Image](#installing-pulling-image).
+ dlw provides typical help information:
  + Run ```dlw help``` to display a summary of all commands.
  + Run ```dlw <CommandName> --help``` to displays a command's offered options.
    + Ex: dlw build --help:
```
Create image file for targeted Components.  Wraps docker build command.

Usage: dlw build [OPTIONS] TARGET 
TARGET:  {'all'|COMPONENT [COMPONENT...]}
  'all'              Process all Components defined by Project. Default Behavior.
  COMPONENT          Replace with one or more Component names.

OPTIONS: dlw:
    --dlwno-parent=false  Build only the targeted Component(s). Exclude prerequisite parent one(s).
    --dlwforce=false      Force build even when Component Resources haven't changed.
    --dlwno-exec=false    Do not execute the generated docker command.
    --dlwshow=false       Write the generated docker command to SYSOUT.
    --help=false          Display help for this command.

OPTIONS: docker:
    --force-rm=false     Always remove intermediate containers, even after unsuccessful builds
    --no-cache=false     Do not use cache when building the image
    -q, --quiet=false    Suppress the verbose output generated by the containers
    --rm=true            Remove intermediate containers after a successful build
    -t, --tag=""         Repository name (and optionally a tag) to be applied to the resulting image in case of success
```
Notes:
+ dlw wrapper commands display two sets of options: dlw specific, always prefixed by "--dlw" and the related Docker options. Allows weaving of dlw options and Docker specific ones.  
+ Options always consume the subsequent command line token, except when the token represents another option or is ' -- ': the argument separator.
+ The assignment operator, '=', can be omitted. Ex: "--dlwno-parent true" == "--dlwno-parent=true"
+ Specifying a boolean option without a value negates its default value. Ex. "--dlwno-parent -- ..." --dlwno-parent negated from 'false' to 'true'.
+ Docker array options [], like '-v', aren't directly supported by the dlw command line.  These recurring options should be specified within the context   

#### Example Remove Commands

+ **Remove All Component Versions for All Components:**
  Deletes all images, their versions, and all associated containers even if the containers are running at the time of this request:  
  ```
> make Remove idscope=All complist=All
```
+ **Remove just the Current Component Version for All Components:**
  Deletes the most recently built image for every Component and all associated containers, even if the containers are running at the time of this request:  
  ```
> make Remove idscope=Current complist=All
```
+ **Remove All the containers for Current Component Version of sshserver.img:**
  Deletes every container associated to the most recently built Component named "sshserver".  
  ```
> make Remove restrict=OnlyContainers idscope=Current complist=sshserver.img
```
+ **Remove All containers and All Components except for the Current ones.**
  Deletes every container and every image version except for the most recent version.  
  ```
> make Remove idscope=AllExceptCurrent complist=All
```

### Concepts

+ **Component**<a id="ConceptsComponent"></a>:  A widget that contributes one or more elemental services to a cooperative pod of other Components.  Component's offer their service(s) through either lexical inclusion, statically inheriting a base Component's implementation ([see FROM](http://docs.docker.io/reference/builder/#from)), or dynamically, as individually executing entities that coordinate their activity through some protocol mechanism ([see LINK](https://docs.docker.com/userguide/dockerlinks/)).

    The dlw implements a Component as a directory whose name reflects the image's name in the local repository.  This directory contains a subdirectory called "context" which represents the resources required to execute a particular dlw command.  "context" is further subdivided by subdirectories whose names reflect a dlw command.  These command-context subdirectories contain resources, like command line options, required to execute the particular command.  They also identify which commands apply to a particular Component, as certain Components may support some but not all dlw commands. For example, a statically included Component might not support the ```dlw run``` command.
+ **Dependency Specification**<a id="ConceptsDependencySpecification"></a>: A declarative mechanism to encode dlw command dependencies between Components.  Component dependencies can be independenly specified for any dlw command, permitting for example, separate dependency graphs for build-time, ```dlw build``` vs. run-time concerns, ```dlw run```.  In general, nearly all dlw commands mirror either build-time or run-time dependencies.  For example, ```dlw start``` shares the same dependency graph as ```dlw run```.  In these cases, individual dlw commands can share an existing command's dependency graph.  Specified dependencies will order the dlw generated Docker Daemon CLI stream to more fully ensure its successful completion (see [How Does It Work](#how-does-it-work)).  Dependency Specification maybe optional, as weakly coupled Components, a pod whose ordering doesn't affect the outcome of any dlw command, eliminate its encoding.

    A file named "Dependency" captures [GNU make rules](http://www.gnu.org/software/make/manual/html_node/Rule-Introduction.html#Rule-Introduction) for each Component name and dlw command pair. A rule should only specify a target and its prerequiste(s).  In all cases, a provided default recipie triggers an appropriate process chain to implement the specified dlw command.  As indicated above, this file should not exist in situations involving weakly coupled Components, as it will be empty.
+ **Component Catalog**<a id="ConceptsComponentCatalog"></a>: Defines the pod of directly interacting Components from which desired group behavior emerges and optionally contains a Dependency Specification.

    A directory called "component" implements a Component Catalog.  One or more Component directores exist as subdirectories within "component".  dlw commands that operate on individual images and their derived containers iterate over "component".
+ **Image GUID List**<a id="ConceptsImageGUIDList"></a>:  An object that maintains a list of Docker image GUIDs generated when building a specific Component.  The different GUIDs in this list represent various image versions generated due to alterations applied to resources, like a Dockerfile, that comprise a Component's (image's) build context.  Associated to each GUID, a column property bag enables extending the metadata for an image to include an arbitrary set of attribures/columns.  These columns can appear in the reporting generated by the ```dlw ps``` and ```dlw image``` commands.

  A standard text file implements each Image GUID List.  The text file is assigned the same name as the Component (image) name with a suffix of ".GUIDlist".  The image GUIDs in the file are ordered from the oldest, which appears as the first line in the text file, to the most recent GUID that occupies its last line.  The column property bag appears space prefixed after the GUID.  It's implemented as a [bash associative array](http://www.linuxjournal.com/content/bash-associative-arrays) named "componentPropBag".  Simply update this column property bag with the custom property names and values you wish displayed as reporting columns.
+ **Component Versioning**<a id="ConceptsComponentVersioning"></a>: A changed to a Component's build context results in a new version of the compiled image.  This newly compiled image is automatically assigned a docker repository name mirroring the Component's name and a docker tag name of 'latest'.  An existing and now prior version of the Component will loose these names reverting to repository and tag names of '<none>'. dlw maintains a list of these prior versions (see <a id="ConceptsImageGUIDList">Image GUID List</a>) and offers a means of indicating a category specifier for a number of its commands.  The dlw supports the following category specifiers: *Current*: the most recent image version, *All*: every known image version, *All But Current*: All image versions excluding  the *current* one.  Since the development process typically focuses on evolving the *Current* version, dlw omits a means to select a particular previous version.
+ **Build Target**<a id="ConceptsBuildTarget"></a>: An implementation level object whose timestamp represents a Component's last successful ```dlw build```.  This timestamp enables build-time optimization by only executing a ```dlw build``` for a given Component iff at least one of the Component's resources reflects a more recent date than the Build Target.  In this case, ```dlw build``` considers the Component changed since the last ```dlw build``` request causing ```dlw build``` to construct a new Component version.

    A Build Target implements itself as a file whose name concatenates the Component name with the suffix ".build".

+ **Build Catalog**<a id="ConceptsBuildCatalog"></a>: An implementation level object that encapsulates one or more Build Targets.

    A Build Catalog appears as a directory called "build".
+ **Image Catalog**<a id="ConceptsImageCatalog"></a>:  An object that encapsulates all Image GUID Lists and Build Targets.

    It's implemented as a directory named "image".

+ **Script Catalog**<a id="ConceptsScriptCatalog"></a>: A repository comprised almost entirely of bash scripts.  The bash scripts can be categorized as either "framework" or "command" scripts.  Framework scripts generically encode the behavior to support dlw commands, while command scripts override the necessary functions within framework modules to support a particular command, such as ```dlw build``` or ```dlw run```.  Script Catalogs can exist on two levels: Installation and Project.  An Installation Script Catalog organizes scripts so a single instance of the Catalog can be shared among several dlw Projects.  In constrast, a Project Script Catalog exists within a particular Project, is inaccessible/isolated from other Projects, and can override any portion of or the entire Installation Script Catalog.

  A directory named 'script' implements a Script Catalog.  The Installation Script Catalog resides in the "/usr/bin/dlw/" while a Project Script Catalog, if desired, dwells within a specific Project.

+ **Project**<a id="ConceptsProject"></a>:  An object encapsulating a Component Catalog, an Image Catalog, and potentially a Project Script Catalog.  A Project's Component Catalog defines the complete scope of Components addressable by a dlw command.  A viable Project minimally contains a Component Catalog consisting of at least one buildable/runnable Component.  

    Implemented as a directory whose name reflects the one assgined to the Project.  The dlw command will assume the current working directory contains the Project that should be affected by it.  Project may also contain a temporary directory named "tmp" if the current dlw command failes providing state information that may be important to debugging the its cause. 


##### What's Provided

+ Docker's OS image: [Ubuntu 12.04](https://github.com/tianon/docker-brew-ubuntu-core/blob/7fef77c821d7f806373c04675358ac6179eaeaf3/precise/Dockerfile)
  + [GNU bash](https://www.gnu.org/software/bash/): [4.2.25(1)-release](http://manpages.ubuntu.com/manpages/precise/man1/bash.1.html)
+ [Docker Daemon (Client)](https://docs.docker.com/reference/commandline/cli/): lxc-docker-?.?.?
+ [GNU make](http://www.gnu.org/software/make/manual/html_node/index.html): [3.81-8.1ubuntu1.1](http://packages.ubuntu.com/precise/make)
+ [GNU screen](http://www.gnu.org/software/screen/): [4.0.3-14ubuntu8](http://packages.ubuntu.com/precise/screen)
+ [Docker Local Workbench](https://github.com/WhisperingChaos/DockerLocalWorkbench)

### License

The MIT License (MIT)
Copyright (c) 2014 Richard Moyse License@Moyse.US

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
