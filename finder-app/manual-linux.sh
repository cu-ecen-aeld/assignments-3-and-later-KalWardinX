#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}
    # TODO: Add your kernel build steps here
    echo "[Start]:  Kernel build steps"
    # clean
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    # defconfig
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    # vmlinux
    # fixes dtc parser error multiple declaration of yylloc
    if [ "$(grep "YYLTYPE yylloc;" ${OUTDIR}/linux-stable/scripts/dtc/dtc-lexer.l)" != "extern YYLTYPE yylloc;" ]
    then
        sed -i 's/YYLTYPE yylloc/extern YYLTYPE yylloc/g' ${OUTDIR}/linux-stable/scripts/dtc/dtc-lexer.l
    fi
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
    # modules
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
    # devicetree
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
    echo "[End]:    Kernel build steps over"
fi

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
echo "[Start]:  Creating necessary base directories"
mkdir "${OUTDIR}/rootfs"
cd "${OUTDIR}/rootfs"
touch init
mkdir bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir usr/bin usr/lib usr/sbin
mkdir -p var/log
echo "[End]:    Created necessary base directories"

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make distclean
    make defconfig
else
    cd busybox
fi

# TODO: Make and install busybox
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} CONFIG_PREFIX="${OUTDIR}/rootfs" install
cd "${OUTDIR}/rootfs"

echo "Library dependencies"
prog_interpreter=$(${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter" | cut -f 2 -d: | tr -d ] | cut -f 3 -d/)
shared_lib=$(${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library" | cut -f 2 -d: | tr -d ] | tr -d [)
echo ${prog_interpreter}
echo ${shared_lib}
# TODO: Add library dependencies to rootfs
sysroot=$(${CROSS_COMPILE}gcc -print-sysroot)
echo ${sysroot}
prog_inter_path="$(find ${sysroot} -type l,f -name ${prog_interpreter})"

cp -a "$(realpath ${prog_inter_path})" "${OUTDIR}/rootfs/lib64"
cp -a "${prog_inter_path}"  "${OUTDIR}/rootfs/lib/"
for i in ${shared_lib}
do
    echo ${i}
    shared_lib_path="$(find ${sysroot} -name ${i})"
    link="$(realpath ${shared_lib_path})"
    cp -a ${link} "${OUTDIR}/rootfs/lib64"
    cp -a ${shared_lib_path} "${OUTDIR}/rootfs/lib64/"
done
# TODO: Make device nodes
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/null c 1 3
sudo mknod -m 600 ${OUTDIR}/rootfs/dev/console c 5 1

# TODO: Clean and build the writer utility
cd ${FINDER_APP_DIR}
make clean
make CROSS_COMPILE=${CROSS_COMPILE} all

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp -rL ${FINDER_APP_DIR}/conf ${OUTDIR}/rootfs/home/ 
cp -L ${FINDER_APP_DIR}/autorun-qemu.sh ${FINDER_APP_DIR}/finder.sh ${FINDER_APP_DIR}/finder-test.sh ${FINDER_APP_DIR}/Makefile ${FINDER_APP_DIR}/writer ${FINDER_APP_DIR}/writer.c ${FINDER_APP_DIR}/writer.o ${FINDER_APP_DIR}/writer.sh ${OUTDIR}/rootfs/home/

# TODO: Chown the root directory
cd ${OUTDIR}/rootfs
sudo chown -R root:root *

# TODO: Create initramfs.cpio.gz
cd ${OUTDIR}/rootfs
find . | cpio -o -H  newc|gzip > ${OUTDIR}/initramfs.cpio.gz