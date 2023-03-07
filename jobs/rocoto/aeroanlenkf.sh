#! /usr/bin/env bash

source "${HOMEgfs}/ush/preamble.sh"

###############################################################
# Source UFSDA workflow modules
#. "${HOMEgfs}/ush/load_ufsda_modules.sh"
. "${HOMEgfs}/ush/load_fv3gfs_modules.sh"
status=$?
[[ ${status} -ne 0 ]] && exit "${status}"

export job="aeroanlrun"
export job1="aeroanlenkfrun"
export jobid="${job1}.$$"
export DATA=${DATA:-${DATAROOT}/${jobid}}
export WIPE_DATA="NO"

###############################################################
# Execute the JJOB
#"${HOMEgfs}/jobs/JGDAS_GLOBAL_AERO_ANALYSIS_RUN"
###HBO
#HBO#source "${HOMEgfs}/ush/jjob_header.sh" -e "aeroanlrun" -c "base aeroanl aeroanlrun"
source "${HOMEgfs}/ush/jjob_header.sh" -e "aeroanlrun" -c "base aeroanlrun"

##############################################
# Set variables used in the script
##############################################
export CDATE=${CDATE:-${PDY}${cyc}}
export CDUMP=${CDUMP:-${RUN:-"gfs"}}
#HBO#export COMPONENT="chem"
export COMPONENT="atmos"


##############################################
# Begin JOB SPECIFIC work
##############################################

GDATE=$(date +%Y%m%d%H -d "${CDATE:0:8} ${CDATE:8:2} - ${assim_freq} hours")
export GDATE
gPDY=${GDATE:0:8}
export gcyc=${GDATE:8:2}
export GDUMP=${GDUMP:-"gdas"}

export OPREFIX="${CDUMP}.t${cyc}z."
export GPREFIX="${GDUMP}.t${gcyc}z."
export APREFIX="${CDUMP}.t${cyc}z."
export GSUFFIX=${GSUFFIX:-${SUFFIX}}
export ASUFFIX=${ASUFFIX:-${SUFFIX}}

export COMOUT=${COMOUT:-${ROTDIR}/${CDUMP}.${PDY}/${cyc}/}

mkdir -p "${COMOUT}"

# COMIN_GES and COMIN_GES_ENS are used in script
export COMIN_GES="${ROTDIR}/${GDUMP}.${gPDY}/${gcyc}/"
export COMIN_GES_ENS="${ROTDIR}/enkf${GDUMP}.${gPDY}/${gcyc}/"

###############################################################
# Run relevant script

EXSCRIPT=${GDASAEROENKFRUNSH:-"${HOMEgfs}/scripts/exgdas_global_aeroanl_enkf_run.sh"}
${EXSCRIPT}
status=$?
[[ ${status} -ne 0 ]] && exit ${status}
exit ${status}

##############################################
# End JOB SPECIFIC work
##############################################

##############################################
# Final processing
##############################################
