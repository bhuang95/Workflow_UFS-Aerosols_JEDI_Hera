#!/bin/bash
################################################################################
####  UNIX Script Documentation Block
#                      .                                             .
# Script name:
# Script description:
#
# Author:                    Org: NCEP/EMC     Date:           
#
# Abstract: This script makes an analysis using JEDI               
#           NOTE quick and dirty for Aerosol 3DEnVar
#
# $Id$
#
# Attributes:
#   Language: POSIX shell
#   Machine: WCOSS-Dell / Hera
#
################################################################################

#  Set environment.
export VERBOSE=${VERBOSE:-"YES"}
if [ $VERBOSE = "YES" ]; then
   echo $(date) EXECUTING $0 $* >&2
   set -x
fi

#  Directories.
pwd=$(pwd)
export NWPROD=${NWPROD:-"$pwd"}
export HOMEgfs=${HOMEgfs:-"$NWPROD"}
export HOMEjedi=${HOMEjedi:-"$HOMEgfs/sorc/jedi.fd/"}
export DATA=${DATA:-"$pwd/analysis.$$"}
export COMIN=${COMIN:-"$pwd"}
export COMIN_OBS=${COMIN_OBS:-"$COMIN"}
export COMIN_GES=${COMIN_GES:-"$COMIN"}
export COMIN_GES_ENS=${COMIN_GES_ENS:-"$COMIN_GES"}
export COMPONENT=${COMPONENT:-"atmos"}
export COMOUT=${COMOUT:-"$COMOUT"}
export JEDIUSH=${JEDIUSH:-"$HOMEgfs/ush/JEDI/"}
export AODTYPE=${AODTYPE:-"VIIRS"}
export RPLTRCRVARS=${RPLTRCRVARS:-""}
export RPLEXEC="${HOMEgfs}/ush/python/replace_aeroanl_restart.py"

# Base variables
CDATE=${CDATE:-"2001010100"}
CDUMP=${CDUMP:-"gdas"}
GDUMP=${GDUMP:-"gdas"}

# Derived base variables
GDATE=$($NDATE -$assim_freq $CDATE)
BDATE=$($NDATE -3 $CDATE)
PDY=$(echo $CDATE | cut -c1-8)
cyc=$(echo $CDATE | cut -c9-10)
bPDY=$(echo $BDATE | cut -c1-8)
bcyc=$(echo $BDATE | cut -c9-10)
gPDY=$(echo $GDATE | cut -c1-8)
gcyc=$(echo $GDATE | cut -c9-10)
CYMD=${PDY}
CH=${cyc}

# Utilities
export NCP=${NCP:-"/bin/cp"}
export NMV=${NMV:-"/bin/mv"}
export NRM=${NRM:-"/bin/rm -rf"}
export NLN=${NLN:-"/bin/ln -sf"}

# FV3 specific info
export CASE=${CASE:-"C384"}
ntiles=${ntiles:-6}

# Observations
OPREFIX=${OPREFIX:-""}
OSUFFIX=${OSUFFIX:-""}

# Guess files
GPREFIX=${GPREFIX:-""}
GSUFFIX=${GSUFFIX:-$SUFFIX}

# Analysis files
export APREFIX=${APREFIX:-""}
export ASUFFIX=${ASUFFIX:-$SUFFIX}

# run python script to handle heavy lifting
#$JEDIUSH/run_aero_3denvar.py

# prepare for JEDI-var update
$JEDIUSH/run_jedi_aeroanl_3denvar_nasaluts_yaml.sh

# run JEDI
#source /apps/lmod/7.7.18/init/ksh
#. ${HOMEjedi}/jedi_module_base.hera
#module purge
#export JEDI_OPT="/scratch1/NCEPDEV/jcsda/jedipara/opt/modules"
#module use $JEDI_OPT/modulefiles/core
#module load jedi/intel-impi/2020.2
#module load cmake/3.20.1
##module load nco ncview ncl
#module list
source ${HOMEjedi}/jedi_module_base.hera.sh
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${HOMEjedi}/lib/"
export OMP_NUM_THREADS=1

echo $LD_LIBRARY_PATH

srun --export=all -n ${ncore_envar} ./fv3jedi_var.x hyb-3dvar_gfs_aero.yaml hyb-3dvar_gfs-aero.run
ERR=$?

if [ ${ERR} -ne 0 ]; then
   echo "JEDI 3denvar failed and exit the program!!!"
   exit 1
fi

# we need to now do some ncks things on the deterministic run
# Geberate analysis files by replacing the backgorund file wiht updated aerosol analysis
mkdir -p ${DATA}/RPLVARS
cd ${DATA}/RPLVARS
ITILE=1
while [[ ${ITILE} -le 6 ]]; do
    GESFILE=${COMIN_GES}/${COMPONENT}/RESTART/${CYMD}.${CH}0000.fv_tracer.res.tile${ITILE}.nc
    ANLFILE=${COMIN_GES}/${COMPONENT}/RESTART/${CYMD}.${CH}0000.fv_tracer_aeroanl.res.tile${ITILE}.nc
    ANLFILE_TMP=${COMIN_GES}/${COMPONENT}/RESTART/${CYMD}.${CH}0000.fv_tracer_aeroanl_tmp.res.tile${ITILE}.nc
    ${NCP} ${GESFILE} ${ANLFILE}
    ${NLN} ${ANLFILE_TMP} ./input.tile${ITILE}
    ${NLN} ${ANLFILE} ./output.tile${ITILE}
    #${NLN} ${GESFILE} ./ges.tile${ITILE}
    ITILE=$((ITILE+1))
done

echo ${RPLTRCRVARS} > INVARS.nml
${NCP} ${RPLEXEC} ./replace_aeroanl_restart.py

srun --export=all -n 1 python replace_aeroanl_restart.py -v INVARS.nml

ERR=$?
if  [ ${ERR} -ne 0 ]; then
    echo "ReplaceVars run failed and exit the program!!!"
    exit ${ERR}
#else
#    ${NRM} ${COMIN_GES}/${COMPONENT}/RESTART/${CYMD}.${CH}0000.fv_tracer_aeroanl_tmp.res.tile?.nc
fi

cd ${DATA}
################################################################################
# Send alerts
#if [ $SENDDBN = "YES" ]; then
#    if [ $RUN = "gdas" ]; then
#       $DBNROOT/bin/dbn_alert MODEL GDASRADSTAT $job $RADSTAT
#    fi
#    if [ $RUN = "gfs" ]; then
#       $DBNROOT/bin/dbn_alert MODEL GFS_abias $job $ABIAS
#    fi
#fi

################################################################################
# Postprocessing
cd $pwd
#mkdata="YES"
#[[ $mkdata = "YES" ]] && rm -rf $DATA

set +x
if [ $VERBOSE = "YES" ]; then
   echo $(date) EXITING $0 with return code $err >&2
fi
exit $err
