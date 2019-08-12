#!/usr/bin/bash

if [ ! -d $HOME/adcirc-cg/work ]; then
  git clone https://github.com/adcirc/adcirc-cg.git
fi
cd $HOME/adcirc-cg/work
export PATH=/home/vagrant/opt/bin:/home/vagrant/perl5/perlbrew/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:$PATH
export CPPFLAGS=-I/home/vagrant/opt/include
export LDFLAGS=-L/home/vagrant/opt/lib
export LD_LIBRARY_PATH=/home/vagrant/opt/lib:
export LD_INCLUDE_PATH=/home/vagrant/opt/include:
make all compiler=gfortran NETCDF=enable NETCDF4=enable NETCDF4_COMPRESSION=enable MACHINENAME=jason-desktop
