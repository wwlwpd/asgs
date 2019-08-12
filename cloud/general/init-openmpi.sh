#!/usr/bin/bash

TMP=$HOME/tmp
OPT=${1-$HOME/opt}
COMPILER=${2-intel}

OPENMPI_VERSION=openmpi-1.8.1

if [ $2 == "clean" ]; then 
  echo Cleaning OpenMPI libraries and utilities
  cd $OPT/bin
  rm -rfv mpic++ mpicc mpiCC mpicc-vt mpiCC-vt mpic++-vt mpicxx mpicxx-vt mpiexec mpif77 mpif77-vt mpif90 mpif90-vt mpifort mpifort-vt mpirun vtwrapper opal_wrapper mpifort ompi_info oshmem_info
  cd $OPT/lib
  rm -rfv *mpi*
  cd $OPT/include
  rm -rvf *mpi* vampirtrace mpp
  exit
fi

if [ $COMPILER == "intel" ]; then 
  export CC=icc
  export FC=ifort
  export CXX=icpc
fi
if [ $COMPILER == "gfortran" ]; then 
  export CC=gcc
  export FC=gfortran
  export CXX=g++
fi

mkdir -p $TMP
mkdir -p $OPT
cd $TMP

wget https://www.open-mpi.org/software/ompi/v1.8/downloads/${OPENMPI_VERSION}.tar.gz
tar -xvf $OPENMPI_VERSION.tar.gz
cd $OPENMPI_VERSION 

./configure --prefix=$OPT
make
make install
