#!/bin/csh
#SBATCH -N 1
#SBATCH -t 00:30:00
#SBATCH -q debug
#SBATCH -A chem-var
#SBATCH -J fgat
#SBATCH -D ./
#SBATCH -o ./bump_gfs_c96.out
#SBATCH -e ./bump_gfs_c96.out

#sbatch --export=ALL sbatch_hofx_gfs_aero.sh


set vdir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/codeDev/JEDI/jedi-bundle/20230113/build/
source ${vdir}/../jedi_module_base.hera.csh

setenv LD_LIBRARY_PATH "${LD_LIBRARY_PATH}:${vdir}/lib"
setenv  OMP_NUM_THREADS 1

srun -n 6 ${vdir}/bin/fv3jedi_var.x "hyb-3dvar_gfs_aero.yaml" "logs/hyb-3dvar_gfs_aero.run"
