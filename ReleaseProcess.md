New release process:

+ merge latest_lastest branch into master.
+ Ensure merged master builds properly with new version:
  + Download master to 'release-test environment':
    + Release-test environment must have git and the desired version of the Docker Daemon running
    + ```apt-cache show lxc-docker-?.?.?```
    + ```git clone https://github.com/WhisperingChaos/DockerLocalWorkbench```
    + ```git remote set-url origin git@github.com:WhisperingChaos/DockerLocalWorkbench.git```
  + Change existing files in Release-test environment:
    + [versionSpecifiers.sh](https://github.com/WhisperingChaos/DockerLocalWorkbench/blob/master/scriptInstall/versionSpecifiers.sh) must reflect the desired build time component versions.
    + [version.sh](https://github.com/WhisperingChaos/DockerLocalWorkbench/blob/master/script/command/version.sh) must reflect the newly determined ```dlw``` version.
  + ```docker build -t dlw .``` the workbench locally.
+ Test the new branch.
  + ```dlwRun.sh -l dlw``` creates a new container reflecting the newly introduced component versions.
  + Verify that selected versions are reflected by:
    + ```dlw version```
  + Run the integration tests within the container:
    + ```cd ~/project/sample```
    + ```dlw itest```
+ Iterate building & testing till happy.
+ Create a new [dlw](https://github.com/WhisperingChaos/DockerLocalWorkbench) git tag:
  + Determine ```dlw version```.
  + Determine ```docker version```.
  + Generate git tag name: ```dlw version```_```docker version```
  + ```git tag -a <dlw version>_<docker version> -m "dlw: <dlw version>, Docker Daemon: <docker version>"```
  + Push branchs to github:
    + ```git push                  # updated production```
    + ```git push origin --tag     # new tag```    
+ Add new [Docker Hub Tag](https://registry.hub.docker.com/u/whisperingchaos/dlw/tags/manage/) to reference the newly created branch.
  + tag name=github tag name
+ Test Docker Hub image:
  + Download and run ```dlw``` Hub image:
  + ```dlwRun.sh <dlw version>_<docker version>```
    + ```cd ~/project/sample```
    + ```dlw itest```

