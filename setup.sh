#!/bin/bash -x 
export -n BBPATH
if [ -n "$BASH_SOURCE" ]; then
    THIS_SCRIPT=$BASH_SOURCE
elif [ -n "$ZSH_NAME" ]; then
    THIS_SCRIPT=$0
else
    THIS_SCRIPT="$(pwd)/setup.sh"
fi
THIS_SCRIPT=$(readlink -f $THIS_SCRIPT)
if [ "$MAKEDROP" = "1" ] ; then
   if [ -z "$ZSH_NAME" ] && [ "$0" = "$THIS_SCRIPT" ]; then
       echo "Error: This script needs to be sourced. Please run as '. $THIS_SCRIPT'"
       exit 1
   fi
fi
if [ "x$1" = "x" ] ;
then
	buildDir=$(pwd)/project
        echo "$buildDir used as project." 2>&1
	echo "To change source $THIS_SCRIPT <builddir>" 2>&1
else
	buildDir=$1
fi
 
REPO_CONFIG="\
LAYER@https://github.com/MontaVista-OpenSourceTechnology/poky.git;branch=rocko;layer=meta \
LAYER@https://github.com/MontaVista-OpenSourceTechnology/poky.git;branch=rocko;layer=meta-poky \
LAYER@https://github.com/MontaVista-OpenSourceTechnology/poky.git;branch=rocko;layer=meta-yocto-bsp \
LAYER@https://github.com/MontaVista-OpenSourceTechnology/meta-openembedded.git;branch=rocko;layer=meta-oe \
LAYER@https://github.com/MontaVista-OpenSourceTechnology/meta-openembedded.git;branch=rocko;layer=meta-python \
LAYER@https://github.com/MontaVista-OpenSourceTechnology/meta-openembedded.git;branch=rocko;layer=meta-filesystems \
LAYER@https://github.com/MontaVista-OpenSourceTechnology/meta-openembedded.git;branch=rocko;layer=meta-networking \
LAYER@https://github.com/MontaVista-OpenSourceTechnology/meta-openembedded.git;branch=rocko;layer=meta-webserver \
LAYER@https://github.com/MontaVista-OpenSourceTechnology/meta-clang.git;branch=rocko \
LAYER@https://github.com/MontaVista-OpenSourceTechnology/meta-virtualization.git;branch=rocko \
LAYER@https://github.com/MontaVista-OpenSourceTechnology/meta-montavista-cgx.git;branch=rocko \
LAYER@https://github.com/MontaVista-OpenSourceTechnology/meta-openembedded.git;branch=rocko;layer=meta-perl \
LAYER@https://github.com/MontaVista-OpenSourceTechnology/meta-openembedded.git;branch=rocko;layer=meta-gnome \
LAYER@https://github.com/MontaVista-OpenSourceTechnology/meta-openembedded.git;branch=rocko;layer=meta-multimedia \
LAYER@https://github.com/MontaVista-OpenSourceTechnology/meta-openembedded.git;branch=rocko;layer=meta-xfce \
LAYER@https://github.com/MontaVista-OpenSourceTechnology/meta-selinux.git;branch=master \
LAYER@https://github.com/MontaVista-OpenSourceTechnology/meta-security.git;branch=rocko \
LAYER@https://github.com/MontaVista-OpenSourceTechnology/meta-cgl.git;branch=rocko;layer=meta-cgl-common \
LAYER@https://github.com/MontaVista-OpenSourceTechnology/meta-cloud-services.git;branch=rocko;layer=meta-openstack \
LAYER@https://github.com/MontaVista-OpenSourceTechnology/meta-cloud-services.git;branch=rocko \
LAYER@https://github.com/MontaVista-OpenSourceTechnology/meta-montavista-cgl;branch=rocko \
LAYER@https://github.com/MontaVista-OpenSourceTechnology/meta-montavista-x86-generic-4.14.git;branch=rocko \
MACHINE@x86-generic-64 \
DISTRO@mvista-cgx \
SOURCE@https://github.com/MontaVista-OpenSourceTechnology/linux-mvista-2.4;branch=mvl-4.14/msd.cgx;meta=MV_KERNEL \
SOURCE@https://github.com/MontaVista-OpenSourceTechnology/yocto-kernel-cache;branch=yocto-4.13;meta=MV_KERNELCACHE \
"
#We use 2.3.3 build tools because of kenrel version limitations
BUILD_TOOLS_LOCATION=http://downloads.yoctoproject.org/releases/yocto/yocto-2.3.3/buildtools/
buildtar=x86_64-buildtools-nativesdk-standalone-2.3.3.sh
TOPDIR=$(dirname $THIS_SCRIPT)
if [ ! -d buildtools ] ; then
   if [ -e $TOPDIR/.buildtools -a -e "$(cat .buildtools 2>/dev/null)" ] ; then
      buildtar=$(cat .buildtools)
   else
      if [ -z "$BUILD_TOOLS_LOCATION" ] ; then
         yoctoDownloads=http://downloads.yoctoproject.org/releases/yocto/
         latestRelease=$(echo -n $(lynx -dump $yoctoDownloads -nolist | cut -d / -f 1 | grep yocto- | tail -n 1))
         BUILD_TOOLS_LOCATION=$yoctoDownloads/$latestRelease/buildtools/
         releaseDir="$latestRelease"
         releaseVersion="$(echo $latestRelease | cut -d - -f 2)"
         buildtar="x86_64-buildtools-nativesdk-standalone-$releaseVersion.sh"
      fi 
      if [ -z "$buildtar" ] ; then
         buildtar=$(lynx -dump -nolist $BUILD_TOOLS_LOCATION |
            grep \.sh | grep -v md5sum | while read A B C; do echo $A; done)
      fi
      if [ "$buildtar" = "[" ] ; then
         buildtar=$(lynx -dump -nolist $BUILD_TOOLS_LOCATION | 
             grep \.sh | grep -v md5sum | while read A B C D; do echo $C; done)
      fi

      if [ ! -e $TOPDIR/$buildtar ] ; then
             wget -O $TOPDIR/$buildtar $BUILD_TOOLS_LOCATION/$buildtar
      fi
   fi
   if [ ! -d "$TOPDIR/buildtools" ] ; then
        chmod 755 $TOPDIR/$buildtar
        bash $TOPDIR/$buildtar -y -d $TOPDIR/buildtools
        echo $buildtar > $TOPDIR/.buildtools
   fi
