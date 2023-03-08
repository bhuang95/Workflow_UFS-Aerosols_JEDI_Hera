#!/bin/ksh -x

###############################################################
## Abstract:
## Calculate increment of Met. fields for FV3-CHEM
## RUN_ENVIR : runtime environment (emc | nco)
## HOMEgfs   : /full/path/to/workflow
## EXPDIR : /full/path/to/config/files
## CDATE  : current date (YYYYMMDDHH)
## CDUMP  : cycle name (gdas / gfs)
## PDY    : current date (YYYYMMDD)
## cyc    : current cycle (HH)
###############################################################
# Source FV3GFS workflow modules
source "${HOMEgfs}/ush/preamble.sh"
. $HOMEgfs/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

export job="calcinc"
export jobid="${job}.$$"
export DATA=${DATA:-${DATAROOT}/${jobid}}

###############################################################
# Source relevant configs
configs="base"
for config in $configs; do
    . $EXPDIR/config.${config}
    status=$?
    [[ $status -ne 0 ]] && exit $status
done

[[ $status -ne 0 ]] && exit $status

ulimit -s unlimited
###############################################################
export CASE_CNTL=${CASE_CNTL:-"C96"}
export CDATE=${CDATE:-"2017110100"}
export ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/dr-data"}
export assim_freq=${assim_freq:-"6"}
export CDUMP=${CDUMP:-"gdas"}
export COMPONET=${COMPONENT:-"atmos"}

GDATE=`$NDATE -$assim_freq ${CDATE}`
GDASDIR=${ROTDIR}/RetieveGDAS

CALCINCNCEXEC=${CALCINCNCEXEC:-$HOMEgfs/exec/calc_increment_ens_ncio.x}
NTHREADS_CALCINC=${NTHREADS_CALCINC:-1}
ncmd=${ncmd:-1}
imp_physics=${imp_physics:-99}
INCREMENTS_TO_ZERO=${INCREMENTS_TO_ZERO:-"'NONE'"}
DO_CALC_INCREMENT=${DO_CALC_INCREMENT:-"YES"}

CYMD=${CDATE:0:8}
CH=${CDATE:8:2}
GYMD=${CDATE:0:8}
GH=${CDATE:8:2}

FHR=${assim_freq}
typeset -Z3 FHR

mkdir -p $DATA
cd $DATA

$NCP $CALCINCNCEXEC ./calc_inc.x

  # deterministic run first

  export OMP_NUM_THREADS=$NTHREADS_CALCINC
  mkdir -p $ROTDIR/${CDUMP}.$PDY/$cyc/$mem/
  BKGFILE=${ROTDIR}/${CDUMP}.${GYMD}/${GH}/${COMPONENT}/${CDUMP}.t${GH}z.atmf${FHR}.nc 
  INCFILE=${ROTDIR}/${CDUMP}.${CYMD}/${CH}/${COMPONENT}/${CDUMP}.t${CH}z.atmfinc.nc
  ANLFILE=${GDASDIR}/${CDUMP}.${CYMD}/${CH}/${CDUMP}.t${CH}z.atmanl.nc

  ${NLN} ${BKGFILE} atmges_mem001
  ${NLN} ${ANLFILE} atmanl_mem001
  ${NLN} ${INCFILE} atminc_mem001

  rm calc_increment.nml
  cat > calc_increment.nml << EOF
&setup
  datapath = './'
  analysis_filename = 'atmanl'
  firstguess_filename = 'atmges'
  increment_filename = 'atminc'
  debug = .false.
  nens = 1
  imp_physics = $imp_physics
/
&zeroinc
  incvars_to_zero = $INCREMENTS_TO_ZERO
/
EOF
  cat calc_increment.nml

  srun --export=all -n 1 ./calc_inc.x
  ERR=$?
  if [[ $ERR != 0 ]]; then
      exit ${ERR}
  fi
  #export ERR=$rc
  #export err=$ERR
  #$ERRSCRIPT || exit 3
  unlink atmges_mem001
  unlink atmanl_mem001
  unlink atminc_mem001

#set +x 
if [ $VERBOSE = "YES" ]; then
   echo $(date) EXITING $0 with return code $err >&2
fi

rm -rf ${DATA}/calcinc.$$
exit ${ERR}
###############################################################

###############################################################
# Exit cleanly
