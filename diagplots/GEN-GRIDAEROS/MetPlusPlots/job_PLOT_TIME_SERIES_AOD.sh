#!/bin/bash --login
##!/bin/sh --login

#SBATCH --account=wrf-chem
#SBATCH --qos=batch
#SBATCH --partition=service
##SBATCH --nodes=1 --ntasks-per-node=1 --cpus-per-task=1
#SBATCH -n 1
#SBATCH --time=02:29:00
#SBATCH --job-name=pythonJob
#SBATCH --output=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/pythonJob_dev.out

### This scripts plots the vertical profiles and time-series of aerosol mixing ratio vertical profiles 
###      (plt_grid_stat_anl.py) and aerosol column intergral time-series (plt_grid_stat_anl_int.py).
###     Its input include stat files from two METplus met_grid_stat_anl runs (e.g., MODELNAME-OBSNAME 
###     and MODELNAME1-OBSNAME1). If the comparison involves the stat files from only a single or 
###     over multiple METplus runs, please add/remove corresponding MODELNAME-OBSNAME and related 
###     variables in this script and the above two python scripts. Please modify the legend variabels 
###     in the python scripts based on the plots. 
###   
### Please contact Bo.Huang at bo.huang@noaa.gov, if further clarification is needed.

export OMP_NUM_THREADS=1

set -x 

module use -a /contrib/anaconda/modulefiles
module load anaconda/latest

### Define the stat directories/files from the METplus met_grid_stat_anl run
CURDIR=`pwd`
TOPPLOTDIR=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/AeroDA-1C192-20C192-201710/diagplots/METPLUS/VertProf-TimeSeri/

SDATE=2017100600
EDATE=2017102318
INC_H=6
PLOTDIR=${TOPPLOTDIR}/PLOTS-${SDATE}-${EDATE}
DATATMP=${PLOTDIR}/data-AOD
TOPDATADIR=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/UfsData/LatLonGrid/metPlusStats-AEROS/
FREERUNEXP="FreeRun-1C192-0C192-201710"
AERODAEXP="AeroDA-1C192-20C192-201710"
MERRA2ANL="MERRA2"
CAMSANL="CAMSIRA"

NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

AERODACNTL=${TOPDATADIR}/${AERODAEXP}_cntlBkg-${AERODAEXP}_cntlAnl-1.0deg
AERODAENSM=${TOPDATADIR}/${AERODAEXP}_ensmBkg-${AERODAEXP}_ensmAnl-1.0deg
FREERUNCNTL=${TOPDATADIR}/${FREERUNEXP}_cntlBkg-${FREERUNEXP}_cntlBkg-1.0deg
MERRA2CAMS=${TOPDATADIR}/${MERRA2ANL}_AOD-${CAMSANL}_AOD-1.0deg

AERODACNTLFIELD=AeroDA-cntlBkg
AERODAENSMFIELD=AeroDA-ensmBkg
FREERUNCNTLFIELD=FreeRun-cntlBkg
MERRA2CAMSFIELD=MERRA2

AERODACNTLPRE=AeroDACntl
AERODAENSMPRE=AeroDAEnsm
FREERUNCNTLPRE=FreeRunCntl
MERRA2CAMSPRE=MERRA2-CAMSiRA

MASKS="FULL NNPAC TROP CONUS EASIA NAFRME RUSC2S SAFRTROP SOCEAN NATL SATL NPAC SPAC INDOCE"

NVARS=1
FCSTVARS=(AODANA)
OBSVARS=(aod550)

[[ ! -d ${DATATMP} ]] && mkdir -p ${DATATMP}
[[ ! -d ${PLOTDIR} ]] && mkdir -p ${PLOTDIR}

cp ${CURDIR}/plt_grid_stat_anl_aod_dev.py ${DATATMP}/plt_grid_stat_anl_aod_dev.py

FCSTVAR_FV=aod
OBSVAR_FV=aod
FCSTVAR_MERRA2=AODANA
OBSVAR_CAMS=aod550
FCSTVAR=${FCSTVAR_FV}
OBSVAR=${OBSVAR_FV}
for MASK in ${MASKS}; do
    cd ${DATATMP}
    rm -rf *.stat

    CDATE=${SDATE}
    while [ ${CDATE} -le ${EDATE} ]; do
        DACNTLDATA_SRC=${AERODACNTL}/${FCSTVAR_FV}-${OBSVAR_FV}/met_tool_wrapper/stat_analysis/${AERODACNTLFIELD}/${CDATE}/${MASK}_${OBSVAR_FV}_SL1L2.stat
        DAENSMDATA_SRC=${AERODAENSM}/${FCSTVAR_FV}-${OBSVAR_FV}/met_tool_wrapper/stat_analysis/${AERODAENSMFIELD}/${CDATE}/${MASK}_${OBSVAR_FV}_SL1L2.stat
        FREERUNDATA_SRC=${FREERUNCNTL}/${FCSTVAR_FV}-${OBSVAR_FV}/met_tool_wrapper/stat_analysis/${FREERUNCNTLFIELD}/${CDATE}/${MASK}_${OBSVAR_FV}_SL1L2.stat
        MERRA2CAMSDATA_SRC=${MERRA2CAMS}/${FCSTVAR_MERRA2}-${OBSVAR_CAMS}/met_tool_wrapper/stat_analysis/${MERRA2CAMSFIELD}/${CDATE}/${MASK}_${OBSVAR_CAMS}_SL1L2.stat

        DACNTLDATA_DET=${AERODACNTLPRE}_${MASK}_${CDATE}.stat
        DAENSMDATA_DET=${AERODAENSMPRE}_${MASK}_${CDATE}.stat
        FREERUNDATA_DET=${FREERUNCNTLPRE}_${MASK}_${CDATE}.stat
        MERRA2CAMSDATA_DET=${MERRA2CAMSPRE}_${MASK}_${CDATE}.stat

        [[ ! -f ${DACNTLDATA_SRC} ]] && exit 100
        [[ ! -f ${DAENSMDATA_SRC} ]] && exit 100
        [[ ! -f ${FREERUNDATA_SRC} ]] && exit 100
        [[ ! -f ${MERRA2CAMSDATA_SRC} ]] && exit 100

        ln -sf ${DACNTLDATA_SRC} ./${DACNTLDATA_DET}
        ln -sf ${DAENSMDATA_SRC} ./${DAENSMDATA_DET}
        ln -sf ${FREERUNDATA_SRC} ./${FREERUNDATA_DET}
        ln -sf ${MERRA2CAMSDATA_SRC} ./${MERRA2CAMSDATA_DET}
        CDATE=$(${NDATE} ${INC_H} ${CDATE})
    done # CDATE


    python plt_grid_stat_anl_aod_dev.py -i ${SDATE} -j ${EDATE} -p ${MASK} -v ${OBSVAR} -a ${AERODACNTLPRE} -b ${AERODAENSMPRE} -c ${FREERUNCNTLPRE} -d ${MERRA2CAMSPRE}
    ERR=$?
    if [ ${ERR} -ne 0 ]; then
        echo "Failed for ${FCSTVAR}-${OBSVAR}-${MASK}"
        exit ${ERR}
    else
        VARDIR=${PLOTDIR}/${FCSTVAR}-${OBSVAR}
        [[ ! -d ${VARDIR} ]] && mkdir ${VARDIR}
        mv TimeSeries.png ${VARDIR}/${FCSTVAR}-${OBSVAR}_${MASK}_TS.png
    fi
done # MASK
