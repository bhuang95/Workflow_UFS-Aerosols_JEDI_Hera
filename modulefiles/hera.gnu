#%Module

proc ModulesHelp {} {
  puts stderr "\tcit - loads modules for Hera/Intel"
}

module-whatis "loads prerequisites for Hera/Intel"

module use -a /contrib/cmake/modulefiles
module load cmake/3.16.1
setenv CMAKE_C_COMPILER mpiicc
setenv CMAKE_CXX_COMPILER mpiicpc
setenv CMAKE_Fortran_COMPILER mpiifort

module use /scratch2/NCEPDEV/nwprod/hpc-stack/libs/hpc-stack/modulefiles/stack
module load hpc/1.1.0

# Load intel compiler and mpi
module load hpc-gnu/9.2.0
module load hpc-mpich/3.3.2 

module load jasper/2.0.22
module load zlib/1.2.11
module load png/1.6.35

module load hdf5/1.10.6
module load netcdf/4.7.4

module load bacio/2.4.1
module load nemsio/2.5.2
module load w3nco/2.4.1
