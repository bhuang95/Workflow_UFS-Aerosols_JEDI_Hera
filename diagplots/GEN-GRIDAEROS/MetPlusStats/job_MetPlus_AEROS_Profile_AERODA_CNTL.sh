#!/bin/bash
#
# Usage: ./runmet_grid_stat_anl_fv3-cams.sh

set -x 

PROJ_ACCOUNT="wrf-chem"
POPOTS="1/1"

CURDIR=`pwd`
METRUN=met_grid_stat_anl
OUTDIR=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/UfsData/LatLonGrid/metPlusStats-AEROS

FREERUNEXP="FreeRun-1C192-0C192-201710"
AERODAEXP="AeroDA-1C192-20C192-201710"

# BASE: The path to METplus package
# INPUTBASE: the path saved dataset files
export RUNNAME=${AERODAEXP}
export FCSTRUNNAME=${AERODAEXP}
export FCSTFIELD="cntlBkg"
export MODELNAME="AeroDA-cntlBkg"
export OBSRUNNAME=${AERODAEXP}
export OBSFIELD="cntlAnl"
export OBSNAME="AeroDA-cntlAnl"
export BASE=/home/Bo.Huang/JEDI-2020/miscScripts-home/METPlus/METplus-AerosoDiag/METplus_pkg/
export INPUTBASE=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/UfsData/LatLonGrid/FV3/AEROS/
export RUNSCRIPT=/home/Bo.Huang/JEDI-2020/miscScripts-home/METPlus/runScripts/${METRUN}.sh

export SDATE=2017100600
export EDATE=2017100606
export INC_H=6
NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

#define model resolution for stat
export GRID_NAME="G003"
GRID_DEG="1.0deg"
#export GRID_NAME="G002"
#GRID_DEG="2.5deg"

WRKDTOP=${OUTDIR}/${FCSTRUNNAME}_${FCSTFIELD}-${OBSRUNNAME}_${OBSFIELD}-${GRID_DEG}


FCST_SRC=${INPUTBASE}/${FCSTRUNNAME}/${FCSTFIELD}/
OBS_SRC=${INPUTBASE}/${OBSRUNNAME}/${OBSFIELD}/
FCST_TMP=${WRKDTOP}/FCST_DATA
OBS_TMP=${WRKDTOP}/OBS_DATA

[[ ! -d ${FCST_TMP} ]] && mkdir -p ${FCST_TMP}
[[ ! -d ${OBS_TMP} ]] && mkdir -p ${OBS_TMP}

rm -rf ${FCST_TMP}/fcst*.nc
rm -rf ${FCST_TMP}/obs*.nc

CDATE=${SDATE}
while [ ${CDATE} -le ${EDATE} ]; do
    CY=${CDATE:0:4}
    CM=${CDATE:4:2}
    CD=${CDATE:6:2}
    CH=${CDATE:8:2}

    FCST_DATA=${FCST_SRC}/${CY}/${CY}${CM}/${CY}${CM}${CD}/fv3_aeros_${CDATE}_pll.nc
    OBS_DATA=${OBS_SRC}/${CY}/${CY}${CM}/${CY}${CM}${CD}/fv3_aeros_${CDATE}_pll.nc

    ln -sf ${FCST_DATA} ${FCST_TMP}/fcst_${CDATE}.nc
    ln -sf ${OBS_DATA} ${OBS_TMP}/obs_${CDATE}.nc
    CDATE=$(${NDATE} ${INC_H} ${CDATE})
done


# set fcst and obs varibales
export FCSTDIR="${FCST_TMP}"
export FCSTINPUTTMP_aeros="fcst_{init?fmt=%Y%m%d%H}.nc"
export FCSTLEV_aeros='"(0,0,*,*)","(0,1,*,*)","(0,2,*,*)","(0,3,*,*)","(0,4,*,*)","(0,5,*,*)","(0,6,*,*)","(0,7,*,*)","(0,8,*,*)"'
export FCSTLEV2_aeros='"0,0,*,*","0,1,*,*","0,2,*,*","0,3,*,*","0,4,*,*","0,5,*,*","0,6,*,*","0,7,*,*","0,8,*,*"'

export OBSDIR="${OBS_TMP}"
export OBSINPUTTMP_aeros="obs_{init?fmt=%Y%m%d%H}.nc"
export OBSLEV_aeros='"(0,0,*,*)","(0,1,*,*)","(0,2,*,*)","(0,3,*,*)","(0,4,*,*)","(0,5,*,*)","(0,6,*,*)","(0,7,*,*)","(0,8,*,*)"'
export OBSLEV2_aeros='"0,0,*,*","0,1,*,*","0,2,*,*","0,3,*,*","0,4,*,*","0,5,*,*","0,6,*,*","0,7,*,*","0,8,*,*"'