fi

if [ ! -e $TOPDIR/.drop ] ; then
   if [ ! -e $TOPDIR/.repo ] ; then
      pushd $TOPDIR
         git pull
         git submodule init
         git submodule update --remote
      popd
   else
      pushd $TOPDIR
         repo sync
      popd
   fi
fi

for config in $REPO_CONFIG; do
    VAR=$(echo $config | cut -d @ -f 1)
    VAL=$(echo $config | cut -d @ -f 2)
    if [ "$VAR" = "URL" ] ; then
       BASE_URL=$VAL
       MSD_URL=$(dirname $BASE_URL)
       LATEST_URL=$MSD_URL/latest/source-repos
    fi
done

if [ -z "$TEMPLATECONF" ] ; then
    export TEMPLATECONF=$TOPDIR/layers/meta-montavista-cgx/conf
fi
source $TOPDIR/buildtools/environment-setup-*
source $TOPDIR/layers/poky/oe-init-build-env $buildDir 
export BB_NO_NETWORK="1"
export LAYERS_RELATIVE="1"
if [ -z "$LOCAL_SOURCES" ] ; then
      LOCAL_SOURCES=1
fi
if [ -e $TOPDIR/.drop -o "$MAKEDROP" = "1" ] ; then
      LOCAL_SOURCES=1
