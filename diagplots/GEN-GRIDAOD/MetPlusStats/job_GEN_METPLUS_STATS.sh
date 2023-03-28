#!/bin/bash --login

#SBATCH --output=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/metplus.out
#SBATCH --job-name=met_series_anl-NRT-NODA-cntlBckg.aod-NASAana.AODANA
#SBATCH --qos=debug
#SBATCH --time=00:29:00
#SBATCH --nodes=1 --ntasks-per-node=1 --cpus-per-task=1
#SBATCH --account=chem-var

#/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/metPlusDiag/metPlusOutput//wrk-NRT-NODA-cntlBckg-NASAana-2022010100-2022043018-1.0deg/met_series_anl//viirs-m_npp-viirs-m_npp/met_series_anl-NRT-NODA-cntlBckg.aod-NASAana.AODANA.out

export OMP_NUM_THREADS=1

set -x
# Comparison between 2 models at pressure level as a time series.
# Requirements
# 1. If both models are in NetCDF, ensure they have the same vertical layers for comparison
#    and in same top-down or down-top order.
# 2. List all the pres layers in NetCDF files
# 3. List the name of variables that are desired to compare in the corresponding order.
#  
# main.conf: define input and output base.
# 
# Setup SDATE, EDATE, INCH, GRID_NAME, FCST_NAME, OBS_NAME, FCST_VAR, FCST_VARLEV, OBS_VAR, OBS_VARLEV, 
#       FCSTFILETMP, OBSFILETMP, OUTPUTFILE_NAME
# SDATE: start date of evaluation
# EDATE: end date of evaluation
# INC_H: increment of hours
# GRID_NAME: GXXX from https://www.nco.ncep.noaa.gov/pmb/docs/on388/tableb.html
#            G002 2.5 deg by 2.5 deg
#            G004 0.5 deg by 0.5 deg
# PLEV: All the pressure levels in NetCDF files
# FCST/OBSPATH: The path saved forecast and obs data files.
# FCST/OBSFILETMP: The name that can be searched under FCST/OBSPATH
# 
#




#if [ -d /glade/scratch ]; then
#   export machine=Cheyenne
#elif [ -d /scratch1/NCEPDEV/da ]; then
#   export machine=Hera
#fi
#source $BASE/ush/met_load.sh


#
# User defined variables
#
FREERUNEXP="FreeRun-1C192-0C192-201710"
AERODAEXP="AeroDA-1C192-20C192-201710"
EXPRUNS=${EXPRUNS:-"${FREERUNEXP} ${AERODAEXP}"}
#EXPRUNS=${EXPRUNS:-"${AERODAEXP}"}

MERRA2ANL="MERRA2"
CAMSIRAANL="CAMSIRA"
OBSTYPES=${OBSTYPES:-"${MERRA2ANL} ${CAMSIRAANL}"}
#OBSTYPES=${OBSTYPES:-"${CAMSIRAANL}"}


WRKD=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/UFS-Aerosols/TestScripts/FV3AOD/METPlusRun

SDATE=${SDATE:-"2017101000"}
EDATE=${EDATE:-"2017102718"}

