# Release repository for x86-generic-64

Montavista Software, LLC. release of x86-generic-64. 

How to use:
==========

```
git clone -b next --recursive https://github.com/MontaVista-OpenSourceTechnology/opencgx-x86-generic-64
cd opencgx-x86-generic-64
source setup.sh
```

By default, the script will create a project called project, you may change this
by adding the directory name you would like to use on the source line:

```
source setup.sh <my directory>
```

After running the top level setup.sh, you are ready to build. When starting
another session, you can source the setup.sh script in the project directory
to get started. This script will automatically source the environment for
the build tools stored under buildtools, and sources the 
poky/oe-init-build-env script.

From that point, the project should work like any other yocto based build system. So
a command like the following will build images that you can run via qemu or on a real target.

```
cd project
or
cd <my directory>
source setup.sh
bitbake core-image-minimal
runqemu x86-generic-64 nographic slirp
```

For additional information see the yocto documentaion: https://www.yoctoproject.org/docs/

directory layout:
================
```
opencgx-x86-generic-64/
       project - bitbake project for the x86-generic-64 project build
       buildtools - build tools to provide minimal build requirement for poky builds
       layers - layers for building x86-generic-64 project
       setup.sh - project setup script  
```

The default MACHINE is x86-generic-64, however x86-atom-64 and x86-generic are also available. 
