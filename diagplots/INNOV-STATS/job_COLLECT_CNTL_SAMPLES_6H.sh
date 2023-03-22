#!/bin/bash
#SBATCH -J innov_stats
#SBATCH -A wrf-chem
#SBATCH -o /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/misc/innov_stats.out
#SBATCH -e /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/misc/innov_stats.out
#SBATCH -n 1
#SBATCH -p service
#SBATCH -t 00:30:00

set -x
module use -a /contrib/anaconda/modulefiles
module load anaconda/latest

curdir=`pwd`
aod=NOAA-VIIRS
cycst=2017100600
cyced=2017102318
topexpdir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols
topplotdir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/AeroDA-1C192-20C192-201710/diagplots/INNOV-STATS/
nodaexp=FreeRun-1C192-0C192-201710
daexp=AeroDA-1C192-20C192-201710
spinupcnts=20 # number of cycles
rundir=${topplotdir}/${aod}-${cycst}-${cyced}/
#/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/AeroDA-1C192-20C192-201710/diagplots/HOFX-STATS/
expnames="
    ${nodaexp}
    ${daexp}
"

aeroda="True"
emeandiag="True"
for expname in ${expnames}; do
    if [[ "${expname}" == *"FreeRun"* ]]; then
        aeroda="False"
        emeandiag="False"
    else
        aeroda="True"
        emeandiag="True"
    fi

    expdir=${rundir}/${expname} 
    [[ ! -d ${expdir} ]] && mkdir -p ${expdir}

    echo ${expdir}
    cd ${expdir}
    cp -r ${curdir}/COLLECT_CNTL_SAMPLES_6H.py ./COLLECT_CNTL_SAMPLES_6H.py

    python COLLECT_CNTL_SAMPLES_6H.py -i ${cycst} -j ${cyced} -a ${aeroda} -m ${emeandiag} -e ${expname} -d ${topexpdir}
    
    [[ $? -ne 0 ]] && exit 100

#cat << EOF > job_${expname}.sh
##!/bin/bash
##SBATCH -J nemsio2nc_run 
##SBATCH -A wrf-chem
##SBATCH -o /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/misc/${expname}_hfxstats.out
##SBATCH -e /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/misc/${expname}_hfxstats.out
##SBATCH -n 1
##SBATCH -q service
##SBATCH -t 00:30:00
#
#set -x
#module load anaconda/latest
#
#echo \`date\`
#python COLLECT_CNTL_SAMPLES_6H.py -i ${cycst} -j ${cyced} -a ${aeroda} -m ${emean} -e ${expname} -d ${topexpdir}
#ERR=\$?
#echo \`date\`
#
#exit \${ERR}
#EOF
#
#sbatch job_${expname}.sh
done

cp ${curdir}/plt_AOD_STATS.py ${rundir}/
cd ${rundir}
python plt_AOD_STATS.py -i ${cycst} -j ${cyced} -e ${nodaexp} -f ${daexp} -s ${spinupcnts}
exit 0

