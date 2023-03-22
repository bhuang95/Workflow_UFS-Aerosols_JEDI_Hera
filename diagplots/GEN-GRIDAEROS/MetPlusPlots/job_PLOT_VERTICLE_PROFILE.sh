#!/bin/bash --login
##!/bin/sh --login

#SBATCH --account=chem-var
#SBATCH --qos=urgent
##SBATCH --nodes=1 --ntasks-per-node=1 --cpus-per-task=1
#SBATCH -n 1
#SBATCH --time=07:59:00
#SBATCH --job-name=pythonJob
#SBATCH --output=pythonJob_dev.out

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

SDATE=2017101000
EDATE=2017101018
INC_H=6
DATATMP=${CURDIR}/data
PLOTDIR=${CURDIR}/PLOTS-${SDATE}-${EDATE}
TOPDATADIR=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/UfsData/LatLonGrid/metPlusStats-AEROS/
FREERUNEXP="FreeRun-1C192-0C192-201710"
AERODAEXP="AeroDA-1C192-20C192-201710"

NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

AERODACNTL=${TOPDATADIR}/${AERODAEXP}_cntlBkg-${AERODAEXP}_cntlAnl
AERODAENSM=${TOPDATADIR}/${AERODAEXP}_ensmBkg-${AERODAEXP}_ensmAnl
FREERUNCNTL=${TOPDATADIR}/${FREERUNEXP}_cntlBkg-${FREERUNEXP}_cntlBkg

#AERODACNTLFIELD
#AERODACNTLPRE

EXPDIR="/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/metPlusDiag/metPlusOutput"
MODELNAME="NRT-DA-cntlBckg"
MODELNAME1="NRT-DA-cntlAnal"
OBSNAME="ECana"
OBSNAME1="NASAana"

MASKS="FULL NNPAC TROP CONUS EASIA NAFRME RUSC2S SAFRTROP SOCEAN NATL SATL NPAC SPAC INDOCE"

NVARS=20
FCSTVARS=(aod SO4 DUSTTOTAL SEASTOTAL CTOTAL
	  NITRATE1 NITRATE2 NITRATE3
          DUSTFINE DUSTMEDIUM DUSTCOARSE
          SEASFINE SEASMEDIUM SEASCOARSE
	  OCPHOBIC OCPHILIC BCPHOBIC BCPHILIC CPHOBIC CPHILIC)

OBSVARS=(aod SO4 DUSTTOTAL SEASTOTAL CTOTAL
	  NITRATE1 NITRATE2 NITRATE3
          DUSTFINE DUSTMEDIUM DUSTCOARSE
          SEASFINE SEASMEDIUM SEASCOARSE
	  OCPHOBIC OCPHILIC BCPHOBIC BCPHILIC CPHOBIC CPHILIC)

[[ ! -d ${DATATMP} ]] && mkdir -p ${DATATMP}
[[ ! -d ${PLOTDIR} ]] && mkdir -p ${PLOTDIR}
cp ${CURDIR}/plt_grid_stat_anl_dev.py ${DATATMP}/plt_grid_stat_aod_dev.py
cp ${CURDIR}/plt_grid_stat_anl_aod_dev.py ${DATATMP}/plt_grid_stat_anl_aod_dev.py
for ((IVAR=0;IVAR<${NVARS};IVAR++)); do
    FCSTVAR=${FCSTVARS[ivar]}
    OBSVAR=${OBSVARS[ivar]}
    for MASK in ${MASKS}; do
        cd ${DATATMP}
	rm -rf *.stat

        CDATE=${SDATE}
        while [ ${CDATE} -le ${EDATE} ]; do
            DACNTLDATA_SRC=${AERODACNTL}/${FCSTVAR}-${OBSVAR}/met_tool_wrapper/stat_analysis/${CDATE}/${AERODACNTLFIELD}/${CDATE}/${MASK}_${OBSVAR}_SL1L2.stat
            DAENSMDATA_SRC=${AERODAENSM}/${FCSTVAR}-${OBSVAR}/met_tool_wrapper/stat_analysis/${CDATE}/${AERODAENSMFIELD}/${CDATE}/${MASK}_${OBSVAR}_SL1L2.stat
            FREERUNDATA_SRC=${FREERUNCNTL}/${FCSTVAR}-${OBSVAR}/met_tool_wrapper/stat_analysis/${CDATE}/${FREERUNCNTLFIELD}/${CDATE}/${MASK}_${OBSVAR}_SL1L2.stat

	    DACNTLDATA_DET=${AERODACNTLPRE}_${CDATE}.stat
	    DAENSMDATA_DET=${AERODAENSMPRE}_${CDATE}.stat
	    FREERUNDATA_DET=${FREERUNCNTLPRE}_${CDATE}.stat

	    [[ ! -f ${DACNTLDATA_SRC} ]] && exit 100
	    [[ ! -f ${DAENSMDATA_SRC} ]] && exit 100
	    [[ ! -f ${FREERUNDATA_SRC} ]] && exit 100

	    ln -sf ${DACNTLDATA_SRC} ./${DACNTLDATA_DET}
	    ln -sf ${DACENSMDATA_SRC} ./${DAENSMDATA_DET}
	    ln -sf ${FREERUNDATA_SRC} ./${FREERUNDATA_DET}
	    CDATE=$(${NDATE} ${INC_H} ${CDATE})
        done # CDATE


	if [ ${FCSTVAR} = 'aod' -o ${OBSVAR} = 'aod' ]; then
            PYEXE="plt_grid_stat_anl_aod_dev.py"
	else
            PYEXE="plt_grid_stat_anl_dev.py"
	fi

	python ${PYEXE} -i ${SDATE} -j ${EDATE} -p ${MASK} -v ${OBSVAR} -a ${AERODACNTLPRE} -b ${AERODAENSMPRE} -c ${FREERUNCNTLPRE}
	ERR=$?
	if [ ${ERR} -ne 0 ]; then
	    echo "Failed for ${FCSTVAR}-${OBSVAR}-${MASK}"
	else
	    VARDIR=${PLOTDIR}/${FCSTVAR}-${OBSVAR}
	    [[ ! -d ${VARDIR} ]] && mkdir ${VARDIR}
	    mv VerticalProfile.png ${VARDIR}/${FCSTVAR}-${OBSVAR}_${MASK}_VP.png
	fi
    done # MASK
done # IVAR

exit $?