#export FCSTINPUTTMP_int="fv3_aeros_int_{init?fmt=%Y%m%d%H}_pll.nc"
#export FCSTLEV_int='"(0,0,*,*)"'
#export FCSTLEV2_int='"0,0,*,*"'

#export FCSTINPUTTMP_aods="fv3_aods_{init?fmt=%Y%m%d%H}_ll.nc"
#export FCSTLEV_aods='"(0,0,*,*)"'
#export FCSTLEV2_aods='"0,0,*,*"'

#export OBSNAME="CAMS"
#export OBSDIR=$INPUTBASE/CAMS//pll
#export OBSINPUTTMP_aeros="cams_aeros_{init?fmt=%Y%m%d%H}_sdtotals.nc"
#export OBSLEV_aeros='"(0,0,*,*)","(0,1,*,*)","(0,2,*,*)","(0,3,*,*)","(0,4,*,*)","(0,5,*,*)","(0,6,*,*)","(0,7,*,*)","(0,8,*,*)"'
#export OBSLEV2_aeros='"0,0,*,*","0,1,*,*","0,2,*,*","0,3,*,*","0,4,*,*","0,5,*,*","0,6,*,*","0,7,*,*","0,8,*,*"'
#export OBSINPUTTMP_aods="cams_aods_{init?fmt=%Y%m%d%H}.nc"
#export OBSLEV_aods='"(0,*,*)"'
#export OBSLEV2_aods='"0,*,*"'

#export OBSNAME="MERRA2"
#export OBSDIR=$INPUTBASE/MERRA2//pll
#export OBSINPUTTMP_aeros="m2_aeros_{init?fmt=%Y%m%d%H}_pll.nc"
#export OBSLEV_aeros='"(0,0,*,*)","(0,1,*,*)","(0,2,*,*)","(0,3,*,*)","(0,4,*,*)","(0,5,*,*)","(0,6,*,*)","(0,7,*,*)","(0,8,*,*)"'
#export OBSLEV2_aeros='"0,0,*,*","0,1,*,*","0,2,*,*","0,3,*,*","0,4,*,*","0,5,*,*","0,6,*,*","0,7,*,*","0,8,*,*"'
#
#export OBSINPUTTMP_int="m2_aeros_int_{init?fmt=%Y%m%d%H}_pll.nc"
#export OBSLEV_int='"(0,0,*,*)"'
#export OBSLEV2_int='"0,0,*,*"'
#
#export OBSINPUTTMP_aods="m2_aods_{init?fmt=%Y%m%d%H}_ll.nc"
#export OBSLEV_aods='"(0,*,*)"'
#export OBSLEV2_aods='"0,*,*"'


# set aerosol varibales to be evaluated
#CAMSiRA (EAC4)		MERRA2/GSDChem
#DUSTTOTAL		DUSTTOTAL
#SEASTOTAL		SEASTOTAL
#aermr01		SEASFINE
#aermr02		SEASMEDIUM
#aermr03		SEASCOARSE
#aermr04		DUSTFINE
#aermr05		DUSTMEDIUM
#aermr06		DUSTCOARSE
#aermr07		OCPHILIC
#aermr08		OCPHOBIC
#aermr09		BCPHILIC
#aermr10		BCPHOBIC
#aermr11		SO4
#aod550			AODANA/aod


#WRKDTOP=$outdir/wrk-fullJEDI-${MODELNAME}-${OBSNAME}-${SDATE}-${EDATE}-${GRID_DEG}/${METRUN}/

nvars=18
FCSTVARS=(DUSTFINE DUSTMEDIUM DUSTCOARSE DUSTTOTAL
          SEASFINE SEASMEDIUM SEASCOARSE SEASTOTAL
	  OCPHOBIC OCPHILIC BCPHOBIC BCPHILIC CPHOBIC CPHILIC CTOTAL 
	  NITRATE1 NITRATE2 NITRATE3)
OBSVARS=${FCSTVARS}

