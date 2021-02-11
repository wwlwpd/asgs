#!/usr/bin/env bash

OPT=${1-$ASGS_INSTALL_PATH}
COMPILER=$2
JOBS=${3-1}
TMP=/tmp/$USER-asgs

if [ "$COMPILER" == "clean" ]; then 
  echo cleaning units
  cd $OPT/bin
  rm -rvf units units_cur
  cd $OPT/share
  rm -rvf units
  cd $OPT/share/man/man1
  rm -rvf units.1
  cd $OPT/share/man/man3
  cd $TMP
  exit
fi

UNITS_VERSION=2.21
UNITS_DIR=units-${UNITS_VERSION}
UNITS_TGZ=${UNITS_DIR}.tar.gz
cd $TMP

if [ ! -e ${UNITS_TGZ} ]; then
  wget https://ftp.gnu.org/gnu/units/${UNITS_TGZ}
fi

rm -rf ./$UNITS_DIR 2> /dev/null

tar zxvf ./$UNITS_TGZ

cd $UNITS_DIR
./configure --prefix=$OPT
make -j $JOBS
make install

# no errors, so clean up
if [ "$?" == 0 ]; then
  echo cleaning build scripts and downloads
  cd $TMP
  rm -rfv units* 
fi