fi
echo "# Do not modify, automatically generated" >> conf/local-content.conf
echo >> conf/local-content.conf
for config in $REPO_CONFIG; do
    VAR=$(echo $config | cut -d @ -f 1)
    VAL=$(echo $config | cut -d @ -f 2)
    if [ "$VAR" = "LAYER" ] ; then
       layer=$(echo $VAL | cut -d \; -f 1)
       layerDir=$(basename $layer | sed s,.git,,)
       options=$(echo $VAL | cut -d \; -f 2-)
       sublayer=""
       for option in $(echo $options | sed s,\;,\ ,g); do
           if [ "$(echo $option | cut -d = -f 1)" = "layer" ] ; then
                sublayer=$(echo $option | cut -d = -f 2)
           fi
       done
       if [ "$MAKEDROP" != "1" ] ; then
          echo "adding $layerDir/$sublayer"
          bitbake-layers -F add-layer $TOPDIR/layers/$layerDir/$sublayer >/dev/null
       fi
    fi
    if [ "$VAR" = "MACHINE" ] ; then
          echo "MACHINE ?= '$VAL'" >> conf/local-content.conf
          echo >> conf/local-content.conf
    fi
    if [ "$VAR" = "DISTRO" ] ; then
          echo "DISTRO ?= '$VAL'" >> conf/local-content.conf
          echo >> conf/local-content.conf
    fi
    if [ "$VAR" = "SOURCE" ] ; then
          META=""
          BRANCH="master"
          TREE=$(echo $VAL | cut -d \; -f 1)
          for option in $(echo $VAL | sed s,\;,\ ,g); do
              OVAR=$(echo $option | cut -d = -f 1) 
              OVAL=$(echo $option | cut -d = -f 2)
              if [ "$OVAR" = "meta" ] ; then
                    META=$OVAL
              fi
              if [ "$OVAR" = "branch" ] ; then
                    BRANCH=$OVAL
              fi
          done
          mkdir -p $TOPDIR/sources-export
          LSOURCE=$TOPDIR/sources/$(basename $TREE | sed s,.git,,)
          LSOURCE_EXPORT=$TOPDIR/sources-export/$(basename $TREE | sed s,.git,,)
          if [ ! -e $TOPDIR/.drop ] ; then
                   pushd $LSOURCE
                     git checkout $BRANCH
                     git pull
                   popd
              if [ ! -e $LSOURCE_EXPORT ] ; then
                 if [ "$BRANCH" = "master" ] ; then
                    git clone --bare $LSOURCE $LSOURCE_EXPORT
                 else
                    git clone -b $BRANCH --bare $LSOURCE $LSOURCE_EXPORT
                 fi
              else
                 pushd $LSOURCE_EXPORT
                     git fetch
                 popd
              fi
          fi
          DL_TREE="git://$TOPDIR/sources-export/$(basename $TREE | sed s,.git,,)"
          echo "$(echo $META)_TREE = '$DL_TREE'" >> conf/local-content.conf
          echo "$(echo $META)_BRANCH = '$BRANCH'" >> conf/local-content.conf
          echo >> conf/local-content.conf
    fi
done
export -n BB_NO_NETWORK
if [ "$MAKEDROP" != "1" ] ; then
   # Temporary waiting for proper bitbake integration: https://patchwork.openembedded.org/patch/144806/
   RELPATH=$(python -c "from os.path import relpath; print (relpath(\"$TOPDIR/layers\",\"$(pwd)\"))")
   sed -i conf/bblayers.conf -e "s,$TOPDIR/layers/,\${TOPDIR}/$RELPATH/,"

   SCRIPT_RELPATH=$(python -c "from os.path import relpath; print (relpath(\"$TOPDIR\",\"`pwd`\"))")
   cat > setup.sh << EOF
   if [ -n "\$BASH_SOURCE" ]; then
      THIS_SCRIPT=\$BASH_SOURCE
   elif [ -n "\$ZSH_NAME" ]; then
      THIS_SCRIPT=\$0
   else
      THIS_SCRIPT="\$(pwd)/setup.sh"
   fi
   PROJECT_DIR=\$(dirname \$THIS_SCRIPT)
   source $SCRIPT_RELPATH/buildtools/environment-setup-*
   source $SCRIPT_RELPATH/layers/poky/oe-init-build-env \$PROJECT_DIR
EOF
   rm -rf tmp-glibc
else
   rm -rf tmp
   rm -rf $TOPDIR/buildtools
   touch $TOPDIR/.drop
   rm -rf $TOPDIR/project
fi
