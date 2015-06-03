New release process:

+ Determine ```dlw``` version to assign to new branch.
+ Determine ```docker``` version new branch targets.
+ Create a new [dlw](https://github.com/WhisperingChaos/DockerLocalWorkbench) branch:
  + Generate branch name: ```dlw version```_```docker version```
+ Ensure new branch builds properly with new version:
  + Download branch to 'release-test environment':
    + Release-test environment must have git and the desired version of the Docker Daemon running 
  + Change existing files in new branch:
    + [versionSpecifiers.sh](https://github.com/WhisperingChaos/DockerLocalWorkbench/blob/master/scriptInstall/versionSpecifiers.sh) must reflect the desired build time component versions.
    + [version.h](https://github.com/WhisperingChaos/DockerLocalWorkbench/blob/master/script/command/version.sh) must reflect the newly determined ```dlw``` version.
  + ```docker build``` the workbench locally.
+ Test the new branch.
  + ```dlwRun.sh -l dlw``` creates a new container reflecting the newly introduced component versions.
  + Verify that selected versions are reflected by:
    + [dlw version]
  + run the integration tests within the container:
    + ```cd ~/project/sample```
    + ```dlw itest```
+ Iterate building & testing till happy.
+ Push branch to github.
+ Add new [Docker Hub Tag](https://registry.hub.docker.com/u/whisperingchaos/dlw/tags/manage/) to reference the newly created branch.
  + tag name=github branch name

