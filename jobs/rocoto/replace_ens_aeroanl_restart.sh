#! /usr/bin/env bash

source "${HOMEgfs}/ush/preamble.sh"

###############################################################
# Source FV3GFS workflow modules
. ${HOMEgfs}/ush/load_fv3gfs_modules.sh
status=$?
[[ ${status} -ne 0 ]] && exit ${status}

export job="rpl_ens_aeroanl"
export jobid="${job}.$$"
export DATA=${DATA:-${DATAROOT}/${jobid}}

source "${HOMEgfs}/ush/jjob_header.sh" -e "aeroanlrun" -c "base aeroanlrun"

##############################################
# Set variables used in the script
##############################################
export CDATE=${CDATE:-"2021021900"}
export assim_freq=${assim_freq:-"6"}
export CDUMP=${CDUMP:-${RUN:-"gdas"}}
export COMPONENT="atmos"
export ROTDIR=${ROTDIR:-""}
export ENSGRP=${ENSGRP:-"01"}
export NMEM_EFCSGRP=${NMEM_EFCSGRP:-"2"}
export REPLACEEXEC=${HOMEgfs}/ush/python/replace_aeroanl_restart.py

ENSED=$((NMEM_EFCSGRP * ${ENSGRP}))
if [ ${ENSGRP} -eq 1 ]; then
    ENSST=0
else
    ENSST=$((ENSED - NMEM_EFCSGRP + 1))
fi

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NLN="/bin/ln -sf"

GDATE=$(date +%Y%m%d%H -d "${CDATE:0:8} ${CDATE:8:2} - ${assim_freq} hours")

CYMD=${CDATE:0:8}
CH=${CDATE:8:2}

GYMD=${GDATE:0:8}
GH=${GDATE:8:2}

GENSDIR=${ROTDIR}/enkfgdas.${GYMD}/${GH}
ANLPREFIX=${CYMD}.${CH}0000
TRCRBCKG="fv_tracer.res"
TRCRJEDI="fv_tracer_aeroanl_tmp.res"
TRCRRPL="fv_tracer_aeroanl.res"
TRCRRCE="fv_tracer_raeroanl.res"
JEDIPREFIX="JEDI"
NEWPREFIX="NEW"
INVARS="so4,bc1,bc2,oc1,oc2,dust1,dust2,dust3,dust4,dust5,seas1,seas2,seas3,seas4,seas5"

# Link ensemble tracer file
IMEM=${ENSST}
while [ ${IMEM} -le ${ENSED} ]; do
    MEMSTR="mem"`printf %03d ${IMEM}`
    if [ ${IMEM} -eq 0 ]; then
        MEMDIR_IN="${GENSDIR}/ensmean/${COMPONENT}/RESTART/"
    else
        MEMDIR_IN="${GENSDIR}/${MEMSTR}/${COMPONENT}/RESTART/"
    fi
    ITILE=1
    while [ ${ITILE} -le 6 ]; do
        TILESTR="tile${ITILE}"

        MEMFILE_IN_BCKG=${MEMDIR_IN}/${ANLPREFIX}.${TRCRBCKG}.${TILESTR}.nc
        MEMFILE_IN_JEDI=${MEMDIR_IN}/${ANLPREFIX}.${TRCRJEDI}.${TILESTR}.nc
        MEMFILE_IN_RPL=${MEMDIR_IN}/${ANLPREFIX}.${TRCRRPL}.${TILESTR}.nc

        MEMFILE_OUT_JEDI=${DATA}/${JEDIPREFIX}.${MEMSTR}.${TILESTR}
        MEMFILE_OUT_NEW=${DATA}/${NEWPREFIX}.${MEMSTR}.${TILESTR}

	${NCP} ${MEMFILE_IN_BCKG} ${MEMFILE_IN_NEW}
	${NLN} ${MEMFILE_IN_JEDI} ${MEMFILE_OUT_JEDI}
	${NLN} ${MEMFILE_IN_NEW} ${MEMFILE_OUT_NEW}

        ITILE=$((ITILE+1))
    done
    IMEM=$((IMEM+1))
done

cd ${DATA}
cp -r ${REPLACEEXEC} ./
echo ${INVARS} > INVARS.nml

python replace_aeroanl_restart.py -i ${JEDIPREFIX} -o ${NEWPREFIX}  -m ${ENSST} -n ${ENSED} -v "INVARS.nml" 

ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}

exit 0
