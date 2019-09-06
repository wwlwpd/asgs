#!/bin/bash

TODO=${1-make};

cd $HOME/adcirc-cg
cd $HOME/adcirc-cg/work
if [ "$TODO" = "clean" ]; then
  make clean clobber
else
  #make clean clobber
  make all adcswan padcswan hstime aswip compiler=$ADCCOMPILER NETCDF=enable NETCDF4=enable NETCDF4_COMPRESSION=enable NETCDFHOME=$NETCDFHOME MACHINENAME=$MACHINENAME
fi
