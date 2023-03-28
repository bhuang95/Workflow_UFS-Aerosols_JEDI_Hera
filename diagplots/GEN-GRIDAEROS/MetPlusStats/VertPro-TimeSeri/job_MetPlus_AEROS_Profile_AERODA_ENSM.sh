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
export FCSTFIELD="ensmBkg"
export MODELNAME="AeroDA-ensmBkg"
export OBSRUNNAME=${AERODAEXP}
export OBSFIELD="ensmAnl"
export OBSNAME="AeroDA-ensmAnl"
export BASE=/home/Bo.Huang/JEDI-2020/miscScripts-home/METPlus/METplus-AerosoDiag/METplus_pkg/
export INPUTBASE_AEROS=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/UfsData/LatLonGrid/FV3/AEROS/
export INPUTBASE_AOD=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/UfsData/LatLonGrid/FV3/AOD/
export RUNSCRIPT=/home/Bo.Huang/JEDI-2020/miscScripts-home/METPlus/runScripts/${METRUN}.sh

export SDATE=2017102400
export EDATE=2017102718
export INC_H=6
NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

#define model resolution for stat
export GRID_NAME="G003"
GRID_DEG="1.0deg"
#export GRID_NAME="G002"
#GRID_DEG="2.5deg"

WRKDTOP=${OUTDIR}/${FCSTRUNNAME}_${FCSTFIELD}-${OBSRUNNAME}_${OBSFIELD}-${GRID_DEG}

FCST_AEROS_SRC=${INPUTBASE_AEROS}/${FCSTRUNNAME}/${FCSTFIELD}/
FCST_AEROS_TMP=${WRKDTOP}/FCST_AEROS_DATA
FCST_AEROS_PRE=fv3_aeros_
FCST_AEROS_SUF=_pll.nc
OBS_AEROS_SRC=${INPUTBASE_AEROS}/${OBSRUNNAME}/${OBSFIELD}/
OBS_AEROS_TMP=${WRKDTOP}/OBS_AEROS_DATA
OBS_AEROS_PRE=fv3_aeros_
OBS_AEROS_SUF=_pll.nc

FCST_AOD_SRC=${INPUTBASE_AOD}/${FCSTRUNNAME}/${FCSTFIELD}/
FCST_AOD_TMP=${WRKDTOP}/FCST_AOD_DATA
FCST_AOD_PRE=fv3_aod_v.viirs-m_npp_
FCST_AOD_SUF=_ll.nc
OBS_AOD_SRC=${INPUTBASE_AOD}/${OBSRUNNAME}/${OBSFIELD}/
OBS_AOD_TMP=${WRKDTOP}/OBS_AOD_DATA
OBS_AOD_PRE=fv3_aod_v.viirs-m_npp_
OBS_AOD_SUF=_ll.nc

VARIABLES="AEROS AOD"

for VARIABLE in ${VARIABLES}; do 
    if [ ${VARIABLE} = "AEROS" ]; then
        FCST_SRC=${FCST_AEROS_SRC}
        FCST_TMP=${FCST_AEROS_TMP}
        FCST_PRE=${FCST_AEROS_PRE}
        FCST_SUF=${FCST_AEROS_SUF}
        OBS_SRC=${OBS_AEROS_SRC}
        OBS_TMP=${OBS_AEROS_TMP}
        OBS_PRE=${OBS_AEROS_PRE}
        OBS_SUF=${OBS_AEROS_SUF}
    elif [ ${VARIABLE} = "AOD" ]; then
        FCST_SRC=${FCST_AOD_SRC}
        FCST_TMP=${FCST_AOD_TMP}
        FCST_PRE=${FCST_AOD_PRE}
        FCST_SUF=${FCST_AOD_SUF}
        OBS_SRC=${OBS_AOD_SRC}
        OBS_TMP=${OBS_AOD_TMP}
        OBS_PRE=${OBS_AOD_PRE}
        OBS_SUF=${OBS_AOD_SUF}
    else
        echo "Please define FIELDS accordingly and exit now"
	exit 1
    fi
   

    [[ ! -d ${FCST_TMP} ]] && mkdir -p ${FCST_TMP}
    [[ ! -d ${OBS_TMP} ]] && mkdir -p ${OBS_TMP}

    rm -rf ${FCST_TMP}/fcst*.nc
    rm -rf ${OBS_TMP}/obs*.nc

    CDATE=${SDATE}
    while [ ${CDATE} -le ${EDATE} ]; do
        CY=${CDATE:0:4}
        CM=${CDATE:4:2}
        CD=${CDATE:6:2}
        CH=${CDATE:8:2}

        FCST_DATA=${FCST_SRC}/${CY}/${CY}${CM}/${CY}${CM}${CD}/${FCST_PRE}${CDATE}${FCST_SUF}
        OBS_DATA=${OBS_SRC}/${CY}/${CY}${CM}/${CY}${CM}${CD}/${OBS_PRE}${CDATE}${OBS_SUF}

        ln -sf ${FCST_DATA} ${FCST_TMP}/fcst_${CDATE}.nc
        ln -sf ${OBS_DATA} ${OBS_TMP}/obs_${CDATE}.nc
        CDATE=$(${NDATE} ${INC_H} ${CDATE})
    done