machine=${machine:-"Hera"}
BASE=${BASE:-"/home/Bo.Huang/JEDI-2020/miscScripts-home/METPlus/METplus-AerosoDiag/METplus_pkg/"}
INC_H=${INC_H:-"6"}
NRTOUTPUT=${NRTOUTPUT-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/UfsData/LatLonGrid/metPlusStats-AOD"}
INPUTBASE=${INPUTBASE:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/UfsData/LatLonGrid"}
OBSBASE=${OBSBASE:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/UfsData/LatLonGrid"}
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}
SENSOR=${SENSOR:-"v.viirs-m_npp"}

#EDATE=`${NDATE} 18  ${SDATE}`
#YMD_S=`echo ${SDATE} | cut -c 1-8`

source $BASE/ush/met_load.sh
rc=$?
if [ $rc -ne 0 ]; then
   exit $rc
fi

GRID_NAME="G003" # 1.o deg
PLEV="100 250 400 500 600 700 850 925 1000"

for EXPRUN in ${EXPRUNS}; do
    if [ ${EXPRUN} = ${AERODAEXP} ]; then
        FIELDS="cntlBkg cntlAnl ensmBkg ensmAnl"
        #FIELDS="ensmAnl"
    elif [ ${EXPRUN} = ${FREERUNEXP} ]; then
        FIELDS="cntlBkg"
    else
	echo "Not valid exprun and exit."
	exit 1
    fi

for FIELD in ${FIELDS}; do
    FCSTPATH=${INPUTBASE}/FV3/AOD/${EXPRUN}/${FIELD}/

    FCST_NAME="${EXPRUN}-${FIELD}"

    FCST_HEAD="fv3_aod_${SENSOR}_"
    FCST_SUFF="_ll.nc"
    FCST_VAR="aod"
    FCST_VARDIM="4"
    SIGLEV="TRUE"

for OBSTYPE in ${OBSTYPES}; do
    OBSPATH=$OBSBASE/${OBSTYPE}/AOD/
    if [ ${OBSTYPE} = ${CAMSIRAANL} ]; then
        OBS_NAME=${CAMSIRAANL}
        OBS_HEAD="camsira_aod_"
        OBS_SUFF="_ll.nc"
        OBS_VAR="aod550"
        OBS_VARDIM="3"
    elif [ ${OBSTYPE} = ${MERRA2ANL} ]; then
        OBS_NAME=${MERRA2ANL}
        OBS_HEAD="merra2_aod_"
        OBS_SUFF="_ll.nc"
        OBS_VAR="AODANA"
        OBS_VARDIM="3"
    else
        echo "Not valid observation and exit"
        exit 1
    fi

OUTPUTDIR=${NRTOUTPUT}/${FCST_NAME}_${OBS_NAME}/${SDATE}-${EDATE}
[[ ! -d ${OUTPUTDIR} ]] & mkdir -p ${OUTPUTDIR}

#STMP="/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/$USER/"
#RUNDIR="$STMP/RUNDIRS/$PSLOT"
#WRKD=$RUNDIR/$SDATE/$CDUMP/prepmetplus_aod_ana_${FCST_NAME}_${OBS_NAME}
#WRKD=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/nrtDisplay/aodAna/prepmetplos_aodana/tmpRun/prepmetplus_aod_ana_${FCST_NAME}_${OBS_NAME}
OUTPUTBASE=${WRKD}

[[  -d ${WRKD} ]] && rm -rf ${WRKD} 
mkdir -p ${WRKD}
#
# Default variables
#

FCSTFILETMP="${FCST_HEAD}*${FCST_SUFF}"
OBSFILETMP="${OBS_HEAD}*${OBS_SUFF}"
#NDATE="python $BASE/bin/ndate.py"
CONFIG_DIR=$BASE/conf
INCONFIG=${CONFIG_DIR}/SeriesAnalysis.conf.IN
MAINCONF=$CONFIG_DIR/main.conf.IN
MASTER=$METPLUS_PATH/ush/master_metplus.py


cd $WRKD
mkdir -p $WRKD/fcst $WRKD/obs

FCSTDIR=$WRKD/fcst
OBSDIR=$WRKD/obs

CDATE=$SDATE
while [ $CDATE -le $EDATE ];
do
  CY=${CDATE:0:4}
  CM=${CDATE:4:2}
  CD=${CDATE:6:2}
  CH=${CDATE:8:2}
  ln -sf $FCSTPATH/${CY}/${CY}${CM}/${CY}${CM}${CD}/${FCST_HEAD}${CDATE}${FCST_SUFF} ./fcst
  ln -sf $OBSPATH/${CY}/${CY}${CM}/${CY}${CM}${CD}/${OBS_HEAD}${CDATE}${OBS_SUFF} ./obs
  CDATE=`$NDATE $INC_H $CDATE`
done

if [ ${SIGLEV} == "TRUE" ]; then
    FPLEVLIST=("sigLev")
    FNCLVIDXLIST=(2)

    OPLEVLIST=("sigLev")
    ONCLVIDXLIST=(0)
else
    FPLEVLIST=(100 250 400 500 600 700 850 925 1000)
    FNCLVIDXLIST=(0 1 2 3 4 5 6 7 8)

    OPLEVLIST=(100 250 400 500 600 700 850 925 1000)
    ONCLVIDXLIST=(0 1 2 3 4 5 6 7 8)
fi

nplv=${#FPLEVLIST[*]}

echo ${nplv}

np=0
while [[ $np -lt $nplv ]];
do
    PLEV=${FPLEVLIST[$np]}
    FCST_VARLEV="\"(0,${FNCLVIDXLIST[$np]},*,*)\""
    OBS_VARLEV="\"(0,${ONCLVIDXLIST[$np]},*,*)\""

    if [ ${FCST_VARDIM} == "3" ]; then
       FCST_VARLEV="\"(0,*,*)\""
    fi

    if [ ${OBS_VARDIM} == "3" ]; then
       OBS_VARLEV="\"(0,*,*)\""
    fi

    OUTPUTTMP="${FCST_VAR}_${PLEV}hPa.nc"

    echo $FCST_VAR $FCST_VARLEV
    echo $OBS_VAR $OBS_VARLEV
    echo $OUTPUTTMP

#if [ "YES" == "NO" ]; then
cat $MAINCONF | sed s:_MET_PATH_:${MET_PATH}:g \
              | sed s:_INPUTBASE_:${INPUTBASE}:g \
              | sed s:_OUTPUTBASE_:${OUTPUTBASE}:g \
              > ./main.conf 

cat $INCONFIG | sed s:_SDATE_:${SDATE}:g \
              | sed s:_EDATE_:${EDATE}:g \
              | sed s:_INC_H_:${INC_H}:g \
              | sed s:_BASE_:${BASE}:g \
              | sed s:_GRID_NAME_:${GRID_NAME}:g \
              | sed s:_FCST_NAME_:${FCST_NAME}:g \
              | sed s:_OBS_NAME_:${OBS_NAME}:g \
              | sed s:_FCST_VAR_:${FCST_VAR}:g \
              | sed s:_FCST_VARLEV_:${FCST_VARLEV}:g \
              | sed s:_OBS_VAR_:${OBS_VAR}:g \
              | sed s:_OBS_VARLEV_:${OBS_VARLEV}:g \
              | sed s:_FCSTDIR_:${FCSTDIR}:g \
              | sed s:_OBSDIR_:${OBSDIR}:g \
              | sed s:_FCSTFILETMP_:"${FCSTFILETMP}":g \
              | sed s:_OBSFILETMP_:"${OBSFILETMP}":g \
              | sed s:_OUTPUTTMP_:${OUTPUTTMP}:g \
              > ./SeriesAnalysis.${OBS_VAR}_${PLEV}hPa.conf
#fi

time $MASTER -c ./main.conf -c ./SeriesAnalysis.${OBS_VAR}_${PLEV}hPa.conf

err=$?
if [ ${err} != '0' ]; then
    echo "METPlus failed at ${SDATE} for ${FCST_NAME}_${OBS_NAME} and exit!"
    exit 1
else
    echo "METPlus succeeded at ${SDATE} for ${FCST_NAME}-${OBS_NAME} and proceed to next step!"
    mv ${WRKD}/met_tool_wrapper/SeriesAnalysis/aod_sigLevhPa.nc ${OUTPUTDIR}
   # rm -rf $WRKD
fi

let np=np+1
done

done # OBSTYPE
done # FIELD
done # EXPRUN

exit ${err}
