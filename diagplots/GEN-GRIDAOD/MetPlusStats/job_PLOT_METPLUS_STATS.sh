#!/bin/bash
#SBATCH -n 1
#SBATCH -t 00:30:00
#SBATCH -p service
#SBATCH -A chem-var
#SBATCH -J metplus_plot
#SBATCH -D ./
#SBATCH -o /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/metplus_plot.log
#SBATCH -e /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/metplus_plot.log


export OMP_NUM_THREADS=1
set -x 

NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

module purge
module load intel/2022.1.2
module use -a /contrib/anaconda/modulefiles
module load anaconda/latest

CURDIR=$(pwd)

FREERUNEXP="FreeRun-1C192-0C192-201710"
AERODAEXP="AeroDA-1C192-20C192-201710"

MERRA2ANL="MERRA2"
CAMSIRAANL="CAMSIRA"

SDATE=${SDATE:-"2017101000"}
EDATE=${EDATE:-"2017102718"}

PLOTDIR=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/AeroDA-1C192-20C192-201710/diagplots/METPLUS/2DMAP/PLOTS-${SDATE}-${EDATE}
PYCODE=${CURDIR}/plt_MERRA2_CAMSIRA_AOD550_2DMAP.py 

[[ ! -d ${PLOTDIR} ]] && mkdir -p ${PLOTDIR}

DATADIR="/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/UfsData/LatLonGrid/metPlusStats-AOD"
MISSNASAAOD_RECORD=${MISSNASAAOD_RECORD:-"./record.missingNASAAOD"}
MISSECAOD_RECORD=${MISSECAOD_RECORD:-"./record.missingECAOD"}
NASAMISSING="NO"
ECMISSING="NO"

NLN="ln -sf"


if ( grep ${SDATE} ${MISSNASAAOD_RECORD} );then
    NASAMISSING="YES"
fi

if ( grep ${SDATE} ${MISSECAOD_RECORD} );then
    ECMISSING="YES"
fi

if [[ ${NASAMISSING} == "YES" && ${NASAMISSING} == "YES" ]]; then
    echo "Missing both NASA and ECMWF AOD and exit"
    exit 0
fi

#FIELDS="CNTL EMEAN"
FIELDS="CNTL"

for FIELD in ${FIELDS}; do
    cd ${PLOTDIR}
    rm -rf *.nc
    AODFILE=aod_sigLevhPa.nc

    if [ ${FIELD} = "CNTL" ]; then
        EMEAN="False"
	FIELDPRE='cntl'
    elif [ ${FIELD} = "EMEAN" ]; then
        EMEAN="True"
	FIELDPRE='ensm'
    else
	echo "Please define FIELD accordingly and exit now"
        exit 1
    fi
   
    echo "HBO1-${EMEAN}-${FIELDPRE}"

    FREERUN_BKG_MERRA2=${DATADIR}/${FREERUNEXP}-cntlBkg_${MERRA2ANL}/${SDATE}-${EDATE}/${AODFILE}
    AERODA_BKG_MERRA2=${DATADIR}/${AERODAEXP}-${FIELDPRE}Bkg_${MERRA2ANL}/${SDATE}-${EDATE}/${AODFILE}
    AERODA_ANL_MERRA2=${DATADIR}/${AERODAEXP}-${FIELDPRE}Anl_${MERRA2ANL}/${SDATE}-${EDATE}/${AODFILE}

    FREERUN_BKG_CAMSIRA=${DATADIR}/${FREERUNEXP}-cntlBkg_${CAMSIRAANL}/${SDATE}-${EDATE}/${AODFILE}
    AERODA_BKG_CAMSIRA=${DATADIR}/${AERODAEXP}-${FIELDPRE}Bkg_${CAMSIRAANL}/${SDATE}-${EDATE}/${AODFILE}
    AERODA_ANL_CAMSIRA=${DATADIR}/${AERODAEXP}-${FIELDPRE}Anl_${CAMSIRAANL}/${SDATE}-${EDATE}/${AODFILE}

    ${NLN} ${FREERUN_BKG_MERRA2} ${PLOTDIR}/freebkg_m2.nc
    ${NLN} ${AERODA_BKG_MERRA2} ${PLOTDIR}/aerodabkg_m2.nc
    ${NLN} ${AERODA_ANL_MERRA2} ${PLOTDIR}/aerodaanl_m2.nc

    ${NLN} ${FREERUN_BKG_CAMSIRA} ${PLOTDIR}/freebkg_cams.nc
    ${NLN} ${AERODA_BKG_CAMSIRA} ${PLOTDIR}/aerodabkg_cams.nc
    ${NLN} ${AERODA_ANL_CAMSIRA} ${PLOTDIR}/aerodaanl_cams.nc

    cp ${PYCODE} ${PLOTDIR}/plt_MERRA2_CAMSIRA_AOD550_2DMAP.py 
    python plt_MERRA2_CAMSIRA_AOD550_2DMAP.py -e ${EMEAN} -p ${SDATE}-${EDATE} -m ${NASAMISSING} -n ${ECMISSING} -a freebkg_m2.nc -b aerodabkg_m2.nc -c aerodaanl_m2.nc -x freebkg_cams.nc -y aerodabkg_cams.nc -z aerodaanl_cams.nc

    ERR=$?

    if [ ${ERR} -ne 0 ]; then
       echo "Python plot failed and exit"
       exit ${ERR}
    fi
done
exit ${ERR}
