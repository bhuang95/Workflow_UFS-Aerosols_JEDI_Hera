#!/bin/bash
##SBATCH -n 1
##SBATCH -t 00:30:00
##SBATCH -p service
##SBATCH -A chem-var
##SBATCH -J fgat
##SBATCH -D ./
##SBATCH -o ./bump_gfs_c96.out
##SBATCH -e ./bump_gfs_c96.out

set -x 

module use -a /contrib/anaconda/modulefiles
module load anaconda/latest

codedir="/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/UFS-Aerosols/TestScripts/diag/2D-AOD-HOFX/"
plotdir="./plots"

[[ ! -d ${plotdir} ]]; mkdir -p ${plotdir}

cp plt_VIIRS_AOD_HOFX_IODAV3.py ${plotdir}/plt_VIIRS_AOD_HOFX_IODAV3.py

cycst=2017100812
cyced=2017100812
cycinc=6
aeroda=False
emean=False
prefix=AeroDA
#datadir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/AeroDA-1C192-20C192-201710/dr-data-backup
datadir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/FreeRun-1C192-0C192-201710/dr-data-backup

ndate=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

cd ${plotdir}

cyc=${cycst}
while [ ${cyc} -le ${cyced} ]; do
    echo ${cyc}
    python plt_VIIRS_AOD_HOFX_IODAV3.py -c ${cyc} -i ${cycinc} -a ${aeroda} -m ${emean} -p ${prefix} -t ${datadir}
    ERR=$?
    [[ ${ERR} -ne 0 ]] && exit 100
    cyc=$(${ndate} ${cinc} ${cyc})
done

exit
