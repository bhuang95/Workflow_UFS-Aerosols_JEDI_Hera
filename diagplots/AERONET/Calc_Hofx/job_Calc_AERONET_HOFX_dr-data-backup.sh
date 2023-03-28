#!/bin/bash
#SBATCH -N 1
#SBATCH -t 00:30:00
#SBATCH -q debug
#SBATCH -A chem-var
#SBATCH -J calc_aeronet_hfx
#SBATCH -D ./
#SBATCH -o /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/calc_aeronet_hfx.log
#SBATCH -e /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/calc_aeronet_hfx.log

SDATE=2017102400
EDATE=2017102718
CYCINC=6
TOPEXPDIR='/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/'
EXPNAMES='FreeRun-1C192-0C192-201710 AeroDA-1C192-20C192-201710'
TMPDIR='/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/UFS-Aerosols/TestScripts/AERONET/tmpdir'
NDATE='/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate'

export HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/"}
export HOMEjedi=${HOMEjedi:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/V20230312/build"}
source ${HOMEjedi}/jedi_module_base.hera.sh
status=$?
[[ $status -ne 0 ]] && exit $status

export JEDIDIR=${HOMEjedi:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/V20230312/build"}
export AODTYPE=${AODTYPE:-"AERONET_AOD15"}
export OBSDIR=${OBSDIR:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/DATA/OBS/AERONET_solar_AOD15"}
export CDUMP=${CDUMP:-"gdas"}
export LEVS=${LEVS:-"128"}
export CASE_CNTL=${CASE_CNTL:-"C192"}
export CASE_ENKF=${CASE_ENKF:-"C192"}
export COMPONENT=${COMPONENT:-"atmos"}
export NCORES="6" #${ncore_hofx:-"6"}
export LAYOUT="1,1" #${layout_hofx:-"1,1"}
export IO_LAYOUT="1,1" #${io_layout_hofx:-"1,1"}
export assim_freq=${assim_freq:-"6"}
export DATA=${TMPDIR}

#export JEDIUSH=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/UFS-Aerosols/TestScripts/AERONET
export JEDIUSH=${HOMEgfs}/ush/JEDI/

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

for EXPNAME in ${EXPNAMES}; do
    export ROTDIR=${TOPEXPDIR}/${EXPNAME}/dr-data-backup
    if [[ "${EXPNAME}" == *"FreeRun"* ]]; then
        # if this is freerun, set aeroda=FALSE
        export AERODA='FALSE'
    else
        export AERODA='TRUE'
    fi

    CDATE1=${SDATE}
    while [ ${CDATE1} -le ${EDATE} ]; do
        export CDATE=${CDATE1}

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

        ### Determine what to field to perform
        HOFXFIELDS="cntlbckg"

        if [ ${AERODA} = "TRUE" ]; then
            HOFXFIELDS="${HOFXFIELDS} cntlanal"
        fi

        echo "HOFXFIELDS=${HOFXFIELDS}"

        [[ -z ${HOFXFIELDS} ]] && { echo "HOFXFIELDS is empty" ; exit 1; }

        ENKFOPT=""
        export CASE=${CASE_CNTL}
        MEMOPT=""
        MEMSTR=""

        for FIELD in ${HOFXFIELDS}; do

            if [ ${FIELD} = "cntlanal" ]; then
               export TRCR="fv_tracer_aeroanl"
            else
               export TRCR="fv_tracer"
            fi

            export RSTDIR=${ROTDIR}/${ENKFOPT}gdas.${GYMD}/${GH}/${COMPONENT}/${MEMOPT}${MEMSTR}/RESTART/
            export HOFXDIR=${ROTDIR}/${ENKFOPT}gdas.${CYMD}/${CH}/diag/${MEMOPT}${MEMSTR}

            [[ ! -d ${HOFXDIR} ]] && mkdir -p  ${HOFXDIR}
            [[ !  -d ${DATA} ]] && mkdir -p ${DATA}
	    cd ${DATA}

            echo "Running run_hofx_nomodel_AOD_LUTs for ${FIELD}-${TRCR}"
            echo ${RSTDIR}
            echo ${HOFXDIR}
            ${JEDIUSH}/run_jedi_hofx_nomodel_nasaluts_dr-data-backup.sh
            ERR=$?
            if [ ${ERR} -ne 0 ]; then
                echo "run_hofx_nomodel_AOD_LUTs failed for ${FIELD}-${TRCR} and exit"
                exit 1
            fi

            export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${HOMEjedi}/lib/"
            export OMP_NUM_THREADS=1
            ulimit -s unlimited

            srun --export=all -n ${NCORES} ./fv3jedi_hofx_nomodel.x "./hofx_nomodel_aero_${AODTYPE}.yaml" "./hofx_nomodel_aero.log"
            ERR=$?
            if [ ${ERR} -ne 0 ]; then
                echo "JEDI hofx failed and exit the program!!!"
                exit ${ERR}
            else
        	echo "run_hofx_nomodel_AOD_LUTs completed for ${FIELD}-${TRCR} and move on"
		rm -rf ${DATA}
            fi
        done
    CDATE1=$(${NDATE} ${CYCINC} ${CDATE1})
    done
done
###############################################################
# Postprocessing
#mkdata="YES"
#[[ $mkdata = "YES" ]] && rm -rf ${DATA1}

#set +x
exit ${ERR}
