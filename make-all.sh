flags=$1

OPT=$HOME/opt/testing

#1. build NETCDF and HDF5 libraries, set environmental variables
export LD_LIBRARY_PATH=$OPT/lib:$LD_LIBRARY_PATH
export LD_INCLUDE_PATH=$OPT/lib:$LD_INCLUDE_PATH
export CPPFLAGS=-I$OPT/include
export LDFLAGS=-L$OPT/lib
export NETCDFPATH=$OPT

sh install/install-hdf5-netcdf4.sh $OPT
echo $OPT

#2.

echo xxx $LD_LIBRARY_PATH
#"NETCDF=enable NETCDF4=enable NETCDF4_COMPRESSION=enable MACHINENAME=stampede │make[1]: Leaving directory `/home1/06482/estrabd/tmp/netcdf-fortran-4.2' compiler=gfortran"
make -f ./makefile clean
make -f ./makefile NETCDFPATH=$OPT $flags

pushd ./output
make -f ./makefile clean
make -f makefile NETCDFPATH=$OPT $flags
popd

pushd ./output/cpra_postproc
make -f ./makefile clean
make -f makefile NETCDFPATH=$OPT $flags
popd

pushd ./util
make -f ./makefile clean
make -f makefile NETCDFPATH=$OPT $flags
popd

pushd ./util/input/nodalattr
make -f ./makefile clean
make -f makefile NETCDFPATH=$OPT $flags
popd

pushd ./util/input/mesh
make -f ./makefile clean
make -f makefile NETCDFPATH=$OPT $flags
popd
