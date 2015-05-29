New release process:

+ Determine ```dlw``` version to assign to new branch.
+ Determine ```docker``` version new branch targets.
+ Create a new [dlw](https://github.com/WhisperingChaos/DockerLocalWorkbench) branch:
  + Generate branch name: ```dlw version```_```docker version```
  + Change existing files in new branch:
    + [version.sh](https://github.com/WhisperingChaos/DockerLocalWorkbench/blob/master/script/command/version.sh)
    + [versionSpecifiers.sh](https://github.com/WhisperingChaos/DockerLocalWorkbench/blob/master/scriptInstall/versionSpecifiers.sh)
+ Add new [Docker Hub Tag](https://registry.hub.docker.com/u/whisperingchaos/dlw/tags/manage/) to reference the newly created branch.
  + tag name=github branch name