done

# set fcst and obs varibales
export INPUTBASE=${INPUTBASE_AEROS}
export FCSTDIR="${FCST_AEROS_TMP}"
export FCSTINPUTTMP_aeros="fcst_{init?fmt=%Y%m%d%H}.nc"
export FCSTLEV_aeros='"(0,0,*,*)","(0,1,*,*)","(0,2,*,*)","(0,3,*,*)","(0,4,*,*)","(0,5,*,*)","(0,6,*,*)","(0,7,*,*)","(0,8,*,*)"'
export FCSTLEV2_aeros='"0,0,*,*","0,1,*,*","0,2,*,*","0,3,*,*","0,4,*,*","0,5,*,*","0,6,*,*","0,7,*,*","0,8,*,*"'

export OBSDIR="${OBS_AEROS_TMP}"
export OBSINPUTTMP_aeros="obs_{init?fmt=%Y%m%d%H}.nc"
export OBSLEV_aeros='"(0,0,*,*)","(0,1,*,*)","(0,2,*,*)","(0,3,*,*)","(0,4,*,*)","(0,5,*,*)","(0,6,*,*)","(0,7,*,*)","(0,8,*,*)"'
export OBSLEV2_aeros='"0,0,*,*","0,1,*,*","0,2,*,*","0,3,*,*","0,4,*,*","0,5,*,*","0,6,*,*","0,7,*,*","0,8,*,*"'


#export FCSTINPUTTMP_int="fv3_aeros_int_{init?fmt=%Y%m%d%H}_pll.nc"
#export FCSTLEV_int='"(0,0,*,*)"'
#export FCSTLEV2_int='"0,0,*,*"'


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

nvars=19
FCSTVARS=(SO4 DUSTFINE DUSTMEDIUM DUSTCOARSE DUSTTOTAL
          SEASFINE SEASMEDIUM SEASCOARSE SEASTOTAL
	  OCPHOBIC OCPHILIC BCPHOBIC BCPHILIC CPHOBIC CPHILIC CTOTAL 
	  NITRATE1 NITRATE2 NITRATE3)
OBSVARS=(SO4 DUSTFINE DUSTMEDIUM DUSTCOARSE DUSTTOTAL
         SEASFINE SEASMEDIUM SEASCOARSE SEASTOTAL
	 OCPHOBIC OCPHILIC BCPHOBIC BCPHILIC CPHOBIC CPHILIC CTOTAL 
	 NITRATE1 NITRATE2 NITRATE3)

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
nvars=-1
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
    /bin/sh $subcmd -a $PROJ_ACCOUNT -p $POPOTS -j $METRUN-${FCSTVAR}_${OBSVAR} -o ${WRKD}/$METRUN-${FCSTVAR}-${OBSVAR}.out -q batch -t 02:29:00 -r /1 ${RUNSCRIPT}
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

export INPUTBASE=${INPUTBASE_AOD}
export MSKLIST="FULL NNPAC TROP CONUS EASIA NAFRME RUSC2S SAFRTROP SOCEAN NATL SATL NPAC SPAC INDOCE"
export FCSTDIR="${FCST_AOD_TMP}"
export FCSTVAR=aod
export FCSTINPUTTMP="fcst_{init?fmt=%Y%m%d%H}.nc"
export FCSTLEV='"(0,2,*,*)"'
export FCSTLEV2='"0,2,*,*"'
#export FCSTINPUTTMP=${FCSTINPUTTMP_aods}
#export FCSTLEV=${FCSTLEV_aods}
#export FCSTLEV2=${FCSTLEV2_aods}
export OBSDIR="${OBS_AOD_TMP}"
export OBSVAR=aod
export OBSINPUTTMP="obs_{init?fmt=%Y%m%d%H}.nc"
export OBSLEV='"(0,2,*,*)"'
export OBSLEV2='"0,2,*,*"'
export WRKD=${WRKDTOP}/${FCSTVAR}-${OBSVAR}
export DATA=$WRKD/tmp
export OUTPUTBASE=${WRKD}

cd $WRKD
##rm -rf $WRKD/*
/bin/sh $subcmd -a $PROJ_ACCOUNT -p $POPOTS -j $METRUN-${FCSTVAR}-${OBSVAR} -o ${WRKD}/$METRUN-${FCSTVAR}-${OBSVAR}.out -q debug -t 00:29:00 -r /1 ${RUNSCRIPT}
exit 0
