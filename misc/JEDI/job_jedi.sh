#!/bin/bash 
#SBATCH --output=./metplus.out
#SBATCH --job-name=jedi-test
#SBATCH --qos=debug
#SBATCH --time=00:29:00
#SBATCH --nodes=12 --ntasks-per-node=12 --cpus-per-task=1
#SBATCH --account=chem-var

##!/bin/bash
##SBATCH -n 144
##SBATCH -t 00:30:00
##SBATCH -q debug
##SBATCH -A chem-var
##SBATCH -J fgat
##SBATCH -D ./
##SBATCH -o ./bump_gfs_c96.out
##SBATCH -e ./bump_gfs_c96.out

#sbatch --export=ALL sbatch_hofx_gfs_aero.sh

vdir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/V20230312/build/

source ${vdir}/jedi_module_base.hera.sh

export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${vdir}/lib"
export OMP_NUM_THREADS=1

srun --export=all -n 144 ./fv3jedi_var.x hyb-3dvar_gfs_aero_NOAA_VIIRS.yaml hyb-3dvar_gfs_aero_NOAA_VIIRS.run
#srun --export=all -n 144 ${vdir}/bin/fv3jedi_var.x "hyb-3dvar_gfs_aero.yaml" "logs/hyb-3dvar_gfs_aero.run"