#FCSTVARS_int=(DUSTTOTAL_INTEGRAL SEASTOTAL_INTEGRAL OCPHILIC_INTEGRAL OCPHOBIC_INTEGRAL BCPHILIC_INTEGRAL BCPHOBIC_INTEGRAL SO4_INTEGRAL CPHOBIC_INTEGRAL CPHILIC_INTEGRAL CTOTAL_INTEGRAL)
#OBSVARS_int=(DUSTTOTAL_INTEGRAL SEASTOTAL_INTEGRAL OCPHILIC_INTEGRAL OCPHOBIC_INTEGRAL BCPHILIC_INTEGRAL BCPHOBIC_INTEGRAL SO4_INTEGRAL CPHOBIC_INTEGRAL CPHILIC_INTEGRAL CTOTAL_INTEGRAL)

export MSKLIST="FULL NNPAC TROP CONUS EASIA NAFRME RUSC2S SAFRTROP SOCEAN NATL SATL NPAC SPAC INDOCE"
#export MSKLIST="NNPAC"

if [ -d /glade/scratch ]; then
   export machine=Cheyenne
   export subcmd=$BASE/ush/sub_ncar
elif [ -d /scratch1/NCEPDEV/da ]; then
   export machine=Hera
   export subcmd=$BASE/ush/sub_hera
fi

#Process aerosol species
nvars=1
for ((ivar=0;ivar<${nvars};ivar++))
do
    export FCSTVAR=${FCSTVARS[ivar]}
    export FCSTINPUTTMP=${FCSTINPUTTMP_aeros}
    export FCSTLEV=${FCSTLEV_aeros}
    export FCSTLEV2=${FCSTLEV2_aeros}
    export OBSVAR=${OBSVARS[ivar]}
    export OBSINPUTTMP=${OBSINPUTTMP_aeros}
    export OBSLEV=${OBSLEV_aeros}
    export OBSLEV2=${OBSLEV2_aeros}
    export WRKD=${WRKDTOP}/${FCSTVAR}-${OBSVAR}
    export DATA=$WRKD/tmp
    export OUTPUTBASE=${WRKD}

    cd $WRKD
    /bin/sh $subcmd -a $PROJ_ACCOUNT -p $POPOTS -j $METRUN-${FCSTVAR}-.${OBSVAR} -o ${WRKD}/$METRUN-${FCSTVAR}-${OBSVAR}.out -q debug -t 00:29:00 -r /1 ${RUNSCRIPT}
    #sleep 2

    #export FCSTVAR=${FCSTVARS_int[ivar]}
    #export FCSTINPUTTMP=${FCSTINPUTTMP_int}
    #export FCSTLEV=${FCSTLEV_int}
    #export FCSTLEV2=${FCSTLEV2_int}
    #export OBSVAR=${OBSVARS_int[ivar]}
    #export OBSINPUTTMP=${OBSINPUTTMP_int}
    #export OBSLEV=${OBSLEV_int}
    #export OBSLEV2=${OBSLEV2_int}
    #export WRKD=${WRKDTOP}/${FCSTVAR}-${OBSVAR}-INTEGRAL
    #export DATA=$WRKD/tmp
    #export OUTPUTBASE=${WRKD}

    #cd $WRKD
    ##rm -rf $WRKD/*
    #/bin/sh $subcmd -a $proj_account -p $popts -j $METRUN-${MODELNAME}.${FCSTVAR}-${OBSNAME}.${OBSVAR} -o ${WRKD}/$METRUN-${MODELNAME}.${FCSTVAR}-${OBSNAME}.${OBSVAR}.out -q batch -t 00:59:00 -r /1 ${RUNSCRIPT}
    #sleep 2
done


exit

#export FCSTVAR=aod
#export FCSTINPUTTMP=${FCSTINPUTTMP_aods}
#export FCSTLEV=${FCSTLEV_aods}
#export FCSTLEV2=${FCSTLEV2_aods}
#export OBSVAR=AODANA
#export OBSINPUTTMP=${OBSINPUTTMP_aods}
#export OBSLEV=${OBSLEV_aods}
#export OBSLEV2=${OBSLEV2_aods}
#export WRKD=${WRKDTOP}/${FCSTVAR}-${OBSVAR}
#export DATA=$WRKD/tmp
#export OUTPUTBASE=${WRKD}
#
#cd $WRKD
##rm -rf $WRKD/*
#/bin/sh $subcmd -a $proj_account -p $popts -j $METRUN-${MODELNAME}.${FCSTVAR}-${OBSNAME}.${OBSVAR} -o ${WRKD}/$METRUN-${MODELNAME}.${FCSTVAR}-${OBSNAME}.${OBSVAR}.out -q batch -t 01:29:00 -r /1 ${RUNSCRIPT}
