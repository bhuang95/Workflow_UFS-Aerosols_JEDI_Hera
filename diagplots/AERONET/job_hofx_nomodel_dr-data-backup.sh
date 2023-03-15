#!/bin/bash
#SBATCH -N 1
#SBATCH -t 00:30:00
##SBATCH -p batch
#SBATCH -q debug
#SBATCH -A chem-var
#SBATCH -J fgat
#SBATCH -D ./
#SBATCH -o ./bump_gfs_c96.out
#SBATCH -e ./bump_gfs_c96.out

export HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/"}
export HOMEjedi=${HOMEjedi:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/V20230312/build"}

#source "${HOMEgfs}/ush/preamble.sh"

###############################################################

# Source FV3GFS workflow modules
#. "${HOMEgfs}/ush/load_fv3gfs_modules.sh"
#status=$?
#[[ $status -ne 0 ]] && exit $status

#export job="diag_hofx"
#export jobid="${job}.$$"
#export DATA1=${DATA:-${DATAROOT}/${jobid}}
DATA1=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/UFS-Aerosols/TestScripts/AERONET/Test
 [ ! -d ${DATA1} ] && mkdir -p ${DATA1}
# Source machine runtime environment
#source "${HOMEgfs}/ush/jjob_header.sh" -e "aeroanlrun" -c "base aeroanlrun"

#export ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/dr-data-backup"}
export ROTDIR=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/AeroDA-1C192-20C192-201710/dr-data-backup
export AERODA=${AERODA:-"TRUE"}
# if this is freerun, set aeroda=FALSE
export JEDIDIR=${HOMEjedi:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/V20230312/build"}
export AODTYPE=${AODTYPE:-"AERONET_AOD15"}
export OBSDIR=${OBSDIR:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/DATA/OBS/AERONET_solar_AOD15"}
export CDATE=${CDATE:-"2017100600"}
export CDUMP=${CDUMP:-"gdas"}
export LEVS=${LEVS:-"128"}
export ENSGRP=${ENSGRP:-"01"}
export CASE_CNTL=${CASE_CNTL:-"C192"}
export CASE_ENKF=${CASE_ENKF:-"C192"}
export COMPONENT=${COMPONENT:-"atmos"}
export NCORES="6" #${ncore_hofx:-"6"}
export LAYOUT="1,1" #${layout_hofx:-"1,1"}
export IO_LAYOUT="1,1" #${io_layout_hofx:-"1,1"}
export assim_freq=${assim_freq:-"6"}

#JEDIUSH=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/UFS-Aerosols/TestScripts/AERONET
JEDIUSH=#${HOMEgfs}/ush/JEDI/

GDATE=$(date +%Y%m%d%H -d "${CDATE:0:8} ${CDATE:8:2} - ${assim_freq} hours")

CYMD=${CDATE:0:8}
CY=${CDATE:0:4}
CM=${CDATE:4:2}
CD=${CDATE:6:2}
CH=${CDATE:8:2}

GYMD=${GDATE:0:8}
GY=${GDATE:0:4}
GM=${GDATE:4:2}
GD=${GDATE:6:2}
GH=${GDATE:8:2}

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

mkdir -p ${DATA1}
cd ${DATA1}


### Determine what to field to perform
HOFXFIELDS="cntlbckg"

if [ ${AERODA} = "TRUE" ]; then
    HOFXFIELDS="${HOFXFIELDS} cntlanal"
fi

echo "HOFXFIELDS=${HOFXFIELDS}"

[[ -z ${HOFXFIELDS} ]] && { echo "HOFXFIELDS is empty" ; exit 1; }

for FIELD in ${HOFXFIELDS}; do
    if [ ${FIELD} = "cntlbckg" -o ${FIELD} = "cntlanal" ]; then
        ENKFOPT=""
	export CASE=${CASE_CNTL}
        MEMOPT=""
    fi

    if [ ${FIELD} = "cntlanal" ]; then
       export TRCR="fv_tracer_aeroanl"
    else
       export TRCR="fv_tracer"
    fi

    MEMSTR=""
    export RSTDIR=${ROTDIR}/${ENKFOPT}gdas.${GYMD}/${GH}/${COMPONENT}/${MEMOPT}${MEMSTR}/RESTART/
    export HOFXDIR=${ROTDIR}/${ENKFOPT}gdas.${CYMD}/${CH}/diag/${MEMOPT}${MEMSTR}

    export DATA=${DATA1}/${MEMOPT}${MEMSTR}/${FIELD}
    [[ ! -d ${HOFXDIR} ]] && mkdir -p  ${HOFXDIR}
    [[ ! -d ${DATA} ]] && mkdir -p  ${DATA}
    echo "Running run_hofx_nomodel_AOD_LUTs for ${FIELD}-${TRCR}"
    echo ${RSTDIR}
    echo ${HOFXDIR}
    ${JEDIUSH}/run_jedi_hofx_nomodel_nasaluts_dr-data-backup.sh
    ERR=$?
    if [ ${ERR} -ne 0 ]; then
        echo "run_hofx_nomodel_AOD_LUTs failed for ${FIELD}-${TRCR} and exit"
        exit 1
    else
	echo "run_hofx_nomodel_AOD_LUTs completed for ${FIELD}-${TRCR} and move on"
    fi
done

###############################################################
# Postprocessing
#mkdata="YES"
#[[ $mkdata = "YES" ]] && rm -rf ${DATA1}

#set +x
exit ${ERR}
